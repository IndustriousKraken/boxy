/// Table rendering functionality for Boxy
///
/// This module handles rendering of table rows with columns,
/// separators, and proper spacing.

const std = @import("std");
const theme = @import("../theme.zig");
const layout = @import("../layout.zig");
const utils = @import("../utils.zig");
const content = @import("content.zig");
const borders = @import("borders.zig");

/// Import RenderContext from sections to avoid circular dependency
const sections = @import("sections.zig");
pub const RenderContext = sections.RenderContext;

/// Options specific to table rendering
pub const TableRenderOptions = struct {
    cells: []const []const u8,
    column_widths: []usize,
    alignment: layout.Alignment,
    cell_padding: usize,
};

/// Get the display width of a theme's column separator (first line only)
pub fn getSeparatorWidth(box_theme: theme.BoxyTheme) usize {
    const separator = box_theme.vertical.column;
    const separator_first_line = if (std.mem.indexOfScalar(u8, separator, '\n')) |idx|
        separator[0..idx]
    else
        separator;
    return utils.displayWidth(separator_first_line);
}

/// Render a complete table row with column separators
pub fn renderTableRow(writer: anytype, ctx: RenderContext, options: TableRenderOptions) !void {
    const cells = options.cells;
    const column_widths = options.column_widths;
    const alignment = options.alignment;
    const cell_padding = options.cell_padding;
    
    if (cells.len == 0 or column_widths.len == 0) return;
    
    const left_border = ctx.theme.getLeft();
    const right_border = ctx.theme.getRight();
    const separator = ctx.theme.vertical.column;
    
    // Get first lines for multi-line borders
    const left_first_line = if (std.mem.indexOfScalar(u8, left_border, '\n')) |idx|
        left_border[0..idx]
    else
        left_border;
    
    const right_first_line = if (std.mem.indexOfScalar(u8, right_border, '\n')) |idx|
        right_border[0..idx]
    else
        right_border;
    
    const separator_first_line = if (std.mem.indexOfScalar(u8, separator, '\n')) |idx|
        separator[0..idx]
    else
        separator;
    
    // Calculate display widths
    _ = utils.displayWidth(left_first_line);
    _ = utils.displayWidth(right_first_line);
    _ = utils.displayWidth(separator_first_line);
    
    // Determine how many lines we need to render (for multi-line borders)
    var max_lines: usize = 1;
    
    // Count lines in borders
    var left_line_count: usize = 0;
    var right_line_count: usize = 0;
    var sep_line_count: usize = 0;
    
    var left_lines = std.mem.splitScalar(u8, left_border, '\n');
    var right_lines = std.mem.splitScalar(u8, right_border, '\n');
    var sep_lines = std.mem.splitScalar(u8, separator, '\n');
    
    while (left_lines.next()) |_| left_line_count += 1;
    while (right_lines.next()) |_| right_line_count += 1;
    while (sep_lines.next()) |_| sep_line_count += 1;
    
    max_lines = @max(@max(left_line_count, right_line_count), sep_line_count);
    if (max_lines == 0) max_lines = 1;
    
    // Reset iterators
    left_lines = std.mem.splitScalar(u8, left_border, '\n');
    right_lines = std.mem.splitScalar(u8, right_border, '\n');
    sep_lines = std.mem.splitScalar(u8, separator, '\n');
    
    // Render each line
    for (0..max_lines) |line_idx| {
        const left_part = left_lines.next() orelse "";
        const right_part = right_lines.next() orelse "";
        const sep_part = sep_lines.next() orelse "";
        
        // Write left border
        try writer.writeAll(left_part);
        
        // Render columns (only on first line for content)
        const num_columns = @min(cells.len, column_widths.len);
        for (0..num_columns) |col_idx| {
            const col_width = column_widths[col_idx];
            
            if (line_idx == 0) {
                // First line: render actual content with padding
                const effective_width = if (col_width >= cell_padding * 2)
                    col_width - (cell_padding * 2)
                else
                    0;
                
                // Add left padding
                for (0..cell_padding) |_| {
                    if (col_width > 0) try writer.writeByte(' ');
                }
                
                // Render cell content
                if (effective_width > 0) {
                    try content.renderCell(writer, cells[col_idx], effective_width, alignment);
                }
                
                // Add right padding
                for (0..cell_padding) |_| {
                    if (col_width > cell_padding) try writer.writeByte(' ');
                }
            } else {
                // Subsequent lines: just spaces
                for (0..col_width) |_| {
                    try writer.writeByte(' ');
                }
            }
            
            // Add column separator (not after last column)
            if (col_idx < num_columns - 1) {
                try writer.writeAll(sep_part);
            }
        }
        
        // Write right border
        try writer.writeAll(right_part);
        try writer.writeByte('\n');
    }
}

/// Render a row divider (uses borders module)
pub fn renderRowDivider(writer: anytype, ctx: RenderContext) !void {
    try borders.renderRowDivider(writer, ctx.theme, ctx.total_width, ctx.layout_info.column_widths);
}

/// Calculate the total width needed for a row with the given number of columns
pub fn calculateRowWidth(num_columns: usize, column_widths: []usize) usize {
    if (num_columns == 0 or column_widths.len == 0) return 0;
    
    var total_width: usize = 0;
    
    // Add column widths
    const actual_columns = @min(num_columns, column_widths.len);
    for (0..actual_columns) |i| {
        total_width += column_widths[i];
    }
    
    // Add separator widths (n-1 separators for n columns)
    if (actual_columns > 1) {
        // Note: This is a simplified calculation
        // In practice, separator width comes from the theme
        total_width += (actual_columns - 1); // Assume 1-char separators
    }
    
    return total_width;
}