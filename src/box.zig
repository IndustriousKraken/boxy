/// Core BoxyBox implementation
///
/// This module contains the main BoxyBox structure that represents a completed
/// box ready for rendering. Once built, a BoxyBox is immutable and can be
/// printed, measured, or used as a component in larger layouts.

const std = @import("std");
const theme = @import("theme.zig");
const layout = @import("layout.zig");
const render_module = @import("render.zig");
const canvas = @import("canvas.zig");

/// A completed box ready for rendering
pub const BoxyBox = struct {
    allocator: std.mem.Allocator,  // Original allocator for rendered_cache
    arena_ptr: *std.heap.ArenaAllocator,  // Owns all box data (on heap)
    theme: theme.BoxyTheme,
    layout_info: layout.LayoutInfo,
    sections: []Section,
    canvas_data: ?canvas.BoxyCanvas,
    rendered_cache: ?[]const u8,
    
    /// Initialize a new box with arena pointer from builder
    pub fn initWithArenaPtr(allocator: std.mem.Allocator, arena_ptr: *std.heap.ArenaAllocator, config: anytype, sections: anytype) !BoxyBox {
        const arena_allocator = arena_ptr.allocator();
        
        // Check if any section is a canvas
        var canvas_section: ?Section = null;
        for (sections.items) |section| {
            if (section.section_type == .canvas) {
                canvas_section = section;
                break;
            }
        }
        
        // Create canvas if needed
        var canvas_data: ?canvas.BoxyCanvas = null;
        if (canvas_section) |cs| {
            canvas_data = try canvas.BoxyCanvas.init(allocator, cs.canvas_width, cs.canvas_height);
        }
        
        return .{
            .allocator = allocator,
            .arena_ptr = arena_ptr,
            .theme = config.theme,
            .layout_info = try layout.calculate(arena_allocator, config, sections),
            .sections = try arena_allocator.dupe(Section, sections.items),
            .canvas_data = canvas_data,
            .rendered_cache = null,
        };
    }
    
    /// Initialize a new box from builder configuration (legacy, creates its own arena)
    pub fn init(allocator: std.mem.Allocator, config: anytype, sections: anytype) !BoxyBox {
        const arena_ptr = try allocator.create(std.heap.ArenaAllocator);
        arena_ptr.* = std.heap.ArenaAllocator.init(allocator);
        return initWithArenaPtr(allocator, arena_ptr, config, sections);
    }
    
    /// Clean up allocated memory
    pub fn deinit(self: *BoxyBox) void {
        // Free rendered cache (uses original allocator)
        if (self.rendered_cache) |cache| {
            self.allocator.free(cache);
        }
        
        // Free canvas if present (might use original allocator)
        if (self.canvas_data) |*canvas_ptr| {
            canvas_ptr.deinit();
        }
        
        // Destroy the arena - this frees EVERYTHING else in one go!
        self.arena_ptr.deinit();
        
        // Now free the arena struct itself (it was allocated on heap)
        self.allocator.destroy(self.arena_ptr);
    }
    
    /// Print the box to a writer (e.g., stdout)
    pub fn print(self: *BoxyBox, writer: anytype) !void {
        const output = try self.render();
        try writer.writeAll(output);
    }
    
    /// Render the box to a string
    pub fn render(self: *BoxyBox) ![]const u8 {
        if (self.rendered_cache) |cache| {
            return cache;
        }
        
        // Render and cache the result
        const output = try render_module.renderBox(self.allocator, self);
        self.rendered_cache = output;
        return output;
    }
    
    /// Get the coordinates of this box (for positioning)
    pub fn getCoords(self: *const BoxyBox) Coordinates {
        return .{
            .row = 0,  // Will be set by container if positioned
            .col = 0,
            .width = self.layout_info.total_width,
            .height = self.layout_info.total_height,
        };
    }
    
    /// Get the inner content area (excluding borders)
    pub fn getContentArea(self: *const BoxyBox) Coordinates {
        const thickness = self.theme.getBorderThickness();
        return .{
            .row = thickness.top,
            .col = thickness.left,
            .width = self.layout_info.content_width,
            .height = self.layout_info.content_height,
        };
    }
    
    /// Get the canvas for direct manipulation (if this box has one)
    pub fn getCanvas(self: *BoxyBox) ?*canvas.BoxyCanvas {
        if (self.canvas_data) |*canvas_ptr| {
            return canvas_ptr;
        }
        return null;
    }
    
    /// Get raw access to the rendering buffer (for advanced users)
    pub fn getRawBuffer(self: *BoxyBox) ![]u8 {
        _ = self;
        // Implementation placeholder
        // This would return a mutable buffer that can be modified directly
        return error.NotImplemented;
    }
    
    /// Blit text at a specific position within the content area
    pub fn blitText(self: *BoxyBox, x: usize, y: usize, text: []const u8) !void {
        if (self.canvas_data) |*canvas_ptr| {
            try canvas_ptr.blitText(x, y, text);
            // Invalidate render cache
            if (self.rendered_cache) |cache| {
                self.allocator.free(cache);
                self.rendered_cache = null;
            }
        }
    }
    
    /// Blit a multi-line block of text
    pub fn blitBlock(self: *BoxyBox, x: usize, y: usize, block: []const u8) !void {
        if (self.canvas_data) |*canvas_ptr| {
            try canvas_ptr.blitBlock(x, y, block);
            // Invalidate render cache
            if (self.rendered_cache) |cache| {
                self.allocator.free(cache);
                self.rendered_cache = null;
            }
        }
    }
    
    /// Refresh just the canvas content (not the borders)
    pub fn refreshCanvas(self: *BoxyBox) !void {
        if (self.canvas_data) |_| {
            // Invalidate only the content portion of the cache
            // Implementation placeholder
            if (self.rendered_cache) |cache| {
                self.allocator.free(cache);
                self.rendered_cache = null;
            }
        }
    }
    
    /// Update a specific cell in the table (for non-canvas boxes)
    pub fn updateCell(self: *BoxyBox, row: usize, col: usize, value: []const u8) !void {
        _ = row;
        _ = col;
        _ = value;
        // Find the appropriate section and update the cell
        // Implementation placeholder
        
        // Invalidate render cache
        if (self.rendered_cache) |cache| {
            self.allocator.free(cache);
            self.rendered_cache = null;
        }
    }
    
    /// Get the coordinates of a specific cell
    pub fn getCellCoords(self: *const BoxyBox, row: usize, col: usize) Coordinates {
        _ = self;
        _ = row;
        _ = col;
        // Calculate based on layout info
        // Implementation placeholder
        return .{ .row = 0, .col = 0, .width = 0, .height = 0 };
    }
};

/// Coordinates and dimensions
pub const Coordinates = struct {
    row: usize,
    col: usize,
    width: usize,
    height: usize,
};

/// A section of content within the box
pub const Section = struct {
    section_type: SectionType,
    orientation: layout.Orientation,
    headers: []const []const u8,
    data: []const []const u8,
    alignment: layout.Alignment,
    canvas_width: usize = 0,
    canvas_height: usize = 0,
};

/// Types of sections that can exist in a box
pub const SectionType = enum {
    title,      // Title section (centered, possibly with padding)
    headers,    // Column/row headers
    data,       // Main data content
    canvas,     // Canvas for dynamic content
    divider,    // Horizontal divider line
};