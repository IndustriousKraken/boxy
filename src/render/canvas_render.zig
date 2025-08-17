/// Canvas rendering functionality for Boxy
///
/// This module handles rendering of canvas sections, which contain
/// dynamic drawable content for games and animations.

const std = @import("std");
const box = @import("../box.zig");
const canvas = @import("../canvas.zig");
const content = @import("content.zig");

/// Import RenderContext from sections to avoid circular dependency
const sections = @import("sections.zig");
pub const RenderContext = sections.RenderContext;

/// Render a canvas section
pub fn renderCanvasSection(writer: anytype, section: box.Section, ctx: RenderContext) !void {
    if (ctx.canvas_data) |canvas_data| {
        // Render each row of the canvas
        for (0..canvas_data.height) |y| {
            // Access the buffer directly since it's read-only rendering
            const row = canvas_data.buffer[y];
            try content.renderContentRow(writer, ctx.theme, ctx.total_width, row);
        }
    } else {
        // If no canvas data, render empty space with the expected dimensions
        for (0..section.canvas_height) |_| {
            // Create an empty line of the correct width
            var empty_line = std.ArrayList(u8).init(std.heap.page_allocator);
            defer empty_line.deinit();
            
            for (0..section.canvas_width) |_| {
                try empty_line.append(' ');
            }
            
            try content.renderContentRow(writer, ctx.theme, ctx.total_width, empty_line.items);
        }
    }
}

/// Render a canvas directly (helper function)
pub fn renderCanvas(writer: anytype, canvas_data: *const canvas.BoxyCanvas, ctx: RenderContext) !void {
    for (canvas_data.buffer) |row| {
        try content.renderContentRow(writer, ctx.theme, ctx.total_width, row);
    }
}