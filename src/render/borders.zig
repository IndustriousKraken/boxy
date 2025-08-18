/// Border rendering functionality for Boxy
///
/// This module handles rendering of all types of borders: top, bottom, 
/// section dividers, header dividers, and row dividers.

const std = @import("std");
const theme = @import("../theme.zig");
const layout = @import("../layout.zig");
const utils = @import("../utils.zig");

/// Render the top border of a box (supports multi-line borders and column junctions)
pub fn renderTopBorder(writer: anytype, box_theme: theme.BoxyTheme, width: usize, column_widths: ?[]usize) !void {
    const tl_corner = box_theme.getTopLeft();
    const tr_corner = box_theme.getTopRight();
    const h_line = box_theme.getTop();
    const junction = box_theme.junction.getOuterColumnTDown();

    // Split each component into lines
    var tl_lines = std.mem.splitScalar(u8, tl_corner, '\n');
    var tr_lines = std.mem.splitScalar(u8, tr_corner, '\n');
    var h_lines = std.mem.splitScalar(u8, h_line, '\n');
    var junction_lines = std.mem.splitScalar(u8, junction, '\n');
    
    // Count maximum lines
    var max_lines: usize = 0;
    var temp_tl = std.mem.splitScalar(u8, tl_corner, '\n');
    var temp_tr = std.mem.splitScalar(u8, tr_corner, '\n');
    var temp_h = std.mem.splitScalar(u8, h_line, '\n');
    var temp_j = std.mem.splitScalar(u8, junction, '\n');
    
    while (temp_tl.next()) |_| : (max_lines = @max(max_lines, 1)) {}
    var line_count: usize = 0;
    while (temp_tr.next()) |_| : (line_count += 1) {}
    max_lines = @max(max_lines, line_count);
    line_count = 0;
    while (temp_h.next()) |_| : (line_count += 1) {}
    max_lines = @max(max_lines, line_count);
    line_count = 0;
    while (temp_j.next()) |_| : (line_count += 1) {}
    max_lines = @max(max_lines, line_count);
    
    if (max_lines == 0) max_lines = 1;
    
    // Render each line
    for (0..max_lines) |_| {
        const tl_line = tl_lines.next() orelse "";
        const tr_line = tr_lines.next() orelse "";
        const h_pattern = h_lines.next() orelse "";
        const junction_pattern = junction_lines.next() orelse "";
        
        // Calculate widths for this line
        const tl_width = utils.displayWidth(tl_line);
        const tr_width = utils.displayWidth(tr_line);
        const content_width = width - tl_width - tr_width;
        
        // Write left corner
        try writer.writeAll(tl_line);
        
        // Fill the horizontal space
        if (column_widths) |col_widths| {
            // Render with column junctions
            try renderHorizontalWithJunctions(writer, h_pattern, junction_pattern, content_width, col_widths);
        } else {
            // Simple horizontal fill
            try renderPattern(writer, h_pattern, content_width);
        }
        
        // Write right corner
        try writer.writeAll(tr_line);
        try writer.writeByte('\n');
    }
}

/// Render the bottom border of a box (supports multi-line borders and column junctions)
pub fn renderBottomBorder(writer: anytype, box_theme: theme.BoxyTheme, width: usize, column_widths: ?[]usize) !void {
    const bl_corner = box_theme.getBottomLeft();
    const br_corner = box_theme.getBottomRight();
    const h_line = box_theme.getBottom();
    const junction = box_theme.junction.getOuterColumnTUp();

    // Split each component into lines
    var bl_lines = std.mem.splitScalar(u8, bl_corner, '\n');
    var br_lines = std.mem.splitScalar(u8, br_corner, '\n');
    var h_lines = std.mem.splitScalar(u8, h_line, '\n');
    var junction_lines = std.mem.splitScalar(u8, junction, '\n');
    
    // Count maximum lines
    var max_lines: usize = 0;
    var temp_bl = std.mem.splitScalar(u8, bl_corner, '\n');
    var temp_br = std.mem.splitScalar(u8, br_corner, '\n');
    var temp_h = std.mem.splitScalar(u8, h_line, '\n');
    var temp_j = std.mem.splitScalar(u8, junction, '\n');
    
    while (temp_bl.next()) |_| : (max_lines = @max(max_lines, 1)) {}
    var line_count: usize = 0;
    while (temp_br.next()) |_| : (line_count += 1) {}
    max_lines = @max(max_lines, line_count);
    line_count = 0;
    while (temp_h.next()) |_| : (line_count += 1) {}
    max_lines = @max(max_lines, line_count);
    line_count = 0;
    while (temp_j.next()) |_| : (line_count += 1) {}
    max_lines = @max(max_lines, line_count);
    
    if (max_lines == 0) max_lines = 1;
    
    // Render each line
    for (0..max_lines) |_| {
        const bl_line = bl_lines.next() orelse "";
        const br_line = br_lines.next() orelse "";
        const h_pattern = h_lines.next() orelse "";
        const junction_pattern = junction_lines.next() orelse "";
        
        // Calculate widths for this line
        const bl_width = utils.displayWidth(bl_line);
        const br_width = utils.displayWidth(br_line);
        const content_width = width - bl_width - br_width;
        
        // Write left corner
        try writer.writeAll(bl_line);
        
        // Fill the horizontal space
        if (column_widths) |col_widths| {
            try renderHorizontalWithJunctions(writer, h_pattern, junction_pattern, content_width, col_widths);
        } else {
            try renderPattern(writer, h_pattern, content_width);
        }
        
        // Write right corner
        try writer.writeAll(br_line);
        try writer.writeByte('\n');
    }
}

/// Render a section divider (between different sections)
pub fn renderSectionDivider(writer: anytype, box_theme: theme.BoxyTheme, width: usize, column_widths: ?[]usize) !void {
    const left_junction = box_theme.junction.getOuterSectionTRight();
    const right_junction = box_theme.junction.getOuterSectionTLeft();
    const h_line = box_theme.horizontal.getSection();
    const cross_junction = box_theme.junction.section_column_cross orelse box_theme.junction.getSectionColumnTDown();

    // Split each component into lines
    var left_lines = std.mem.splitScalar(u8, left_junction, '\n');
    var right_lines = std.mem.splitScalar(u8, right_junction, '\n');
    var h_lines = std.mem.splitScalar(u8, h_line, '\n');
    var cross_lines = std.mem.splitScalar(u8, cross_junction, '\n');
    
    // Count maximum lines
    var max_lines: usize = 0;
    var temp_left = std.mem.splitScalar(u8, left_junction, '\n');
    var temp_right = std.mem.splitScalar(u8, right_junction, '\n');
    var temp_h = std.mem.splitScalar(u8, h_line, '\n');
    var temp_cross = std.mem.splitScalar(u8, cross_junction, '\n');
    
    while (temp_left.next()) |_| : (max_lines = @max(max_lines, 1)) {}
    var line_count: usize = 0;
    while (temp_right.next()) |_| : (line_count += 1) {}
    max_lines = @max(max_lines, line_count);
    line_count = 0;
    while (temp_h.next()) |_| : (line_count += 1) {}
    max_lines = @max(max_lines, line_count);
    line_count = 0;
    while (temp_cross.next()) |_| : (line_count += 1) {}
    max_lines = @max(max_lines, line_count);
    
    if (max_lines == 0) max_lines = 1;
    
    // Render each line
    for (0..max_lines) |_| {
        const left_line = left_lines.next() orelse "";
        const right_line = right_lines.next() orelse "";
        const h_pattern = h_lines.next() orelse "";
        const cross_pattern = cross_lines.next() orelse "";
        
        // Calculate widths for this line
        const left_width = utils.displayWidth(left_line);
        const right_width = utils.displayWidth(right_line);
        const content_width = width - left_width - right_width;
        
        // Write left junction
        try writer.writeAll(left_line);
        
        // Fill the horizontal space
        if (column_widths) |col_widths| {
            try renderHorizontalWithJunctions(writer, h_pattern, cross_pattern, content_width, col_widths);
        } else {
            try renderPattern(writer, h_pattern, content_width);
        }
        
        // Write right junction
        try writer.writeAll(right_line);
        try writer.writeByte('\n');
    }
}

/// Render a header divider (between headers and data)
pub fn renderHeaderDivider(writer: anytype, box_theme: theme.BoxyTheme, width: usize, column_widths: []usize) !void {
    const left_junction = box_theme.junction.getOuterHeaderTRight();
    const right_junction = box_theme.junction.getOuterHeaderTLeft();
    const h_line = box_theme.horizontal.getHeader();
    const cross_junction = box_theme.junction.getHeaderColumnCross();

    // Split each component into lines
    var left_lines = std.mem.splitScalar(u8, left_junction, '\n');
    var right_lines = std.mem.splitScalar(u8, right_junction, '\n');
    var h_lines = std.mem.splitScalar(u8, h_line, '\n');
    var cross_lines = std.mem.splitScalar(u8, cross_junction, '\n');
    
    // Count maximum lines
    var max_lines: usize = 0;
    var temp_left = std.mem.splitScalar(u8, left_junction, '\n');
    var temp_right = std.mem.splitScalar(u8, right_junction, '\n');
    var temp_h = std.mem.splitScalar(u8, h_line, '\n');
    var temp_cross = std.mem.splitScalar(u8, cross_junction, '\n');
    
    while (temp_left.next()) |_| : (max_lines = @max(max_lines, 1)) {}
    var line_count: usize = 0;
    while (temp_right.next()) |_| : (line_count += 1) {}
    max_lines = @max(max_lines, line_count);
    line_count = 0;
    while (temp_h.next()) |_| : (line_count += 1) {}
    max_lines = @max(max_lines, line_count);
    line_count = 0;
    while (temp_cross.next()) |_| : (line_count += 1) {}
    max_lines = @max(max_lines, line_count);
    
    if (max_lines == 0) max_lines = 1;
    
    // Render each line
    for (0..max_lines) |_| {
        const left_line = left_lines.next() orelse "";
        const right_line = right_lines.next() orelse "";
        const h_pattern = h_lines.next() orelse "";
        const cross_pattern = cross_lines.next() orelse "";
        
        // Calculate widths for this line
        const left_width = utils.displayWidth(left_line);
        const right_width = utils.displayWidth(right_line);
        const content_width = width - left_width - right_width;
        
        // Write left junction
        try writer.writeAll(left_line);
        
        // Always render with junctions for header dividers
        try renderHorizontalWithJunctions(writer, h_pattern, cross_pattern, content_width, column_widths);
        
        // Write right junction
        try writer.writeAll(right_line);
        try writer.writeByte('\n');
    }
}

/// Render a row divider (between data rows in tables)
pub fn renderRowDivider(writer: anytype, box_theme: theme.BoxyTheme, width: usize, column_widths: []usize) !void {
    const row_divider = box_theme.horizontal.row orelse return; // No row divider for this theme
    
    const left_junction = box_theme.junction.getOuterRowTRight();
    const right_junction = box_theme.junction.getOuterRowTLeft();
    const cross_junction = box_theme.junction.getRowColumnCross();

    // Split each component into lines
    var left_lines = std.mem.splitScalar(u8, left_junction, '\n');
    var right_lines = std.mem.splitScalar(u8, right_junction, '\n');
    var divider_lines = std.mem.splitScalar(u8, row_divider, '\n');
    var cross_lines = std.mem.splitScalar(u8, cross_junction, '\n');
    
    // Count maximum lines
    var max_lines: usize = 0;
    var temp_left = std.mem.splitScalar(u8, left_junction, '\n');
    var temp_right = std.mem.splitScalar(u8, right_junction, '\n');
    var temp_divider = std.mem.splitScalar(u8, row_divider, '\n');
    var temp_cross = std.mem.splitScalar(u8, cross_junction, '\n');
    
    while (temp_left.next()) |_| : (max_lines = @max(max_lines, 1)) {}
    var line_count: usize = 0;
    while (temp_right.next()) |_| : (line_count += 1) {}
    max_lines = @max(max_lines, line_count);
    line_count = 0;
    while (temp_divider.next()) |_| : (line_count += 1) {}
    max_lines = @max(max_lines, line_count);
    line_count = 0;
    while (temp_cross.next()) |_| : (line_count += 1) {}
    max_lines = @max(max_lines, line_count);
    
    if (max_lines == 0) max_lines = 1;
    
    // Render each line
    for (0..max_lines) |_| {
        const left_line = left_lines.next() orelse "";
        const right_line = right_lines.next() orelse "";
        const divider_pattern = divider_lines.next() orelse "";
        const cross_pattern = cross_lines.next() orelse "";
        
        // Calculate widths for this line
        const left_width = utils.displayWidth(left_line);
        const right_width = utils.displayWidth(right_line);
        const content_width = width - left_width - right_width;
        
        // Write left junction
        try writer.writeAll(left_line);
        
        // Render with junctions
        try renderHorizontalWithJunctions(writer, divider_pattern, cross_pattern, content_width, column_widths);
        
        // Write right junction
        try writer.writeAll(right_line);
        try writer.writeByte('\n');
    }
}

/// Render a horizontal line with column junctions
fn renderHorizontalWithJunctions(writer: anytype, h_pattern: []const u8, junction_pattern: []const u8, total_width: usize, column_widths: []usize) !void {
    var remaining_width = total_width;
    
    for (column_widths, 0..) |col_width, i| {
        // Don't render beyond our available width
        if (remaining_width == 0) break;
        
        // Calculate the actual width to render for this column
        const width_to_render = @min(col_width, remaining_width);
        try renderPattern(writer, h_pattern, width_to_render);
        remaining_width -= width_to_render;
        
        // Add junction between columns (not after the last column)
        if (i < column_widths.len - 1 and remaining_width > 0) {
            const junction_width = utils.displayWidth(junction_pattern);
            if (remaining_width >= junction_width) {
                try writer.writeAll(junction_pattern);
                remaining_width -= junction_width;
            }
        }
    }
    
    // Fill any remaining space with the horizontal pattern
    if (remaining_width > 0) {
        try renderPattern(writer, h_pattern, remaining_width);
    }
}

/// Render a pattern repeated to fill the specified width
pub fn renderPattern(writer: anytype, pattern: []const u8, width: usize) !void {
    if (pattern.len == 0 or width == 0) return;
    
    const pattern_display_width = utils.displayWidth(pattern);
    if (pattern_display_width == 0) return;
    
    // Handle patterns that are wider than the target width
    if (pattern_display_width > width) {
        // Truncate the pattern to fit
        var current_width: usize = 0;
        var i: usize = 0;
        
        while (i < pattern.len and current_width < width) {
            const byte_count = utils.utf8ByteSequenceLength(pattern[i]);
            const char_width = if (byte_count == 4) @as(usize, 2) else @as(usize, 1);
            
            if (current_width + char_width <= width) {
                try writer.writeAll(pattern[i..i + byte_count]);
                current_width += char_width;
                i += byte_count;
            } else {
                break;
            }
        }
        return;
    }
    
    // Repeat the pattern to fill the width
    var filled_width: usize = 0;
    while (filled_width + pattern_display_width <= width) {
        try writer.writeAll(pattern);
        filled_width += pattern_display_width;
    }
    
    // Handle remaining space with partial pattern
    const remaining = width - filled_width;
    if (remaining > 0) {
        var current_width: usize = 0;
        var i: usize = 0;
        
        while (i < pattern.len and current_width < remaining) {
            const byte_count = utils.utf8ByteSequenceLength(pattern[i]);
            const char_width = if (byte_count == 4) @as(usize, 2) else @as(usize, 1);
            
            if (current_width + char_width <= remaining) {
                try writer.writeAll(pattern[i..i + byte_count]);
                current_width += char_width;
                i += byte_count;
            } else {
                break;
            }
        }
    }
}

/// Render a multi-line border by splitting on newlines and rendering each line
pub fn renderMultiLineBorder(writer: anytype, border: []const u8, width: usize) !void {
    var lines = std.mem.splitScalar(u8, border, '\n');
    
    while (lines.next()) |line| {
        try renderPattern(writer, line, width);
        try writer.writeByte('\n');
    }
}