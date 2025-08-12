/// Rendering pipeline for Boxy
///
/// This module handles the actual rendering of boxes to strings. It takes
/// layout information and themes and produces the final output with borders,
/// content, and proper formatting.

const std = @import("std");
const theme = @import("theme.zig");
const box = @import("box.zig");
const layout = @import("layout.zig");
const canvas = @import("canvas.zig");
const utils = @import("utils.zig");

/// Rendering constants
const Constants = struct {
    /// Default ellipsis indicator for truncated text
    const ELLIPSIS = "...";
    
    /// Width of the ellipsis in display columns
    const ELLIPSIS_WIDTH = 3;
    
    /// Minimum width needed to show truncated text with ellipsis
    const MIN_TRUNCATE_WIDTH = 3;
    
    /// Fallback column width when not specified
    const FALLBACK_COLUMN_WIDTH = 10;
};

/// Groups common rendering parameters to reduce parameter passing
pub const RenderContext = struct {
    theme: theme.BoxyTheme,
    total_width: usize,
    content_width: usize,
    layout_info: layout.LayoutInfo,
};

/// Options specific to table rendering
pub const TableRenderOptions = struct {
    cells: []const []const u8,
    column_widths: []usize,
    alignment: layout.Alignment,
    cell_padding: usize,
};

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
    };
    
    // Render top border (with column junctions if there are headers)
    const has_columns = blk: {
        for (boxy_box.sections) |section| {
            if (section.section_type == .headers or section.section_type == .data) {
                break :blk true;
            }
        }
        break :blk false;
    };
    
    if (has_columns) {
        try renderTopBorder(writer, ctx.theme, ctx.total_width, ctx.layout_info.column_widths);
    } else {
        try renderTopBorder(writer, ctx.theme, ctx.total_width, null);
    }
    
    // Render each section
    for (boxy_box.sections, 0..) |section, i| {
        try renderSection(writer, section, ctx);
        
        // Add section divider after title (with column junctions if next section has columns)
        if (i < boxy_box.sections.len - 1 and section.section_type == .title) {
            const next_has_columns = if (i + 1 < boxy_box.sections.len)
                boxy_box.sections[i + 1].section_type == .headers or boxy_box.sections[i + 1].section_type == .data
            else
                false;
            
            if (next_has_columns and has_columns) {
                try renderSectionDivider(writer, ctx.theme, ctx.total_width, ctx.layout_info.column_widths);
            } else {
                try renderSectionDivider(writer, ctx.theme, ctx.total_width, null);
            }
        }
        
        // Add divider between headers and data
        if (section.section_type == .headers and i < boxy_box.sections.len - 1) {
            try renderHeaderDivider(writer, ctx.theme, ctx.total_width, ctx.layout_info.column_widths);
        }
    }
    
    // Render canvas if present
    if (boxy_box.canvas_data) |*canvas_data| {
        try renderCanvas(writer, canvas_data, ctx);
    }
    
    // Render bottom border (with column junctions if there are columns)
    if (has_columns) {
        try renderBottomBorder(writer, ctx.theme, ctx.total_width, ctx.layout_info.column_widths);
    } else {
        try renderBottomBorder(writer, ctx.theme, ctx.total_width, null);
    }
    
    return try buffer.toOwnedSlice();
}

/// Render the top border of a box (supports multi-line borders and column junctions)
fn renderTopBorder(writer: anytype, box_theme: theme.BoxyTheme, width: usize, column_widths: ?[]usize) !void {
    const tl_corner = box_theme.getTopLeft();
    const tr_corner = box_theme.getTopRight();
    const top_pattern = box_theme.getTop();
    
    // Check if this is a multi-line border
    var top_lines = std.mem.splitScalar(u8, top_pattern, '\n');
    var line_count: usize = 0;
    while (top_lines.next()) |_| {
        line_count += 1;
    }
    
    if (line_count <= 1) {
        // Single line border
        try writer.writeAll(tl_corner);
        const tl_width = utils.displayWidth(tl_corner);
        const tr_width = utils.displayWidth(tr_corner);
        const border_width = if (width > tl_width + tr_width) width - tl_width - tr_width else 0;
        
        // If we have columns, render with junctions
        if (column_widths) |cols| {
            var position: usize = 0;
            for (cols, 0..) |col_width, i| {
                try renderPattern(writer, top_pattern, col_width);
                position += col_width;
                
                // Add junction if not last column
                if (i < cols.len - 1) {
                    try writer.writeAll(box_theme.junction.top);
                    position += 1; // Junction is typically 1 display column
                }
            }
            
            // Fill any remaining space
            if (position < border_width) {
                try renderPattern(writer, top_pattern, border_width - position);
            }
        } else {
            // No columns, just render the border
            try renderPattern(writer, top_pattern, border_width);
        }
        
        try writer.writeAll(tr_corner);
        try writer.writeByte('\n');
    } else {
        // Multi-line border - render each line
        top_lines = std.mem.splitScalar(u8, top_pattern, '\n');
        var line_idx: usize = 0;
        while (top_lines.next()) |line| {
            if (line_idx == 0) {
                // First line gets corners
                try writer.writeAll(tl_corner);
                const tl_width = utils.displayWidth(tl_corner);
                const tr_width = utils.displayWidth(tr_corner);
                const border_width = if (width > tl_width + tr_width) width - tl_width - tr_width else 0;
                try renderPattern(writer, line, border_width);
                try writer.writeAll(tr_corner);
            } else {
                // Subsequent lines
                try renderPattern(writer, line, width);
            }
            try writer.writeByte('\n');
            line_idx += 1;
        }
    }
}

/// Render the bottom border of a box (supports multi-line borders and column junctions)
fn renderBottomBorder(writer: anytype, box_theme: theme.BoxyTheme, width: usize, column_widths: ?[]usize) !void {
    const bl_corner = box_theme.getBottomLeft();
    const br_corner = box_theme.getBottomRight();
    const bottom_pattern = box_theme.getBottom();
    
    // Check if this is a multi-line border
    var bottom_lines = std.mem.splitScalar(u8, bottom_pattern, '\n');
    var line_count: usize = 0;
    while (bottom_lines.next()) |_| {
        line_count += 1;
    }
    
    if (line_count <= 1) {
        // Single line border
        try writer.writeAll(bl_corner);
        const bl_width = utils.displayWidth(bl_corner);
        const br_width = utils.displayWidth(br_corner);
        const border_width = if (width > bl_width + br_width) width - bl_width - br_width else 0;
        
        // If we have columns, render with junctions
        if (column_widths) |cols| {
            var position: usize = 0;
            for (cols, 0..) |col_width, i| {
                try renderPattern(writer, bottom_pattern, col_width);
                position += col_width;
                
                // Add junction if not last column
                if (i < cols.len - 1) {
                    try writer.writeAll(box_theme.junction.bottom);
                    position += 1; // Junction is typically 1 display column
                }
            }
            
            // Fill any remaining space
            if (position < border_width) {
                try renderPattern(writer, bottom_pattern, border_width - position);
            }
        } else {
            // No columns, just render the border
            try renderPattern(writer, bottom_pattern, border_width);
        }
        
        try writer.writeAll(br_corner);
        try writer.writeByte('\n');
    } else {
        // Multi-line border - render each line
        bottom_lines = std.mem.splitScalar(u8, bottom_pattern, '\n');
        var line_idx: usize = 0;
        while (bottom_lines.next()) |line| {
            if (line_idx == 0) {
                // First line gets corners
                try writer.writeAll(bl_corner);
                const bl_width = utils.displayWidth(bl_corner);
                const br_width = utils.displayWidth(br_corner);
                const border_width = if (width > bl_width + br_width) width - bl_width - br_width else 0;
                try renderPattern(writer, line, border_width);
                try writer.writeAll(br_corner);
            } else {
                // Subsequent lines
                try renderPattern(writer, line, width);
            }
            try writer.writeByte('\n');
            line_idx += 1;
        }
    }
}

/// Render a section divider (e.g., between title and content)
fn renderSectionDivider(writer: anytype, box_theme: theme.BoxyTheme, width: usize, column_widths: ?[]usize) !void {
    // Left junction
    try writer.writeAll(box_theme.junction.left);
    
    // Calculate actual junction widths
    const left_width = utils.displayWidth(box_theme.junction.left);
    const right_width = utils.displayWidth(box_theme.junction.right);
    
    // Divider line (using section border from inner borders)
    const divider_width = if (width > left_width + right_width) 
        width - left_width - right_width 
    else 
        0;
    
    // If we have columns, render with junctions
    if (column_widths) |cols| {
        var position: usize = 0;
        for (cols, 0..) |col_width, i| {
            try renderPattern(writer, box_theme.inner.section, col_width);
            position += col_width;
            
            // Add junction if not last column (use t_down since columns continue down)
            if (i < cols.len - 1) {
                try writer.writeAll(box_theme.inner.t_down);
                position += 1;
            }
        }
        
        // Fill any remaining space
        if (position < divider_width) {
            try renderPattern(writer, box_theme.inner.section, divider_width - position);
        }
    } else {
        // No columns, just render the divider
        try renderPattern(writer, box_theme.inner.section, divider_width);
    }
    
    // Right junction
    try writer.writeAll(box_theme.junction.right);
    try writer.writeByte('\n');
}

/// Render a header divider with column junctions
fn renderHeaderDivider(writer: anytype, box_theme: theme.BoxyTheme, width: usize, column_widths: []usize) !void {
    // Left junction
    try writer.writeAll(box_theme.junction.left);
    
    // Calculate actual junction widths
    const left_width = utils.displayWidth(box_theme.junction.left);
    const right_width = utils.displayWidth(box_theme.junction.right);
    const t_down_width = utils.displayWidth(box_theme.inner.t_down);
    
    // Get the display width of the column separator (first line only)
    const column_separator = box_theme.inner.v;
    const separator_first_line = if (std.mem.indexOfScalar(u8, column_separator, '\n')) |idx|
        column_separator[0..idx]
    else
        column_separator;
    const separator_width = utils.displayWidth(separator_first_line);
    
    // Draw horizontal line with column junctions
    var position: usize = 0;
    for (column_widths, 0..) |col_width, i| {
        // For all but the last column, we need to account for the junction
        var line_width = col_width;
        if (i < column_widths.len - 1) {
            // If the t-junction is wider than the separator, reduce the line before it
            if (t_down_width > separator_width) {
                const adjustment = t_down_width - separator_width;
                line_width = if (col_width > adjustment) col_width - adjustment else 0;
            }
        }
        
        // Draw horizontal line for adjusted width
        try renderPattern(writer, box_theme.inner.h, line_width);
        position += line_width;
        
        // Add column junction if not last column
        if (i < column_widths.len - 1) {
            try writer.writeAll(box_theme.inner.t_down);  // T-junction where column continues down
            position += t_down_width;  // Already calculated above
        }
    }
    
    // Fill remaining space if needed
    const content_width = if (width > left_width + right_width) 
        width - left_width - right_width 
    else 
        0;
    if (position < content_width) {
        try renderPattern(writer, box_theme.inner.h, content_width - position);
    }
    
    // Right junction
    try writer.writeAll(box_theme.junction.right);
    try writer.writeByte('\n');
}

/// Render a content section
fn renderSection(writer: anytype, section: box.Section, ctx: RenderContext) !void {
    switch (section.section_type) {
        .title => try renderTitleSection(writer, section, ctx),
        .headers => try renderHeaderSection(writer, section, ctx),
        .data => try renderDataSection(writer, section, ctx),
        .divider => try renderDividerSection(writer, ctx),
        .canvas => {}, // Canvas is rendered separately
    }
}

/// Render a title section (with padding and centering)  
fn renderTitleSection(writer: anytype, section: box.Section, ctx: RenderContext) !void {
    const padding = ctx.layout_info.padding;
    
    // Top padding
    for (0..padding.top) |_| {
        try renderContentRow(writer, ctx.theme, ctx.total_width, "");
    }
    
    // Title lines (centered)
    for (section.data) |line| {
        // Use a temporary allocator for centering
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();
        
        const centered = try utils.centerText(allocator, line, ctx.content_width);
        try renderContentRow(writer, ctx.theme, ctx.total_width, centered);
    }
    
    // Bottom padding
    for (0..padding.bottom) |_| {
        try renderContentRow(writer, ctx.theme, ctx.total_width, "");
    }
}

/// Render a header section
fn renderHeaderSection(writer: anytype, section: box.Section, ctx: RenderContext) !void {
    // Headers with column separators
    const options = TableRenderOptions{
        .cells = section.headers,
        .column_widths = ctx.layout_info.column_widths,
        .alignment = section.alignment,
        .cell_padding = ctx.layout_info.cell_padding,
    };
    try renderTableRow(writer, ctx, options);
}

/// Render a data section
fn renderDataSection(writer: anytype, section: box.Section, ctx: RenderContext) !void {
    // Data rows with column separators
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    const rows = try utils.organizeDataIntoRows(allocator, section.data, section.headers.len);
    defer rows.deinit();
    
    for (rows.items, 0..) |row, i| {
        const options = TableRenderOptions{
            .cells = row,
            .column_widths = ctx.layout_info.column_widths,
            .alignment = section.alignment,
            .cell_padding = ctx.layout_info.cell_padding,
        };
        try renderTableRow(writer, ctx, options);
        
        // Add row divider if theme specifies it (but not after last row)
        if (ctx.theme.inner.row_divider) |_| {
            if (i < rows.items.len - 1) {
                try renderRowDivider(writer, ctx);
            }
        }
    }
}

/// Render a divider section
fn renderDividerSection(writer: anytype, ctx: RenderContext) !void {
    // Divider sections don't have columns themselves
    try renderSectionDivider(writer, ctx.theme, ctx.total_width, null);
}

/// Render a canvas
fn renderCanvas(writer: anytype, canvas_data: *const canvas.BoxyCanvas, ctx: RenderContext) !void {
    for (canvas_data.buffer) |row| {
        try renderContentRow(writer, ctx.theme, ctx.total_width, row);
    }
}

/// Render a single content row with borders (supports multi-line borders)
fn renderContentRow(writer: anytype, box_theme: theme.BoxyTheme, total_width: usize, content: []const u8) !void {
    const left_border = box_theme.getLeft();
    const right_border = box_theme.getRight();
    
    // Split borders into lines (use splitScalar to preserve spaces)
    var left_lines = std.mem.splitScalar(u8, left_border, '\n');
    var right_lines = std.mem.splitScalar(u8, right_border, '\n');
    
    // Count lines in borders
    var max_lines: usize = 1;
    var left_line_count: usize = 0;
    var right_line_count: usize = 0;
    while (left_lines.next()) |_| {
        left_line_count += 1;
    }
    while (right_lines.next()) |_| {
        right_line_count += 1;
    }
    max_lines = @max(left_line_count, right_line_count);
    if (max_lines == 0) max_lines = 1;
    
    // Reset iterators
    left_lines = std.mem.splitScalar(u8, left_border, '\n');
    right_lines = std.mem.splitScalar(u8, right_border, '\n');
    
    // Render each line
    for (0..max_lines) |line_idx| {
        // Get the border parts for this line
        const left_part = left_lines.next() orelse "";
        const right_part = right_lines.next() orelse "";
        
        // Calculate widths
        const left_width = utils.displayWidth(left_part);
        const right_width = utils.displayWidth(right_part);
        const content_width = total_width - left_width - right_width;
        
        // Write left border
        try writer.writeAll(left_part);
        
        // Write content or padding (only on first line)
        if (line_idx == 0) {
            const content_display_width = utils.displayWidth(content);
            if (content_display_width < content_width) {
                try writer.writeAll(content);
                // Pad with spaces
                for (content_display_width..content_width) |_| {
                    try writer.writeByte(' ');
                }
            } else {
                try writer.writeAll(content);  // For now, just write it all
            }
        } else {
            // Subsequent lines get spaces
            for (0..content_width) |_| {
                try writer.writeByte(' ');
            }
        }
        
        // Write right border
        try writer.writeAll(right_part);
        try writer.writeByte('\n');
    }
}

/// Render a table row with column separators
fn renderTableRow(writer: anytype, ctx: RenderContext, options: TableRenderOptions) !void {
    const cells = options.cells;
    const box_theme = ctx.theme;
    const column_widths = options.column_widths;
    const total_width = ctx.total_width;
    const alignment = options.alignment;
    const cell_padding = options.cell_padding;
    // Handle multi-line borders and separators directly
    const left_border = box_theme.getLeft();
    const right_border = box_theme.getRight();
    const column_separator = box_theme.inner.v;
    
    // Split borders and separator into lines
    var left_lines = std.mem.splitScalar(u8, left_border, '\n');
    var right_lines = std.mem.splitScalar(u8, right_border, '\n');
    var separator_lines = std.mem.splitScalar(u8, column_separator, '\n');
    
    // Count max lines
    var max_lines: usize = 1;
    var left_line_count: usize = 0;
    var right_line_count: usize = 0;
    var sep_line_count: usize = 0;
    
    var temp_left = std.mem.splitScalar(u8, left_border, '\n');
    while (temp_left.next()) |_| left_line_count += 1;
    
    var temp_right = std.mem.splitScalar(u8, right_border, '\n');
    while (temp_right.next()) |_| right_line_count += 1;
    
    var temp_sep = std.mem.splitScalar(u8, column_separator, '\n');
    while (temp_sep.next()) |_| sep_line_count += 1;
    
    max_lines = @max(left_line_count, @max(right_line_count, sep_line_count));
    if (max_lines == 0) max_lines = 1;
    
    // Render each line
    for (0..max_lines) |line_idx| {
        // Reset iterators for this line
        if (line_idx > 0) {
            left_lines = std.mem.splitScalar(u8, left_border, '\n');
            right_lines = std.mem.splitScalar(u8, right_border, '\n');
            separator_lines = std.mem.splitScalar(u8, column_separator, '\n');
            // Skip to current line
            for (0..line_idx) |_| {
                _ = left_lines.next();
                _ = right_lines.next();
                _ = separator_lines.next();
            }
        }
        
        const left_part = left_lines.next() orelse "";
        const right_part = right_lines.next() orelse "";
        const separator_part = separator_lines.next() orelse "";
        
        // Calculate widths
        const left_width = utils.displayWidth(left_part);
        const right_width = utils.displayWidth(right_part);
        const content_width = total_width - left_width - right_width;
        
        // Write left border
        try writer.writeAll(left_part);
        
        // Write cells with separators
        var content_pos: usize = 0;
        for (cells, 0..) |cell, i| {
            if (i > 0) {
                // Column separator
                try writer.writeAll(separator_part);
                content_pos += utils.displayWidth(separator_part);
            }
            
            // Cell content (only on first line)
            const width = if (i < column_widths.len) column_widths[i] else Constants.FALLBACK_COLUMN_WIDTH;
            
            if (line_idx == 0) {
                // First line: render actual cell content
                // Apply cell padding first (internal spacing)
                for (0..cell_padding) |_| {
                    try writer.writeByte(' ');
                }
                
                // Calculate available width after cell padding
                const available_width = if (width > cell_padding * 2) 
                    width - (cell_padding * 2) 
                else 
                    0;
                
                const cell_display_width = utils.displayWidth(cell);
                const alignment_padding = alignment.getPadding(cell_display_width, available_width);
                
                // Alignment padding
                for (0..alignment_padding.left) |_| {
                    try writer.writeByte(' ');
                }
                
                // Text with truncation if needed
                if (cell_display_width <= available_width - alignment_padding.left - alignment_padding.right) {
                    // Text fits, write it all
                    try writer.writeAll(cell);
                    // Alignment right padding
                    for (0..alignment_padding.right) |_| {
                        try writer.writeByte(' ');
                    }
                    // Cell padding on the right
                    for (0..cell_padding) |_| {
                        try writer.writeByte(' ');
                    }
                } else if (available_width > Constants.MIN_TRUNCATE_WIDTH) {
                    // Text too long, truncate with ellipsis
                    const truncate_width = available_width - alignment_padding.left;
                    if (truncate_width > Constants.ELLIPSIS_WIDTH) {
                        // We have room for at least one character plus ellipsis
                        const ellipsis = Constants.ELLIPSIS;
                        const max_text_width = truncate_width - Constants.ELLIPSIS_WIDTH;
                        
                        // Find how many bytes to keep to fit in max_text_width display columns
                        var byte_count: usize = 0;
                        var display_count: usize = 0;
                        while (byte_count < cell.len and display_count < max_text_width) {
                            const char_bytes = utils.utf8ByteSequenceLength(cell[byte_count]);
                            const old_byte_count = byte_count;
                            byte_count += char_bytes;
                            
                            // Check display width of this character
                            const char_display_width = utils.displayWidth(cell[old_byte_count..byte_count]);
                            if (display_count + char_display_width > max_text_width) {
                                byte_count = old_byte_count; // Don't include this character
                                break;
                            }
                            display_count += char_display_width;
                        }
                        
                        try writer.writeAll(cell[0..byte_count]);
                        try writer.writeAll(ellipsis);
                        
                        // Fill remaining space and add right cell padding
                        const written_display_width = display_count + Constants.ELLIPSIS_WIDTH; // text + ellipsis
                        for (written_display_width..truncate_width) |_| {
                            try writer.writeByte(' ');
                        }
                        for (0..cell_padding) |_| {
                            try writer.writeByte(' ');
                        }
                    } else {
                        // Just write ellipsis if we can
                        try writer.writeAll(Constants.ELLIPSIS);
                        for (Constants.ELLIPSIS_WIDTH..available_width) |_| {
                            try writer.writeByte(' ');
                        }
                    }
                } else {
                    // Width too small, just fill with spaces
                    for (0..width) |_| {
                        try writer.writeByte(' ');
                    }
                }
            } else {
                // Subsequent lines: just spaces
                for (0..width) |_| {
                    try writer.writeByte(' ');
                }
            }
            content_pos += width;
        }
        
        // Fill remaining space
        if (content_pos < content_width) {
            for (content_pos..content_width) |_| {
                try writer.writeByte(' ');
            }
        }
        
        // Write right border
        try writer.writeAll(right_part);
        try writer.writeByte('\n');
    }
}

/// Render a single cell with alignment and padding
fn renderCell(writer: anytype, text: []const u8, width: usize, alignment: layout.Alignment) !void {
    // The width already includes cell padding from layout calculation
    if (width == 0) return;
    
    // Calculate padding for alignment
    const padding = alignment.getPadding(text.len, width);
    
    // Left padding
    for (0..padding.left) |_| {
        try writer.writeByte(' ');
    }
    
    // Text (truncated if necessary)
    const text_to_write = if (text.len > width - padding.left) 
        text[0..width - padding.left] 
    else 
        text;
    try writer.writeAll(text_to_write);
    
    // Right padding
    const written = padding.left + text_to_write.len;
    if (written < width) {
        for (written..width) |_| {
            try writer.writeByte(' ');
        }
    }
}

/// Render a repeating pattern to fill a specified width (in display columns)
fn renderPattern(writer: anytype, pattern: []const u8, width: usize) !void {
    if (pattern.len == 0 or width == 0) return;
    
    // Calculate the display width of the pattern
    const pattern_display_width = utils.displayWidth(pattern);
    if (pattern_display_width == 0) return;
    
    // Calculate how many full patterns we need and how many extra columns
    const full_repeats = width / pattern_display_width;
    const remaining_cols = width % pattern_display_width;
    
    // Write full pattern repeats
    for (0..full_repeats) |_| {
        try writer.writeAll(pattern);
    }
    
    // Handle partial pattern at the end if needed
    if (remaining_cols > 0) {
        // We need to write part of the pattern to fill the remaining columns
        // Find how many bytes of the pattern to write
        var bytes_to_write: usize = 0;
        var cols_written: usize = 0;
        
        while (bytes_to_write < pattern.len and cols_written < remaining_cols) {
            const char_bytes = utils.utf8ByteSequenceLength(pattern[bytes_to_write]);
            const char_display_width = utils.displayWidth(pattern[bytes_to_write..@min(bytes_to_write + char_bytes, pattern.len)]);
            
            if (cols_written + char_display_width <= remaining_cols) {
                bytes_to_write += char_bytes;
                cols_written += char_display_width;
            } else {
                break;
            }
        }
        
        try writer.writeAll(pattern[0..bytes_to_write]);
        
        // If we couldn't fill all remaining columns (e.g., need 1 column but next char is 2 columns wide),
        // pad with spaces
        for (cols_written..remaining_cols) |_| {
            try writer.writeByte(' ');
        }
    }
}

/// Render a divider between data rows
fn renderRowDivider(writer: anytype, ctx: RenderContext) !void {
    const box_theme = ctx.theme;
    const column_widths = ctx.layout_info.column_widths;
    
    // Get the divider characters (should never be null if we're here, but be safe)
    const divider = box_theme.inner.row_divider orelse return;
    const cross = box_theme.inner.row_cross orelse divider;
    const left_junction = box_theme.inner.row_left orelse divider;
    const right_junction = box_theme.inner.row_right orelse divider;
    
    // Calculate border widths (junctions replace borders, they're the same width)
    const left_border = box_theme.getLeft();
    const left_first_line = if (std.mem.indexOfScalar(u8, left_border, '\n')) |idx|
        left_border[0..idx]
    else
        left_border;
    const left_width = utils.displayWidth(left_first_line);
    
    const right_border = box_theme.getRight();
    const right_first_line = if (std.mem.indexOfScalar(u8, right_border, '\n')) |idx|
        right_border[0..idx]
    else
        right_border;
    const right_width = utils.displayWidth(right_first_line);
    
    // Write left junction (replaces left border)
    try writer.writeAll(left_junction);
    
    // Calculate content area (same as regular rows)
    const content_width = ctx.total_width - left_width - right_width;
    
    // Draw divider with column junctions
    var position: usize = 0;
    for (column_widths, 0..) |col_width, i| {
        // Draw horizontal divider for this column width
        try renderPattern(writer, divider, col_width);
        position += col_width;
        
        // Add column junction if not last column
        if (i < column_widths.len - 1) {
            try writer.writeAll(cross);
            const cross_width = utils.displayWidth(cross);
            position += cross_width;
        }
    }
    
    // Fill any remaining space
    if (position < content_width) {
        try renderPattern(writer, divider, content_width - position);
    }
    
    // Write right junction (replaces right border)
    try writer.writeAll(right_junction);
    try writer.writeByte('\n');
}

/// Calculate the width used by a row with column separators
fn calculateRowWidth(num_columns: usize, column_widths: []usize) usize {
    var total: usize = 0;
    
    // Sum column widths
    for (column_widths[0..@min(num_columns, column_widths.len)]) |width| {
        total += width;
    }
    
    // Add separator widths (one less than columns)
    if (num_columns > 1) {
        total += num_columns - 1;
    }
    
    return total;
}

/// Render multi-line borders (for 3D effects)
pub fn renderMultiLineBorder(writer: anytype, border: []const u8, width: usize) !void {
    var lines = std.mem.tokenize(u8, border, "\n");
    while (lines.next()) |line| {
        try renderPattern(writer, line, width);
        try writer.writeByte('\n');
    }
}