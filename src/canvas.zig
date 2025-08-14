/// Canvas functionality for dynamic content within boxes
///
/// This module provides the BoxyCanvas structure that allows direct manipulation
/// of content within a box. Perfect for games, animations, and dynamic displays.
/// The canvas provides a 2D array of characters that can be modified directly
/// or through blit operations.

const std = @import("std");

/// A drawable canvas area within a box
pub const BoxyCanvas = struct {
    allocator: std.mem.Allocator,
    width: usize,
    height: usize,
    buffer: [][]u8,
    dirty: bool,
    
    /// Create a new canvas with the specified dimensions
    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !BoxyCanvas {
        var buffer = try allocator.alloc([]u8, height);
        errdefer allocator.free(buffer);
        
        for (buffer, 0..) |*row, i| {
            row.* = try allocator.alloc(u8, width);
            errdefer {
                for (buffer[0..i]) |r| allocator.free(r);
            }
            // Initialize with spaces
            @memset(row.*, ' ');
        }
        
        return .{
            .allocator = allocator,
            .width = width,
            .height = height,
            .buffer = buffer,
            .dirty = false,
        };
    }
    
    /// Clean up allocated memory
    pub fn deinit(self: *BoxyCanvas) void {
        for (self.buffer) |row| {
            self.allocator.free(row);
        }
        self.allocator.free(self.buffer);
    }
    
    /// Clear the canvas (fill with spaces)
    pub fn clear(self: *BoxyCanvas) void {
        for (self.buffer) |row| {
            @memset(row, ' ');
        }
        self.dirty = true;
    }
    
    /// Set a single character at the specified position
    pub fn setChar(self: *BoxyCanvas, x: usize, y: usize, char: u8) void {
        if (x < self.width and y < self.height) {
            self.buffer[y][x] = char;
            self.dirty = true;
        }
    }
    
    /// Get a single character at the specified position
    pub fn getChar(self: *const BoxyCanvas, x: usize, y: usize) ?u8 {
        if (x < self.width and y < self.height) {
            return self.buffer[y][x];
        }
        return null;
    }
    
    /// Blit a text string at the specified position
    /// Text that extends beyond the canvas bounds is clipped
    pub fn blitText(self: *BoxyCanvas, x: usize, y: usize, text: []const u8) !void {
        if (y >= self.height) return;
        
        const start_x = x;
        const end_x = @min(x + text.len, self.width);
        const copy_len = end_x - start_x;
        
        if (copy_len > 0) {
            @memcpy(self.buffer[y][start_x..end_x], text[0..copy_len]);
            self.dirty = true;
        }
    }
    
    /// Blit a multi-line block of text at the specified position
    /// Each line is separated by \n in the input
    pub fn blitBlock(self: *BoxyCanvas, x: usize, y: usize, block: []const u8) !void {
        var lines = std.mem.tokenizeScalar(u8, block, '\n');
        var current_y = y;
        
        while (lines.next()) |line| {
            if (current_y >= self.height) break;
            try self.blitText(x, current_y, line);
            current_y += 1;
        }
    }
    
    /// Blit another canvas onto this one at the specified position
    pub fn blitCanvas(self: *BoxyCanvas, x: usize, y: usize, other: *const BoxyCanvas) void {
        const start_y = y;
        const end_y = @min(y + other.height, self.height);
        
        for (start_y..end_y, 0..) |dst_y, src_y| {
            const start_x = x;
            const end_x = @min(x + other.width, self.width);
            const copy_len = end_x - start_x;
            
            if (copy_len > 0) {
                @memcpy(
                    self.buffer[dst_y][start_x..end_x],
                    other.buffer[src_y][0..copy_len]
                );
            }
        }
        self.dirty = true;
    }
    
    /// Draw a horizontal line using the specified character
    pub fn drawHLine(self: *BoxyCanvas, x: usize, y: usize, length: usize, char: u8) void {
        if (y >= self.height) return;
        
        const start = x;
        const end = @min(x + length, self.width);
        
        for (start..end) |i| {
            self.buffer[y][i] = char;
        }
        self.dirty = true;
    }
    
    /// Draw a vertical line using the specified character
    pub fn drawVLine(self: *BoxyCanvas, x: usize, y: usize, length: usize, char: u8) void {
        if (x >= self.width) return;
        
        const start = y;
        const end = @min(y + length, self.height);
        
        for (start..end) |i| {
            self.buffer[i][x] = char;
        }
        self.dirty = true;
    }
    
    /// Draw a rectangle outline
    pub fn drawRect(self: *BoxyCanvas, x: usize, y: usize, width: usize, height: usize, char: u8) void {
        // Top and bottom
        self.drawHLine(x, y, width, char);
        if (height > 1) {
            self.drawHLine(x, y + height - 1, width, char);
        }
        
        // Left and right
        if (height > 2) {
            self.drawVLine(x, y + 1, height - 2, char);
            if (width > 1) {
                self.drawVLine(x + width - 1, y + 1, height - 2, char);
            }
        }
    }
    
    /// Fill a rectangle with the specified character
    pub fn fillRect(self: *BoxyCanvas, x: usize, y: usize, width: usize, height: usize, char: u8) void {
        const end_y = @min(y + height, self.height);
        const end_x = @min(x + width, self.width);
        
        for (y..end_y) |row_y| {
            for (x..end_x) |col_x| {
                self.buffer[row_y][col_x] = char;
            }
        }
        self.dirty = true;
    }
    
    /// Get a reference to a specific row (for direct manipulation)
    pub fn getRow(self: *BoxyCanvas, y: usize) ?[]u8 {
        if (y < self.height) {
            self.dirty = true;
            return self.buffer[y];
        }
        return null;
    }
    
    /// Get the entire buffer for direct manipulation (advanced users)
    pub fn getRawBuffer(self: *BoxyCanvas) [][]u8 {
        self.dirty = true;
        return self.buffer;
    }
    
    /// Check if the canvas has been modified since last render
    pub fn isDirty(self: *const BoxyCanvas) bool {
        return self.dirty;
    }
    
    /// Mark the canvas as clean (usually called after rendering)
    pub fn markClean(self: *BoxyCanvas) void {
        self.dirty = false;
    }
    
    /// Create a sub-canvas view (doesn't allocate new memory)
    pub fn subCanvas(self: *BoxyCanvas, x: usize, y: usize, width: usize, height: usize) CanvasView {
        return CanvasView{
            .parent = self,
            .offset_x = x,
            .offset_y = y,
            .width = @min(width, self.width - x),
            .height = @min(height, self.height - y),
        };
    }
};

/// A view into a portion of a canvas (for windowing)
pub const CanvasView = struct {
    parent: *BoxyCanvas,
    offset_x: usize,
    offset_y: usize,
    width: usize,
    height: usize,
    
    /// Set a character within this view
    pub fn setChar(self: *CanvasView, x: usize, y: usize, char: u8) void {
        if (x < self.width and y < self.height) {
            self.parent.setChar(self.offset_x + x, self.offset_y + y, char);
        }
    }
    
    /// Blit text within this view
    pub fn blitText(self: *CanvasView, x: usize, y: usize, text: []const u8) !void {
        if (x < self.width and y < self.height) {
            try self.parent.blitText(self.offset_x + x, self.offset_y + y, text);
        }
    }
};