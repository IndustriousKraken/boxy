/// Section rendering functionality for Boxy
///
/// This module handles rendering of different section types:
/// titles, headers, data, dividers, and canvas sections.

const std = @import("std");
const box = @import("../box.zig");
const layout = @import("../layout.zig");
const utils = @import("../utils.zig");
const content = @import("content.zig");
const tables = @import("tables.zig");
const canvas_render = @import("canvas_render.zig");

/// Groups common rendering parameters
pub const RenderContext = struct {
    theme: @import("../theme.zig").BoxyTheme,
    total_width: usize,
    content_width: usize,
    layout_info: layout.LayoutInfo,
    canvas_data: ?*@import("../canvas.zig").BoxyCanvas = null,
};

/// Helper to calculate how many lines a section will take to render
pub fn getSectionLineCount(section: box.Section) usize {
    return switch (section.section_type) {
        .title => section.data.len + 2, // Title lines + padding
        .headers => 1,
        .data => if (section.headers.len > 0 and section.data.len > 0)
            section.data.len / section.headers.len
        else if (section.data.len > 0)
            1  // Single row of data
        else
            0,
        .divider => 1,
        .canvas => section.canvas_height,
    };
}

/// Render a section based on its type
pub fn renderSection(writer: anytype, section: box.Section, ctx: RenderContext) !void {
    switch (section.section_type) {
        .title => try renderTitleSection(writer, section, ctx),
        .headers => try renderHeaderSection(writer, section, ctx),
        .data => try renderDataSection(writer, section, ctx),
        .divider => try renderDividerSection(writer, ctx),
        .canvas => try canvas_render.renderCanvasSection(writer, section, ctx),
    }
}

/// Render a title section with padding
fn renderTitleSection(writer: anytype, section: box.Section, ctx: RenderContext) !void {
    const padding = ctx.layout_info.padding;
    
    // Top padding
    for (0..padding.top) |_| {
        try content.renderContentRow(writer, ctx.theme, ctx.total_width, "");
    }
    
    // Title lines
    for (section.data) |line| {
        const centered = try utils.centerText(std.heap.page_allocator, line, ctx.content_width);
        defer std.heap.page_allocator.free(centered);
        try content.renderContentRow(writer, ctx.theme, ctx.total_width, centered);
    }
    
    // Bottom padding
    for (0..padding.bottom) |_| {
        try content.renderContentRow(writer, ctx.theme, ctx.total_width, "");
    }
}

/// Render a header section
fn renderHeaderSection(writer: anytype, section: box.Section, ctx: RenderContext) !void {
    const options = tables.TableRenderOptions{
        .cells = section.headers,
        .column_widths = ctx.layout_info.column_widths,
        .alignment = section.alignment,
        .cell_padding = ctx.layout_info.cell_padding,
    };
    try tables.renderTableRow(writer, ctx, options);
}

/// Render a data section with multiple rows
fn renderDataSection(writer: anytype, section: box.Section, ctx: RenderContext) !void {
    if (section.headers.len == 0 or section.data.len == 0) return;
    
    // Convert data array to rows
    const allocator = std.heap.page_allocator;
    var rows = std.ArrayList([]const []const u8).init(allocator);
    defer rows.deinit();
    
    const num_columns = section.headers.len;
    const num_rows = section.data.len / num_columns;
    
    for (0..num_rows) |row| {
        const start_idx = row * num_columns;
        const end_idx = start_idx + num_columns;
        try rows.append(section.data[start_idx..end_idx]);
    }
    
    // Render each row
    for (rows.items, 0..) |row, i| {
        const options = tables.TableRenderOptions{
            .cells = row,
            .column_widths = ctx.layout_info.column_widths,
            .alignment = section.alignment,
            .cell_padding = ctx.layout_info.cell_padding,
        };
        try tables.renderTableRow(writer, ctx, options);
        
        // Add row divider if theme specifies it (but not after last row)
        if (ctx.theme.horizontal.row) |_| {
            if (i < rows.items.len - 1) {
                try tables.renderRowDivider(writer, ctx);
            }
        }
    }
}

/// Render a divider section
fn renderDividerSection(writer: anytype, ctx: RenderContext) !void {
    const borders = @import("borders.zig");
    try borders.renderSectionDivider(writer, ctx.theme, ctx.total_width, null);
}