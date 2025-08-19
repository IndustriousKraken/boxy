/// Layout Manager for positioning multiple boxes
///
/// This module provides functionality to position and combine multiple
/// BoxyBox instances into complex layouts. It enables side-by-side placement,
/// overlapping, and provides the foundation for interactive UIs.

const std = @import("std");
const box_mod = @import("box.zig");
const utils = @import("utils.zig");

/// Information about a placed box
pub const PlacedBox = struct {
    box: *box_mod.BoxyBox,
    row: usize,
    col: usize,
    z_index: i32,  // Higher values render on top
    
    /// Get the bounds of this placed box
    pub fn getBounds(self: PlacedBox) BoxBounds {
        const rendered = self.box.render() catch return BoxBounds{ .row = self.row, .col = self.col, .width = 0, .height = 0 };
        
        // Count lines and find max display width
        var lines = std.mem.splitScalar(u8, rendered, '\n');
        var height: usize = 0;
        var width: usize = 0;
        
        while (lines.next()) |line| {
            height += 1;
            // Use display width instead of byte length
            const display_w = utils.displayWidth(line);
            width = @max(width, display_w);
        }
        
        return BoxBounds{
            .row = self.row,
            .col = self.col,
            .width = width,
            .height = height,
        };
    }
};

/// Bounding box for a placed box
pub const BoxBounds = struct {
    row: usize,
    col: usize,
    width: usize,
    height: usize,
    
    /// Check if a point is within these bounds
    pub fn contains(self: BoxBounds, row: usize, col: usize) bool {
        return row >= self.row and row < self.row + self.height and
               col >= self.col and col < self.col + self.width;
    }
};

/// Character cell in the layout buffer
const Cell = struct {
    bytes: [4]u8 = [_]u8{0} ** 4,  // UTF-8 character (max 4 bytes)
    len: u8 = 0,  // Actual byte length
    width: u8 = 1,  // Display width (1 or 2 columns)
};

/// Layout manager for positioning multiple boxes
pub const LayoutManager = struct {
    allocator: std.mem.Allocator,
    width: usize,  // Width in display columns
    height: usize,  // Height in rows
    cells: [][]Cell,  // 2D grid of cells
    boxes: std.ArrayList(PlacedBox),
    background_char: u8,
    
    /// Initialize a new layout manager with specified dimensions
    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !LayoutManager {
        var cells = try allocator.alloc([]Cell, height);
        errdefer allocator.free(cells);
        
        for (cells, 0..) |*row, i| {
            row.* = try allocator.alloc(Cell, width);
            errdefer {
                for (cells[0..i]) |r| allocator.free(r);
            }
            // Initialize with spaces
            for (row.*) |*cell| {
                cell.* = Cell{
                    .bytes = [_]u8{' ', 0, 0, 0},
                    .len = 1,
                    .width = 1,
                };
            }
        }
        
        return LayoutManager{
            .allocator = allocator,
            .width = width,
            .height = height,
            .cells = cells,
            .boxes = std.ArrayList(PlacedBox).init(allocator),
            .background_char = ' ',
        };
    }
    
    /// Clean up allocated memory
    pub fn deinit(self: *LayoutManager) void {
        for (self.cells) |row| {
            self.allocator.free(row);
        }
        self.allocator.free(self.cells);
        self.boxes.deinit();
    }
    
    /// Set the background character (default is space)
    pub fn setBackground(self: *LayoutManager, char: u8) void {
        self.background_char = char;
        self.clear();
    }
    
    /// Clear the layout buffer
    pub fn clear(self: *LayoutManager) void {
        for (self.cells) |row| {
            for (row) |*cell| {
                cell.* = Cell{
                    .bytes = [_]u8{self.background_char, 0, 0, 0},
                    .len = 1,
                    .width = 1,
                };
            }
        }
    }
    
    /// Place a box at the specified position
    pub fn place(self: *LayoutManager, placed_box: *box_mod.BoxyBox, row: usize, col: usize) !void {
        try self.placeAt(placed_box, row, col, 0);
    }
    
    /// Place a box at the specified position with z-index
    pub fn placeAt(self: *LayoutManager, placed_box: *box_mod.BoxyBox, row: usize, col: usize, z_index: i32) !void {
        try self.boxes.append(PlacedBox{
            .box = placed_box,
            .row = row,
            .col = col,
            .z_index = z_index,
        });
        
        // Sort by z-index for proper layering
        std.mem.sort(PlacedBox, self.boxes.items, {}, struct {
            fn lessThan(_: void, a: PlacedBox, b: PlacedBox) bool {
                return a.z_index < b.z_index;
            }
        }.lessThan);
    }
    
    /// Remove a box from the layout
    pub fn remove(self: *LayoutManager, target_box: *box_mod.BoxyBox) void {
        var i: usize = 0;
        while (i < self.boxes.items.len) {
            if (self.boxes.items[i].box == target_box) {
                _ = self.boxes.swapRemove(i);
            } else {
                i += 1;
            }
        }
    }
    
    /// Write a UTF-8 character at the specified cell position
    fn writeCell(self: *LayoutManager, row: usize, col: usize, bytes: []const u8) void {
        if (row >= self.height or col >= self.width or bytes.len == 0) return;
        
        const cell = &self.cells[row][col];
        const byte_len = @min(bytes.len, 4);
        
        // Copy the character bytes
        @memcpy(cell.bytes[0..byte_len], bytes[0..byte_len]);
        cell.len = @intCast(byte_len);
        
        // Calculate display width
        cell.width = if (byte_len == 4) 2 else 1;  // Simplified: 4-byte chars are usually emojis (2 columns)
    }
    
    /// Blit a rendered box string to the buffer with display width awareness
    fn blitString(self: *LayoutManager, start_row: usize, start_col: usize, text: []const u8) void {
        var lines = std.mem.splitScalar(u8, text, '\n');
        var row_offset: usize = 0;
        
        while (lines.next()) |line| {
            const target_row = start_row + row_offset;
            if (target_row >= self.height) break;
            
            // Process line character by character
            var byte_idx: usize = 0;
            var col_offset: usize = 0;
            
            while (byte_idx < line.len) {
                const target_col = start_col + col_offset;
                if (target_col >= self.width) break;
                
                // Get the next UTF-8 character
                const byte_count = utils.utf8ByteSequenceLength(line[byte_idx]);
                const end_idx = @min(byte_idx + byte_count, line.len);
                const char_bytes = line[byte_idx..end_idx];
                
                // Calculate display width
                const char_width = utils.displayWidth(char_bytes);
                
                // Check if character fits
                if (target_col + char_width <= self.width) {
                    // Write the character
                    self.writeCell(target_row, target_col, char_bytes);
                    
                    // For wide characters, fill the next cell with a placeholder
                    if (char_width == 2 and target_col + 1 < self.width) {
                        // Mark the next cell as continuation of wide char
                        self.cells[target_row][target_col + 1] = Cell{
                            .bytes = [_]u8{0} ** 4,
                            .len = 0,
                            .width = 0,  // Continuation cell
                        };
                    }
                    
                    col_offset += char_width;
                } else {
                    // Character doesn't fit, skip to next line
                    break;
                }
                
                byte_idx = end_idx;
            }
            
            row_offset += 1;
        }
    }
    
    /// Render all placed boxes to the buffer and return as string
    pub fn render(self: *LayoutManager) ![]const u8 {
        // Clear buffer first
        self.clear();
        
        // Render each box in z-order
        for (self.boxes.items) |placed| {
            const rendered = try placed.box.render();
            self.blitString(placed.row, placed.col, rendered);
        }
        
        // Convert cells to string
        var result = std.ArrayList(u8).init(self.allocator);
        defer result.deinit();
        
        for (self.cells, 0..) |row, row_idx| {
            var col_idx: usize = 0;
            while (col_idx < self.width) {
                const cell = row[col_idx];
                
                if (cell.len > 0) {
                    // Write the character bytes
                    try result.appendSlice(cell.bytes[0..cell.len]);
                    
                    // Skip continuation cells for wide characters
                    if (cell.width == 2) {
                        col_idx += 2;
                    } else {
                        col_idx += 1;
                    }
                } else if (cell.width == 0) {
                    // Continuation cell, skip it (already handled by wide char)
                    col_idx += 1;
                } else {
                    // Empty cell, write space
                    try result.append(' ');
                    col_idx += 1;
                }
            }
            
            // Add newline except for last row
            if (row_idx < self.cells.len - 1) {
                try result.append('\n');
            }
        }
        
        return try result.toOwnedSlice();
    }
    
    /// Get the box at the specified position (for hit testing)
    pub fn getBoxAt(self: *LayoutManager, row: usize, col: usize) ?*box_mod.BoxyBox {
        // Check in reverse order (highest z-index first)
        var i = self.boxes.items.len;
        while (i > 0) {
            i -= 1;
            const placed = self.boxes.items[i];
            const bounds = placed.getBounds();
            if (bounds.contains(row, col)) {
                return placed.box;
            }
        }
        return null;
    }
    
    /// Get the bounds of a placed box
    pub fn getBoxBounds(self: *LayoutManager, target_box: *box_mod.BoxyBox) ?BoxBounds {
        for (self.boxes.items) |placed| {
            if (placed.box == target_box) {
                return placed.getBounds();
            }
        }
        return null;
    }
    
    /// Get all boxes that overlap with the given bounds
    pub fn getBoxesInRegion(self: *LayoutManager, region: BoxBounds) !std.ArrayList(*box_mod.BoxyBox) {
        var result = std.ArrayList(*box_mod.BoxyBox).init(self.allocator);
        
        for (self.boxes.items) |placed| {
            const bounds = placed.getBounds();
            
            // Check for overlap
            const overlap = !(region.col + region.width <= bounds.col or
                            bounds.col + bounds.width <= region.col or
                            region.row + region.height <= bounds.row or
                            bounds.row + bounds.height <= region.row);
            
            if (overlap) {
                try result.append(placed.box);
            }
        }
        
        return result;
    }
};