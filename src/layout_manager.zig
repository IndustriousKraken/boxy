/// Layout Manager for positioning multiple boxes
///
/// This module provides functionality to position and combine multiple
/// BoxyBox instances into complex layouts. It enables side-by-side placement,
/// overlapping, and provides the foundation for interactive UIs.

const std = @import("std");
const box_mod = @import("box.zig");

/// Information about a placed box
pub const PlacedBox = struct {
    box: *box_mod.BoxyBox,
    row: usize,
    col: usize,
    z_index: i32,  // Higher values render on top
    
    /// Get the bounds of this placed box
    pub fn getBounds(self: PlacedBox) BoxBounds {
        const rendered = self.box.render() catch return BoxBounds{ .row = self.row, .col = self.col, .width = 0, .height = 0 };
        
        // Count lines and find max width
        var lines = std.mem.splitScalar(u8, rendered, '\n');
        var height: usize = 0;
        var width: usize = 0;
        
        while (lines.next()) |line| {
            if (line.len > 0) {
                height += 1;
                width = @max(width, line.len);
            }
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

/// Layout manager for positioning multiple boxes
pub const LayoutManager = struct {
    allocator: std.mem.Allocator,
    width: usize,
    height: usize,
    buffer: [][]u8,
    boxes: std.ArrayList(PlacedBox),
    background_char: u8,
    
    /// Initialize a new layout manager with specified dimensions
    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !LayoutManager {
        var buffer = try allocator.alloc([]u8, height);
        errdefer allocator.free(buffer);
        
        for (buffer, 0..) |*row, i| {
            row.* = try allocator.alloc(u8, width);
            errdefer {
                for (buffer[0..i]) |r| allocator.free(r);
            }
            @memset(row.*, ' ');
        }
        
        return LayoutManager{
            .allocator = allocator,
            .width = width,
            .height = height,
            .buffer = buffer,
            .boxes = std.ArrayList(PlacedBox).init(allocator),
            .background_char = ' ',
        };
    }
    
    /// Clean up allocated memory
    pub fn deinit(self: *LayoutManager) void {
        for (self.buffer) |row| {
            self.allocator.free(row);
        }
        self.allocator.free(self.buffer);
        self.boxes.deinit();
    }
    
    /// Set the background character (default is space)
    pub fn setBackground(self: *LayoutManager, char: u8) void {
        self.background_char = char;
        self.clear();
    }
    
    /// Clear the layout buffer
    pub fn clear(self: *LayoutManager) void {
        for (self.buffer) |row| {
            @memset(row, self.background_char);
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
    
    /// Render all placed boxes to the buffer and return as string
    pub fn render(self: *LayoutManager) ![]const u8 {
        // Clear buffer first
        self.clear();
        
        // Render each box in z-order
        for (self.boxes.items) |placed| {
            const rendered = try placed.box.render();
            self.blitString(placed.row, placed.col, rendered);
        }
        
        // Convert buffer to string
        var result = std.ArrayList(u8).init(self.allocator);
        defer result.deinit();
        
        for (self.buffer, 0..) |row, i| {
            try result.appendSlice(row);
            if (i < self.buffer.len - 1) {
                try result.append('\n');
            }
        }
        
        return try result.toOwnedSlice();
    }
    
    /// Blit a rendered box string to the buffer
    fn blitString(self: *LayoutManager, start_row: usize, start_col: usize, text: []const u8) void {
        var lines = std.mem.splitScalar(u8, text, '\n');
        var row_offset: usize = 0;
        
        while (lines.next()) |line| {
            const target_row = start_row + row_offset;
            if (target_row >= self.height) break;
            
            // Simply copy bytes directly - the buffer will hold UTF-8 as-is
            const start = start_col;
            const end = @min(start_col + line.len, self.width);
            if (start < end) {
                const copy_len = end - start;
                const source_slice = line[0..@min(copy_len, line.len)];
                @memcpy(self.buffer[target_row][start..end], source_slice);
            }
            
            row_offset += 1;
        }
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