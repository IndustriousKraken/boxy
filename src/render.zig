/// Rendering pipeline for Boxy
///
/// This module coordinates the rendering of boxes to strings. It takes
/// layout information and themes and produces the final output with borders,
/// content, and proper formatting.
///
/// The rendering is split into specialized modules:
/// - borders: Top, bottom, and divider borders with column junctions
/// - content: Individual content rows and cells with alignment
/// - sections: Title, header, data, divider, and canvas sections
/// - tables: Table rows with column separators and spacing
/// - canvas_render: Canvas-specific rendering for dynamic content

const std = @import("std");
const box = @import("box.zig");

// Import rendering modules
const borders = @import("render/borders.zig");
const content = @import("render/content.zig");
const sections = @import("render/sections.zig");
const tables = @import("render/tables.zig");
const canvas_render = @import("render/canvas_render.zig");

// Re-export commonly used types
pub const RenderContext = sections.RenderContext;
pub const TableRenderOptions = tables.TableRenderOptions;

// Re-export utility functions
pub const renderPattern = borders.renderPattern;
pub const renderMultiLineBorder = borders.renderMultiLineBorder;
pub const renderContentRow = content.renderContentRow;
pub const renderCell = content.renderCell;
pub const getSeparatorWidth = tables.getSeparatorWidth;
pub const getSectionLineCount = sections.getSectionLineCount;

/// Render a complete box to a string
pub fn renderBox(allocator: std.mem.Allocator, boxy_box: *const box.BoxyBox) ![]const u8 {
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();
    
    const writer = buffer.writer();
    
    // Create render context
    const ctx = RenderContext{
        .theme = boxy_box.theme,
        .total_width = boxy_box.layout_info.total_width,
        .content_width = boxy_box.layout_info.content_width,
        .layout_info = boxy_box.layout_info,
        .canvas_data = boxy_box.canvas_data,
    };
    
    // Determine if we have column-based content
    const has_columns = blk: {
        for (boxy_box.sections) |section| {
            if (section.section_type == .headers or section.section_type == .data) {
                break :blk true;
            }
        }
        break :blk false;
    };
    
    // Render top border with appropriate junctions
    const show_top_junctions = has_columns and 
        boxy_box.sections.len > 0 and 
        (boxy_box.sections[0].section_type == .headers or boxy_box.sections[0].section_type == .data);
    
    if (show_top_junctions) {
        try borders.renderTopBorder(writer, ctx.theme, ctx.total_width, ctx.layout_info.column_widths);
    } else {
        try borders.renderTopBorder(writer, ctx.theme, ctx.total_width, null);
    }
    
    // Render each section
    for (boxy_box.sections, 0..) |section, i| {
        try sections.renderSection(writer, section, ctx);
        
        // Add section divider after title (with column junctions if next section has columns)
        if (i < boxy_box.sections.len - 1 and section.section_type == .title) {
            const next_has_columns = if (i + 1 < boxy_box.sections.len)
                boxy_box.sections[i + 1].section_type == .headers or boxy_box.sections[i + 1].section_type == .data
            else
                false;
            
            if (next_has_columns and has_columns) {
                try borders.renderSectionDivider(writer, ctx.theme, ctx.total_width, ctx.layout_info.column_widths);
            } else {
                try borders.renderSectionDivider(writer, ctx.theme, ctx.total_width, null);
            }
        }
        
        // Add divider between headers and data
        if (section.section_type == .headers and i < boxy_box.sections.len - 1) {
            try borders.renderHeaderDivider(writer, ctx.theme, ctx.total_width, ctx.layout_info.column_widths);
        }
    }
    
    // Render bottom border
    if (has_columns) {
        try borders.renderBottomBorder(writer, ctx.theme, ctx.total_width, ctx.layout_info.column_widths);
    } else {
        try borders.renderBottomBorder(writer, ctx.theme, ctx.total_width, null);
    }
    
    return try buffer.toOwnedSlice();
}