/// Theme definitions for Boxy boxes - Systematic structure
///
/// This module contains the BoxyTheme structure using a systematic approach
/// where every line type and junction is explicitly and unambiguously named.
///
/// Naming convention:
/// - Lines are categorized as vertical or horizontal
/// - Junctions are named as {line1}_{line2}_{shape}
///   Example: outer_section_t_left = outer vertical meets section horizontal, T points left

const std = @import("std");

/// Complete theme definition for a box
pub const BoxyTheme = struct {
    // All vertical lines
    vertical: VerticalLines = .{},
    
    // All horizontal lines  
    horizontal: HorizontalLines = .{},
    
    // All intersections/junctions
    junction: Junctions = .{},
    
    /// Get the effective top border
    pub fn getTop(self: BoxyTheme) []const u8 {
        return self.horizontal.getTop();
    }
    
    /// Get the effective bottom border
    pub fn getBottom(self: BoxyTheme) []const u8 {
        return self.horizontal.getBottom();
    }
    
    /// Get the effective left border
    pub fn getLeft(self: BoxyTheme) []const u8 {
        return self.vertical.getLeft();
    }
    
    /// Get the effective right border
    pub fn getRight(self: BoxyTheme) []const u8 {
        return self.vertical.getRight();
    }
    
    /// Get the effective top-left corner
    pub fn getTopLeft(self: BoxyTheme) []const u8 {
        return self.junction.outer_top_left orelse 
               self.junction.outer_corner orelse "┌";
    }
    
    /// Get the effective top-right corner
    pub fn getTopRight(self: BoxyTheme) []const u8 {
        return self.junction.outer_top_right orelse 
               self.junction.outer_corner orelse "┐";
    }
    
    /// Get the effective bottom-left corner
    pub fn getBottomLeft(self: BoxyTheme) []const u8 {
        return self.junction.outer_bottom_left orelse 
               self.junction.outer_corner orelse "└";
    }
    
    /// Get the effective bottom-right corner
    pub fn getBottomRight(self: BoxyTheme) []const u8 {
        return self.junction.outer_bottom_right orelse 
               self.junction.outer_corner orelse "┘";
    }
    
    /// Check if this theme uses multi-line borders
    pub fn isMultiLine(self: BoxyTheme) bool {
        // Check if any border contains newlines
        if (std.mem.indexOf(u8, self.vertical.outer, "\n") != null) return true;
        if (std.mem.indexOf(u8, self.horizontal.outer, "\n") != null) return true;
        return false;
    }
};

/// All vertical line types
pub const VerticalLines = struct {
    outer: ?[]const u8 = null,          // Both left and right (simple mode)
    outer_left: ?[]const u8 = null,     // Left border specifically
    outer_right: ?[]const u8 = null,    // Right border specifically
    column: []const u8 = "│",           // Column dividers between data
    
    /// Get effective left border
    pub fn getLeft(self: VerticalLines) []const u8 {
        return self.outer_left orelse self.outer orelse "│";
    }
    
    /// Get effective right border
    pub fn getRight(self: VerticalLines) []const u8 {
        return self.outer_right orelse self.outer orelse "│";
    }
};

/// All horizontal line types  
pub const HorizontalLines = struct {
    outer: ?[]const u8 = null,          // Both top and bottom (simple mode)
    outer_top: ?[]const u8 = null,      // Top border specifically
    outer_bottom: ?[]const u8 = null,   // Bottom border specifically
    section: ?[]const u8 = null,        // After title (defaults to outer if null)
    header: ?[]const u8 = null,         // Between headers and data (defaults to section if null)
    row: ?[]const u8 = null,            // Between data rows (null = no row dividers)
    
    /// Get effective top border
    pub fn getTop(self: HorizontalLines) []const u8 {
        return self.outer_top orelse self.outer orelse "─";
    }
    
    /// Get effective bottom border
    pub fn getBottom(self: HorizontalLines) []const u8 {
        return self.outer_bottom orelse self.outer orelse "─";
    }
    
    /// Get effective section divider (with fallback)
    pub fn getSection(self: HorizontalLines) []const u8 {
        return self.section orelse self.outer orelse "─";
    }
    
    /// Get effective header divider (with fallback chain)
    pub fn getHeader(self: HorizontalLines) []const u8 {
        return self.header orelse self.section orelse self.outer orelse "─";
    }
};

/// All junction types (where lines meet)
pub const Junctions = struct {
    // Outer × Outer = Corners
    outer_corner: ?[]const u8 = null,              // All four corners (simple mode)
    outer_top_left: ?[]const u8 = null,            // ┌ ╔ ╭ o
    outer_top_right: ?[]const u8 = null,           // ┐ ╗ ╮ o
    outer_bottom_left: ?[]const u8 = null,         // └ ╚ ╰ o
    outer_bottom_right: ?[]const u8 = null,        // ┘ ╝ ╯ o
    
    // Outer vertical × Inner horizontal = T-junctions at left/right borders
    outer_section_t_left: ?[]const u8 = null,      // Right border meets section line
    outer_section_t_right: ?[]const u8 = null,     // Left border meets section line
    outer_header_t_left: ?[]const u8 = null,       // Right border meets header line
    outer_header_t_right: ?[]const u8 = null,      // Left border meets header line
    outer_row_t_left: ?[]const u8 = null,          // Right border meets row divider
    outer_row_t_right: ?[]const u8 = null,         // Left border meets row divider
    
    // Outer horizontal × Inner vertical = T-junctions at top/bottom borders
    outer_column_t_up: ?[]const u8 = null,         // Bottom border meets column
    outer_column_t_down: ?[]const u8 = null,       // Top border meets column
    
    // Inner × Inner = Crosses and T-junctions inside the box
    section_column_t_down: ?[]const u8 = null,     // Column starts at section line
    section_column_cross: ?[]const u8 = null,      // Column crosses section (if it continues)
    header_column_t_down: ?[]const u8 = null,      // Column starts at header line
    header_column_cross: ?[]const u8 = null,       // Column crosses header line
    row_column_cross: ?[]const u8 = null,          // Column crosses row divider
    
    // Smart defaults for T-junctions at borders
    pub fn getOuterSectionTLeft(self: Junctions) []const u8 {
        return self.outer_section_t_left orelse "┤";
    }
    
    pub fn getOuterSectionTRight(self: Junctions) []const u8 {
        return self.outer_section_t_right orelse "├";
    }
    
    pub fn getOuterHeaderTLeft(self: Junctions) []const u8 {
        return self.outer_header_t_left orelse 
               self.outer_section_t_left orelse "┤";
    }
    
    pub fn getOuterHeaderTRight(self: Junctions) []const u8 {
        return self.outer_header_t_right orelse 
               self.outer_section_t_right orelse "├";
    }
    
    pub fn getOuterRowTLeft(self: Junctions) []const u8 {
        return self.outer_row_t_left orelse 
               self.outer_header_t_left orelse 
               self.outer_section_t_left orelse "┤";
    }
    
    pub fn getOuterRowTRight(self: Junctions) []const u8 {
        return self.outer_row_t_right orelse 
               self.outer_header_t_right orelse 
               self.outer_section_t_right orelse "├";
    }
    
    pub fn getOuterColumnTUp(self: Junctions) []const u8 {
        return self.outer_column_t_up orelse "┴";
    }
    
    pub fn getOuterColumnTDown(self: Junctions) []const u8 {
        return self.outer_column_t_down orelse "┬";
    }
    
    pub fn getSectionColumnTDown(self: Junctions) []const u8 {
        return self.section_column_t_down orelse 
               self.outer_column_t_down orelse "┬";
    }
    
    pub fn getHeaderColumnCross(self: Junctions) []const u8 {
        return self.header_column_cross orelse "┼";
    }
    
    pub fn getRowColumnCross(self: Junctions) []const u8 {
        return self.row_column_cross orelse 
               self.header_column_cross orelse "┼";
    }
};

/// Helper functions for theme creation

/// Creates a simple theme with minimal configuration
pub fn simple(h: []const u8, v: []const u8, corner: []const u8) BoxyTheme {
    return .{
        .vertical = .{ .outer = v, .column = v },
        .horizontal = .{ .outer = h },
        .junction = .{ .outer_corner = corner },
    };
}

/// Creates a theme with different outer borders
pub fn bordered(top: []const u8, bottom: []const u8, left: []const u8, right: []const u8) BoxyTheme {
    return .{
        .vertical = .{ 
            .outer_left = left,
            .outer_right = right,
            .column = "│",
        },
        .horizontal = .{ 
            .outer_top = top,
            .outer_bottom = bottom,
        },
        .junction = .{},
    };
}