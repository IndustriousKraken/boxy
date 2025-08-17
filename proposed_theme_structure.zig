/// Proposed new theme structure for Boxy
/// This restructures themes to be more logical and self-documenting

const std = @import("std");

/// Complete theme definition for a box
pub const BoxyTheme = struct {
    // Outer borders - all the edges of the box
    outer: OuterBorders = .{},
    
    // Inner dividers - all the lines inside the box
    inner: InnerDividers = .{},
    
    // Junctions - where outer borders meet inner dividers
    junction: Junctions = .{},
};

/// Outer borders of the box
pub const OuterBorders = struct {
    // Simple mode - same for all sides
    h: ?[]const u8 = null,              // horizontal (top and bottom)
    v: ?[]const u8 = null,              // vertical (left and right)
    corner: ?[]const u8 = null,         // all four corners
    
    // Detailed mode - override simple mode if specified
    top: ?[]const u8 = null,            // top edge
    bottom: ?[]const u8 = null,         // bottom edge
    left: ?[]const u8 = null,           // left edge
    right: ?[]const u8 = null,          // right edge
    
    // Corners
    top_left: ?[]const u8 = null,       // ╔ ┌ ╭
    top_right: ?[]const u8 = null,      // ╗ ┐ ╮
    bottom_left: ?[]const u8 = null,    // ╚ └ ╰
    bottom_right: ?[]const u8 = null,   // ╝ ┘ ╯
};

/// Inner dividers within the box
pub const InnerDividers = struct {
    // Basic dividers
    h: []const u8 = "─",                // horizontal divider
    v: []const u8 = "│",                // vertical divider
    cross: []const u8 = "┼",            // where h and v meet
    
    // Section divider (after title)
    section_h: ?[]const u8 = null,      // horizontal line for sections (defaults to h)
    section_cross: ?[]const u8 = null,  // cross for section dividers (defaults to cross)
    
    // Partial dividers (NOT YET IMPLEMENTED)
    // These would be for dividers that don't span the full width/height
    partial_t_down: ?[]const u8 = null,   // ┬ partial divider from top
    partial_t_up: ?[]const u8 = null,     // ┴ partial divider from bottom
    partial_t_right: ?[]const u8 = null,  // ├ partial divider from left
    partial_t_left: ?[]const u8 = null,   // ┤ partial divider from right
    
    // Row dividers (between data rows)
    row_h: ?[]const u8 = null,          // horizontal line between rows
    row_cross: ?[]const u8 = null,      // where row divider meets column
};

/// Junctions where outer borders meet inner dividers
pub const Junctions = struct {
    // Default junctions (used for all divider types unless overridden)
    t_down: []const u8 = "┬",           // ┬ junction at top border
    t_up: []const u8 = "┴",             // ┴ junction at bottom border
    t_right: []const u8 = "├",          // ├ junction at left border
    t_left: []const u8 = "┤",           // ┤ junction at right border
    
    // Section-specific junctions (optional refinement)
    section_t_right: ?[]const u8 = null,  // junction for section divider at left border
    section_t_left: ?[]const u8 = null,   // junction for section divider at right border
    
    // Header-specific junctions (optional refinement)
    header_t_right: ?[]const u8 = null,   // junction for header divider at left border
    header_t_left: ?[]const u8 = null,    // junction for header divider at right border
    header_t_down: ?[]const u8 = null,    // junction for header divider at top border
    header_t_up: ?[]const u8 = null,      // junction for header divider at bottom border
    
    // Row-specific junctions (optional refinement)
    row_t_right: ?[]const u8 = null,      // junction for row divider at left border
    row_t_left: ?[]const u8 = null,       // junction for row divider at right border
};

// Example usage with new structure:
pub const pipes_theme_new = BoxyTheme{
    .outer = .{
        .h            = "═",
        .v            = "║",
        .top_left     = "╔",
        .top_right    = "╗",
        .bottom_left  = "╚",
        .bottom_right = "╝",
    },
    .inner = .{
        .h            = "─",
        .v            = "│",
        .cross        = "┼",
        .section_h    = "═",     // Heavy line for section dividers
        .section_cross = "┼",    // Could be different if desired
    },
    .junction = .{
        .t_down       = "╤",     // ╤ double-horizontal, single-vertical
        .t_up         = "╧",     // ╧ double-horizontal, single-vertical
        .t_right      = "╠",     // ╠ double-vertical, single-horizontal
        .t_left       = "╣",     // ╣ double-vertical, single-horizontal
    },
};

// Grid theme with row dividers
pub const grid_theme_new = BoxyTheme{
    .outer = .{
        .h            = "─",
        .v            = "│",
        .top_left     = "┌",
        .top_right    = "┐",
        .bottom_left  = "└",
        .bottom_right = "┘",
    },
    .inner = .{
        .h            = "─",
        .v            = "│",
        .cross        = "┼",
        .row_h        = "─",     // Same as h, but explicit
        .row_cross    = "┼",     // Same as cross, but explicit
    },
    .junction = .{
        .t_down       = "┬",
        .t_up         = "┴",
        .t_right      = "├",
        .t_left       = "┤",
        // No need for row-specific junctions since they're the same
    },
};