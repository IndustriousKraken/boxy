/// Theme definitions for Boxy boxes
///
/// This module contains the BoxyTheme structure and related functionality for
/// defining how boxes look. Themes control borders, corners, junctions, and
/// dividers.
///
/// Themes support:
/// - Simple mode (just h_border and v_border)
/// - Detailed mode (different borders for each side)
/// - Multi-line borders (using \n for 3D effects)
/// - Pattern-based borders that repeat

const std = @import("std");

/// Complete theme definition for a box
pub const BoxyTheme = struct {
    // Outer borders - simple mode (these are used if detailed borders aren't specified)
    h_border: ?[]const u8 = null,
    v_border: ?[]const u8 = null,
    
    // Outer borders - detailed mode (override simple mode if specified)
    top: ?[]const u8 = null,
    bottom: ?[]const u8 = null,
    left: ?[]const u8 = null,
    right: ?[]const u8 = null,
    
    // Corners - simple mode
    corner: ?[]const u8 = null,
    
    // Corners - detailed mode  
    tl: ?[]const u8 = null,  // top-left
    tr: ?[]const u8 = null,  // top-right
    bl: ?[]const u8 = null,  // bottom-left
    br: ?[]const u8 = null,  // bottom-right
    
    // Inner borders and junctions
    inner: InnerBorders = .{},
    
    // Junctions where inner borders meet outer borders
    junction: Junctions = .{},
    
    /// Get the effective top border (falls back to h_border if not specified)
    pub fn getTop(self: BoxyTheme) []const u8 {
        return self.top orelse self.h_border orelse "─";
    }
    
    /// Get the effective bottom border (falls back to h_border if not specified)
    pub fn getBottom(self: BoxyTheme) []const u8 {
        return self.bottom orelse self.h_border orelse "─";
    }
    
    /// Get the effective left border (falls back to v_border if not specified)
    pub fn getLeft(self: BoxyTheme) []const u8 {
        return self.left orelse self.v_border orelse "│";
    }
    
    /// Get the effective right border (falls back to v_border if not specified)
    pub fn getRight(self: BoxyTheme) []const u8 {
        return self.right orelse self.v_border orelse "│";
    }
    
    /// Get the effective top-left corner
    pub fn getTopLeft(self: BoxyTheme) []const u8 {
        return self.tl orelse self.corner orelse "┌";
    }
    
    /// Get the effective top-right corner
    pub fn getTopRight(self: BoxyTheme) []const u8 {
        return self.tr orelse self.corner orelse "┐";
    }
    
    /// Get the effective bottom-left corner
    pub fn getBottomLeft(self: BoxyTheme) []const u8 {
        return self.bl orelse self.corner orelse "└";
    }
    
    /// Get the effective bottom-right corner
    pub fn getBottomRight(self: BoxyTheme) []const u8 {
        return self.br orelse self.corner orelse "┘";
    }
    
    /// Check if this theme uses multi-line borders
    pub fn isMultiLine(self: BoxyTheme) bool {
        // Check if any border contains newlines
        if (self.left) |border| {
            if (std.mem.indexOf(u8, border, "\n") != null) return true;
        }
        if (self.right) |border| {
            if (std.mem.indexOf(u8, border, "\n") != null) return true;
        }
        // Top and bottom multi-line borders would be unusual but check anyway
        if (self.top) |border| {
            if (std.mem.indexOf(u8, border, "\n") != null) return true;
        }
        if (self.bottom) |border| {
            if (std.mem.indexOf(u8, border, "\n") != null) return true;
        }
        return false;
    }
    
    /// Calculate the border thickness (for multi-line borders)
    pub fn getBorderThickness(self: BoxyTheme) struct { top: usize, bottom: usize, left: usize, right: usize } {
        _ = self;
        // Implementation placeholder - count newlines
        return .{ .top = 1, .bottom = 1, .left = 1, .right = 1 };
    }
};

/// Inner borders for separating content within the box
pub const InnerBorders = struct {
    h: []const u8 = "─",           // Horizontal separator between rows
    v: []const u8 = "│",           // Vertical separator between columns
    section: []const u8 = "═",     // Heavy separator (e.g., after title)
    cross: []const u8 = "┼",       // Where h and v meet
    
    // T-junctions for inner borders
    t_down: []const u8 = "┬",      // ┬ shape (inner horizontal meets top border)
    t_up: []const u8 = "┴",        // ┴ shape (inner horizontal meets bottom border)
    t_right: []const u8 = "├",     // ├ shape (inner vertical meets left border)
    t_left: []const u8 = "┤",      // ┤ shape (inner vertical meets right border)
    
    // Optional row dividers (between data rows)
    row_divider: ?[]const u8 = null,      // Line between data rows (null = no dividers)
    row_cross: ?[]const u8 = null,        // Junction where row divider meets column separator
    row_left: ?[]const u8 = null,         // Junction where row divider meets left border
    row_right: ?[]const u8 = null,        // Junction where row divider meets right border
};

/// Junction points where inner borders meet outer borders
pub const Junctions = struct {
    top: []const u8 = "┬",         // Inner vertical meets top border
    bottom: []const u8 = "┴",      // Inner vertical meets bottom border
    left: []const u8 = "├",        // Inner horizontal meets left border
    right: []const u8 = "┤",       // Inner horizontal meets right border
};

/// Creates a simple theme with just horizontal and vertical borders
pub fn simple(h: []const u8, v: []const u8) BoxyTheme {
    return .{
        .h_border = h,
        .v_border = v,
    };
}

/// Creates a 3D theme with different borders on each side
pub fn dimensional(top: []const u8, bottom: []const u8, left: []const u8, right: []const u8) BoxyTheme {
    return .{
        .top = top,
        .bottom = bottom,
        .left = left,
        .right = right,
    };
}

/// Creates a theme from a custom border configuration
pub fn custom(config: BoxyTheme) BoxyTheme {
    return config;
}