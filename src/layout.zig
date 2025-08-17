/// Layout engine for Boxy
///
/// This module handles all layout calculations including sizing, positioning,
/// alignment, and data organization. It transforms user input into concrete
/// dimensions and positions for rendering.

const std = @import("std");
const utils = @import("utils.zig");
const constants = @import("constants.zig");
const render = @import("render.zig");


/// Re-export layout constants for backward compatibility
pub const Constants = constants.Layout;

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

/// Calculate raw column widths based on content (without padding)
fn calculateRawColumnWidths(allocator: std.mem.Allocator, sections: anytype) ![]usize {
    // Find the maximum number of columns from all sections
    var max_columns: usize = 0;
    var has_canvas = false;
    var canvas_width: usize = 0;
    
    for (sections.items) |section| {
        if (section.section_type == .headers) {
            max_columns = @max(max_columns, section.headers.len);
        } else if (section.section_type == .data) {
            max_columns = @max(max_columns, section.headers.len);
        } else if (section.section_type == .canvas) {
            has_canvas = true;
            canvas_width = section.canvas_width;
        }
    }
    
    // If we have a canvas section, return a single column with canvas width
    if (has_canvas) {
        const column_widths = try allocator.alloc(usize, 1);
        column_widths[0] = canvas_width;
        return column_widths;
    }
    
    // If no columns found, use default
    if (max_columns == 0) max_columns = 1;
    
    // Calculate column widths based on actual data
    const column_widths = try allocator.alloc(usize, max_columns);
    @memset(column_widths, 0);
    
    // Find maximum width for each column (raw content width, no padding)
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
    
    // Ensure minimum width for empty columns
    for (column_widths) |*width| {
        if (width.* == 0) width.* = Constants.DEFAULT_COLUMN_WIDTH;
    }
    
    return column_widths;
}

/// Apply user-specified width constraints (only called when user sets explicit width)
fn applyUserWidthConstraint(column_widths: []usize, final_content_width: usize, separator_width: usize, config: anytype) void {
    if (column_widths.len == 0) return;
    
    // Calculate available space for columns after accounting for separators
    const separator_total_width = if (column_widths.len > 1) 
        (column_widths.len - 1) * separator_width 
    else 
        0;
    
    const available_for_columns = if (final_content_width > separator_total_width)
        final_content_width - separator_total_width
    else
        column_widths.len; // Minimum 1 char per column
    
    // Distribute evenly among columns (for user constraints, we reset to equal widths)
    const width_per_column = available_for_columns / column_widths.len;
    const extra_width = available_for_columns % column_widths.len;
    
    // Determine effective strategy (auto-detect if not specified)
    const strategy = if (@hasField(@TypeOf(config), "extra_space_strategy") and config.extra_space_strategy != null)
        config.extra_space_strategy.?
    else if (@hasField(@TypeOf(config), "spreadsheet_mode") and config.spreadsheet_mode)
        ExtraSpaceStrategy.first  // Spreadsheet: extra to first column (row headers)
    else
        ExtraSpaceStrategy.last;  // Regular table: extra to last columns
    
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
                // Distribute extra width evenly across all columns
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

/// Calculate complete layout for a box
pub fn calculate(allocator: std.mem.Allocator, config: anytype, sections: anytype) !LayoutInfo {
    const cell_padding = if (@hasField(@TypeOf(config), "cell_padding")) config.cell_padding else Constants.DEFAULT_CELL_PADDING;
    
    // Step 1: Calculate raw column widths from content (no padding)
    const column_widths = try calculateRawColumnWidths(allocator, sections);
    
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
    
    // Step 2: Calculate the natural content width needed
    // This includes: raw column widths + padding + separators
    const theme = config.theme;
    const separator_width = render.getSeparatorWidth(theme);
    
    // Calculate sum of raw column widths
    var raw_columns_total: usize = 0;
    for (column_widths) |width| {
        raw_columns_total += width;
    }
    
    // Add space for padding (each column gets padding on both sides)
    const padding_total = column_widths.len * cell_padding * 2;
    
    // Add space for separators between columns
    const separators_total = if (column_widths.len > 1)
        (column_widths.len - 1) * separator_width
    else
        0;
    
    // Natural content width from columns
    const natural_content_width = raw_columns_total + padding_total + separators_total;
    
    // Step 3: Check title width requirement
    var title_required_width: usize = 0;
    for (sections.items) |section| {
        if (section.section_type == .title) {
            for (section.data) |title_line| {
                const title_width = utils.displayWidth(title_line);
                title_required_width = @max(title_required_width, title_width + 4); // Add padding around title
            }
        }
    }
    
    // Step 4: Determine final content width (max of natural and title requirements)
    var content_width = @max(natural_content_width, title_required_width);
    
    // Note: Box padding is handled separately in title sections
    // Tables don't add extra padding - columns should fill edge to edge
    const padding = Padding{};
    
    // Calculate actual border widths from theme
    // Get the first line of borders (for multi-line borders)
    const left_border = theme.getLeft();
    const right_border = theme.getRight();
    
    // Get just the first line of each border for width calculation
    const left_border_width = utils.displayWidth(utils.firstLine(left_border));
    const right_border_width = utils.displayWidth(utils.firstLine(right_border));
    
    // Calculate natural width
    const natural_width = content_width + left_border_width + right_border_width;
    
    // Step 5: If content needs to expand (for title), distribute extra space proportionally
    if (content_width > natural_content_width and column_widths.len > 0) {
        const extra_space = content_width - natural_content_width;
        
        // Calculate how much extra space each column gets (proportional to its size)
        var total_weight: f32 = 0;
        for (column_widths) |width| {
            total_weight += @as(f32, @floatFromInt(width));
        }
        
        if (total_weight > 0) {
            var distributed: usize = 0;
            for (column_widths, 0..) |*width, i| {
                const proportion = @as(f32, @floatFromInt(width.*)) / total_weight;
                const extra_for_this = if (i == column_widths.len - 1)
                    extra_space - distributed  // Last column gets any remainder
                else
                    @as(usize, @intFromFloat(proportion * @as(f32, @floatFromInt(extra_space))));
                
                width.* += extra_for_this;
                distributed += extra_for_this;
            }
        }
    }
    
    // Step 6: Add padding to each column width
    for (column_widths) |*width| {
        width.* += cell_padding * 2;
    }
    
    // Step 7: Apply user width constraint if specified
    const width_constraint = if (@hasField(@TypeOf(config), "width")) config.width else Size{ .auto = {} };
    const total_width = width_constraint.constrain(natural_width);
    
    // Only apply width redistribution if user specified a constraint that changes the width
    if (width_constraint != .auto and total_width != natural_width) {
        content_width = total_width - left_border_width - right_border_width;
        applyUserWidthConstraint(column_widths, content_width, separator_width, config);
    }
    
    // Calculate actual height from sections
    var content_lines: usize = 0;
    for (sections.items) |section| {
        switch (section.section_type) {
            .title => content_lines += section.data.len + 2, // Title lines + padding
            .headers => content_lines += 1,
            .data => {
                if (section.headers.len > 0 and section.data.len > 0) {
                    content_lines += section.data.len / section.headers.len;
                }
            },
            .divider => content_lines += 1,
            .canvas => content_lines += section.canvas_height,
        }
    }
    
    // Calculate natural height including borders
    // Top border (1) + content + bottom border (1) + potential header divider (1) + padding
    const border_height = 2; // Top and bottom borders
    const natural_height = content_lines + border_height + 2; // +2 for potential dividers/padding
    
    // Apply height constraint from config
    const height_constraint = if (@hasField(@TypeOf(config), "height")) config.height else Size{ .auto = {} };
    const total_height = height_constraint.constrain(natural_height);
    
    // Calculate content height based on whether we have a constraint
    const content_height = if (height_constraint == .auto)
        content_lines  // Use natural content height when unconstrained
    else if (total_height > border_height)
        total_height - border_height  // Only subtract borders when constrained
    else
        1;  // Minimum content height
    
    return .{
        .total_width = total_width,
        .total_height = total_height,
        .content_width = content_width,
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