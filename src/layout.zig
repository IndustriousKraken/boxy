/// Layout engine for Boxy
///
/// This module handles all layout calculations including sizing, positioning,
/// alignment, and data organization. It transforms user input into concrete
/// dimensions and positions for rendering.

const std = @import("std");
const utils = @import("utils.zig");

/// Get the display width of a theme's column separator (first line only)
fn getSeparatorWidth(theme_obj: anytype) usize {
    const separator = theme_obj.inner.v;
    const separator_first_line = if (std.mem.indexOfScalar(u8, separator, '\n')) |idx|
        separator[0..idx]
    else
        separator;
    return utils.displayWidth(separator_first_line);
}

/// Configuration constants
pub const Constants = struct {
    /// Default width for columns when no content is available
    pub const DEFAULT_COLUMN_WIDTH = 10;
    
    /// Minimum width for displaying truncated text with ellipsis
    pub const MIN_TRUNCATE_WIDTH = 3;
    
    /// Default cell padding on each side
    pub const DEFAULT_CELL_PADDING = 1;
    
    /// Extra rows allocated for headers and padding  
    pub const EXTRA_ROW_BUFFER = 5;
};

/// Orientation for data layout
pub const Orientation = enum {
    columns,    // Data sets are columns (default)
    rows,       // Data sets are rows
    
    /// Check if data should be transposed for rendering
    pub fn shouldTranspose(self: Orientation) bool {
        return self == .rows;
    }
};

/// Strategy for distributing extra space when width is constrained
pub const ExtraSpaceStrategy = enum {
    first,       // Add extra space to first columns (good for spreadsheets with row headers)
    last,        // Add extra space to last columns (good for uniform grids)
    distributed, // Distribute extra space evenly across all columns
    center,      // Add extra space to center columns
};

/// Text alignment within cells
pub const Alignment = enum {
    left,
    center,
    right,
    
    /// Calculate padding for aligned text
    pub fn getPadding(self: Alignment, text_len: usize, cell_width: usize) struct { left: usize, right: usize } {
        if (text_len >= cell_width) {
            return .{ .left = 0, .right = 0 };
        }
        
        const total_padding = cell_width - text_len;
        
        return switch (self) {
            .left => .{ .left = 0, .right = total_padding },
            .right => .{ .left = total_padding, .right = 0 },
            .center => .{ 
                .left = total_padding / 2, 
                .right = total_padding - (total_padding / 2) 
            },
        };
    }
};

/// Size specification for width or height
pub const Size = union(enum) {
    auto: void,           // Size to content
    exact: usize,         // Exact size in characters
    min: usize,           // Minimum size
    max: usize,           // Maximum size
    range: struct {       // Min and max
        min: usize,
        max: usize,
    },
    
    /// Apply constraints to a calculated size
    pub fn constrain(self: Size, calculated: usize) usize {
        return switch (self) {
            .auto => calculated,
            .exact => |val| val,
            .min => |val| @max(val, calculated),
            .max => |val| @min(val, calculated),
            .range => |r| @max(r.min, @min(r.max, calculated)),
        };
    }
};

/// Complete layout information for a box
pub const LayoutInfo = struct {
    total_width: usize,          // Total width including borders
    total_height: usize,         // Total height including borders
    content_width: usize,        // Width of content area
    content_height: usize,       // Height of content area
    column_widths: []usize,      // Width of each column
    row_heights: []usize,        // Height of each row
    padding: Padding,            // Padding around content
    cell_padding: usize,         // Padding inside each cell
    sections: []SectionLayout,   // Layout for each section
};

/// Padding specification
pub const Padding = struct {
    top: usize = 1,
    bottom: usize = 1,
    left: usize = 1,
    right: usize = 1,
    
    /// Get total horizontal padding
    pub fn horizontal(self: Padding) usize {
        return self.left + self.right;
    }
    
    /// Get total vertical padding
    pub fn vertical(self: Padding) usize {
        return self.top + self.bottom;
    }
};

/// Layout information for a single section
pub const SectionLayout = struct {
    section_type: SectionType,
    start_row: usize,         // Starting row within content area
    start_col: usize,         // Starting column within content area
    width: usize,             // Width of this section
    height: usize,            // Height of this section
    column_widths: []usize,   // Column widths for this section
    row_heights: []usize,     // Row heights for this section
};

/// Types of sections (matching box.zig)
pub const SectionType = enum {
    title,
    headers,
    data,
    canvas,
    divider,
};

/// Calculate natural column widths based on content
fn calculateNaturalColumnWidths(allocator: std.mem.Allocator, sections: anytype, cell_padding: usize) ![]usize {
    // Find the maximum number of columns from all sections
    var max_columns: usize = 0;
    
    for (sections.items) |section| {
        if (section.section_type == .headers) {
            max_columns = @max(max_columns, section.headers.len);
        } else if (section.section_type == .data) {
            max_columns = @max(max_columns, section.headers.len);
        }
    }
    
    // If no columns found, use default
    if (max_columns == 0) max_columns = 1;
    
    // Calculate column widths based on actual data
    const column_widths = try allocator.alloc(usize, max_columns);
    @memset(column_widths, 0);
    
    // Find maximum width for each column
    for (sections.items) |section| {
        // Check headers
        if (section.section_type == .headers) {
            for (section.headers, 0..) |header, i| {
                if (i < column_widths.len) {
                    const display_w = utils.displayWidth(header);
                    column_widths[i] = @max(column_widths[i], display_w);
                }
            }
        }
        // Check data
        if (section.section_type == .data and section.headers.len > 0) {
            const cols = section.headers.len;
            for (section.data, 0..) |item, idx| {
                const col = idx % cols;
                if (col < column_widths.len) {
                    const display_w = utils.displayWidth(item);
                    column_widths[col] = @max(column_widths[col], display_w);
                }
            }
        }
    }
    
    // Add padding to each column and ensure minimum width
    for (column_widths) |*width| {
        if (width.* == 0) width.* = Constants.DEFAULT_COLUMN_WIDTH;
        width.* += cell_padding * 2;  // Add padding on both sides
    }
    
    return column_widths;
}

/// Apply width constraints and distribute extra space among columns
fn applyWidthConstraints(column_widths: []usize, total_width: usize, natural_width: usize, final_content_width: usize, theme_obj: anytype, config: anytype) void {
    // If width was constrained and we have columns, redistribute column widths
    if (total_width != natural_width and column_widths.len > 0) {
        // Calculate available space for columns after accounting for separators
        // single_separator_width already calculated above
        const single_separator_width = getSeparatorWidth(theme_obj);
        const separator_total_width = if (column_widths.len > 1) 
            (column_widths.len - 1) * single_separator_width 
        else 
            0;
        // Tables don't use padding, so don't subtract it
        const available_for_columns = if (final_content_width > separator_total_width)
            final_content_width - separator_total_width
        else
            column_widths.len; // Minimum 1 char per column
        
        // Distribute evenly among columns
        const width_per_column = available_for_columns / column_widths.len;
        const extra_width = available_for_columns % column_widths.len;
        
        // Determine effective strategy (auto-detect if not specified)
        const strategy = if (@hasField(@TypeOf(config), "extra_space_strategy") and config.extra_space_strategy != null)
            config.extra_space_strategy.?
        else if (@hasField(@TypeOf(config), "spreadsheet_mode") and config.spreadsheet_mode)
            ExtraSpaceStrategy.first  // Spreadsheet: extra to first column (row headers)
        else
            ExtraSpaceStrategy.last;  // Regular table: extra to last columns
        
        // Debug: Print the strategy being used
        // std.debug.print("Strategy: {}, spreadsheet_mode: {}, extra_width: {}\n", .{strategy, config.spreadsheet_mode, extra_width});
        
        for (column_widths, 0..) |*width, i| {
            width.* = width_per_column;
            
            // Add extra width based on strategy
            switch (strategy) {
                .first => {
                    // Add extra width to first columns
                    if (i < extra_width) {
                        width.* += 1;
                    }
                },
                .last => {
                    // Add extra width to last columns
                    const last_start = column_widths.len - extra_width;
                    if (i >= last_start) {
                        width.* += 1;
                    }
                },
                .distributed => {
                    // Already handled by width_per_column; 
                    // for true distribution we'd spread more evenly
                    if (i < extra_width) {
                        width.* += 1;
                    }
                },
                .center => {
                    // Add extra width to center columns
                    const center_start = (column_widths.len - extra_width) / 2;
                    const center_end = center_start + extra_width;
                    if (i >= center_start and i < center_end) {
                        width.* += 1;
                    }
                },
            }
        }
    }
}

/// Calculate complete layout for a box
pub fn calculate(allocator: std.mem.Allocator, config: anytype, sections: anytype) !LayoutInfo {
    const cell_padding = if (@hasField(@TypeOf(config), "cell_padding")) config.cell_padding else Constants.DEFAULT_CELL_PADDING;
    
    // Calculate natural column widths from content
    const column_widths = try calculateNaturalColumnWidths(allocator, sections, cell_padding);
    
    // Count maximum rows for height allocation
    var max_rows: usize = 0;
    for (sections.items) |section| {
        if (section.section_type == .data and section.headers.len > 0 and section.data.len > 0) {
            const rows_in_section = section.data.len / section.headers.len;
            max_rows = @max(max_rows, rows_in_section);
        }
    }
    if (max_rows == 0) max_rows = 1;
    
    const row_heights = try allocator.alloc(usize, max_rows + Constants.EXTRA_ROW_BUFFER); // Extra for headers/padding
    @memset(row_heights, 1);
    
    const section_layouts = try allocator.alloc(SectionLayout, sections.items.len);
    for (section_layouts, 0..) |*layout, i| {
        layout.* = .{
            .section_type = .data,
            .start_row = i * 2,
            .start_col = 0,
            .width = 0,  // Calculated from column_widths
            .height = 0, // Calculated from row_heights
            .column_widths = column_widths,
            .row_heights = row_heights,
        };
    }
    
    // Calculate actual total width based on columns
    var content_width: usize = 0;
    for (column_widths) |width| {
        content_width += width;
    }
    
    // Get actual separator width from theme (could be multi-character like "::")
    const theme = config.theme;
    const single_separator_width = getSeparatorWidth(theme);
    
    // Add separators between columns
    if (column_widths.len > 1) {
        content_width += (column_widths.len - 1) * single_separator_width;
    }
    
    // Note: Box padding is handled separately in title sections
    // Tables don't add extra padding - columns should fill edge to edge
    const padding = Padding{};
    
    // Calculate actual border widths from theme
    // Get the first line of borders (for multi-line borders)
    const left_border = theme.getLeft();
    const right_border = theme.getRight();
    
    // Get just the first line of each border for width calculation
    const left_first_line = if (std.mem.indexOfScalar(u8, left_border, '\n')) |idx|
        left_border[0..idx]
    else
        left_border;
    
    const right_first_line = if (std.mem.indexOfScalar(u8, right_border, '\n')) |idx|
        right_border[0..idx]
    else
        right_border;
    
    const left_border_width = utils.displayWidth(left_first_line);
    const right_border_width = utils.displayWidth(right_first_line);
    
    // Calculate natural width
    const natural_width = content_width + left_border_width + right_border_width;
    
    // Apply width constraint from config
    const width_constraint = if (@hasField(@TypeOf(config), "width")) config.width else Size{ .auto = {} };
    const total_width = width_constraint.constrain(natural_width);
    
    // Recalculate content width and column widths if total width was constrained
    const final_content_width = if (total_width != natural_width)
        total_width - left_border_width - right_border_width
    else
        content_width;
    
    // Apply width constraints if needed
    applyWidthConstraints(column_widths, total_width, natural_width, final_content_width, theme, config);
    
    // Calculate actual height from sections
    var total_lines: usize = 0;
    for (sections.items) |section| {
        switch (section.section_type) {
            .title => total_lines += section.data.len + 2, // Title lines + padding
            .headers => total_lines += 1,
            .data => {
                if (section.headers.len > 0 and section.data.len > 0) {
                    total_lines += section.data.len / section.headers.len;
                }
            },
            .divider => total_lines += 1,
            .canvas => {}, // Canvas height handled separately
        }
    }
    
    // Add borders and dividers
    const total_height = total_lines + 4; // Top border + bottom border + header divider + padding
    const content_height = total_lines;
    
    return .{
        .total_width = total_width,
        .total_height = total_height,
        .content_width = final_content_width,
        .content_height = content_height,
        .column_widths = column_widths,
        .row_heights = row_heights,
        .padding = padding,
        .cell_padding = cell_padding,
        .sections = section_layouts,
    };
}

/// Calculate column widths based on content
pub fn calculateColumnWidths(allocator: std.mem.Allocator, data: []const []const []const u8, constraints: ?[]const Size) ![]usize {
    const num_columns = if (data.len > 0) data[0].len else 0;
    var widths = try allocator.alloc(usize, num_columns);
    
    // Find maximum width for each column
    for (0..num_columns) |col| {
        var max_width: usize = 0;
        for (data) |row| {
            if (col < row.len) {
                max_width = @max(max_width, row[col].len);
            }
        }
        
        // Apply constraints if provided
        if (constraints) |c| {
            if (col < c.len) {
                max_width = c[col].constrain(max_width);
            }
        }
        
        widths[col] = max_width;
    }
    
    return widths;
}

/// Calculate row heights based on content
pub fn calculateRowHeights(allocator: std.mem.Allocator, data: []const []const []const u8, wrap: bool) ![]usize {
    var heights = try allocator.alloc(usize, data.len);
    
    for (data, 0..) |_, i| {
        if (wrap) {
            // Calculate wrapped height for each cell in the row
            // Implementation placeholder
            heights[i] = 1;
        } else {
            // Single line per row
            heights[i] = 1;
        }
    }
    
    return heights;
}

/// Transpose data from columns to rows or vice versa
pub fn transposeData(allocator: std.mem.Allocator, data: []const []const []const u8, orientation: Orientation) ![]const []const []const u8 {
    _ = allocator;
    if (orientation == .columns) {
        return data; // Already in column format
    }
    
    // Transpose from rows to columns
    // Implementation placeholder
    return data;
}

/// Calculate text wrapping for a cell
pub fn wrapText(allocator: std.mem.Allocator, text: []const u8, width: usize) ![][]const u8 {
    _ = width;
    var lines = std.ArrayList([]const u8).init(allocator);
    defer lines.deinit();
    
    // Simple word wrapping implementation
    // Implementation placeholder
    try lines.append(text);
    
    return try lines.toOwnedSlice();
}

/// Truncate text to fit within a specified width
pub fn truncateText(text: []const u8, max_width: usize, indicator: []const u8) []const u8 {
    if (text.len <= max_width) {
        return text;
    }
    
    if (max_width <= indicator.len) {
        return indicator[0..max_width];
    }
    
    const keep_len = max_width - indicator.len;
    return text[0..keep_len]; // Should concatenate with indicator, but returning truncated for now
}

/// Apply alignment to text within a cell
pub fn alignText(allocator: std.mem.Allocator, text: []const u8, width: usize, alignment: Alignment) ![]u8 {
    if (text.len >= width) {
        return try allocator.dupe(u8, text[0..width]);
    }
    
    const padding = alignment.getPadding(text.len, width);
    var result = try allocator.alloc(u8, width);
    
    // Fill with spaces
    @memset(result, ' ');
    
    // Copy text at appropriate position
    @memcpy(result[padding.left..padding.left + text.len], text);
    
    return result;
}