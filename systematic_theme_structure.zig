/// Systematic theme structure based on line intersections
/// Every possible meeting of lines is explicitly named

const std = @import("std");

pub const BoxyTheme = struct {
    // All vertical lines
    vertical: VerticalLines = .{},
    
    // All horizontal lines  
    horizontal: HorizontalLines = .{},
    
    // All intersections/junctions
    junction: Junctions = .{},
};

pub const VerticalLines = struct {
    outer: []const u8 = "│",        // Left and right borders
    column: []const u8 = "│",       // Column dividers
};

pub const HorizontalLines = struct {
    outer: []const u8 = "─",        // Top and bottom borders
    section: []const u8 = "═",      // After title
    header: []const u8 = "─",       // Between headers and data
    row: []const u8 = "─",          // Between data rows
};

pub const Junctions = struct {
    // Outer × Outer = Corners
    outer_corner: ?[]const u8 = null,           // All four corners (simple mode)
    outer_top_left: ?[]const u8 = null,         // ┌ ╔ ╭
    outer_top_right: ?[]const u8 = null,        // ┐ ╗ ╮
    outer_bottom_left: ?[]const u8 = null,      // └ ╚ ╰
    outer_bottom_right: ?[]const u8 = null,     // ┘ ╝ ╯
    
    // Outer vertical × Inner horizontal
    outer_section_t_left: []const u8 = "╣",     // Right border meets section
    outer_section_t_right: []const u8 = "╠",    // Left border meets section
    outer_header_t_left: []const u8 = "┤",      // Right border meets header
    outer_header_t_right: []const u8 = "├",     // Left border meets header
    outer_row_t_left: []const u8 = "┤",         // Right border meets row
    outer_row_t_right: []const u8 = "├",        // Left border meets row
    
    // Outer horizontal × Inner vertical
    outer_column_t_up: []const u8 = "┴",        // Bottom border meets column
    outer_column_t_down: []const u8 = "┬",      // Top border meets column
    
    // Inner × Inner
    section_column_t_down: []const u8 = "╤",    // Column starts at section
    header_column_cross: []const u8 = "┼",      // Column continues through header
    row_column_cross: []const u8 = "┼",         // Column crosses row
    
    // Note: we don't have section_column_t_up because columns 
    // don't end at section lines in current implementation
};

// Example with this structure:
pub const pipes_theme_systematic = BoxyTheme{
    .vertical = .{
        .outer  = "║",
        .column = "│",
    },
    .horizontal = .{
        .outer   = "═",
        .section = "═",
        .header  = "─",
        .row     = null,  // No row dividers in pipes theme
    },
    .junction = .{
        .outer_top_left      = "╔",
        .outer_top_right     = "╗",
        .outer_bottom_left   = "╚",
        .outer_bottom_right  = "╝",
        
        .outer_section_t_left  = "╣",
        .outer_section_t_right = "╠",
        .outer_header_t_left   = "╢",
        .outer_header_t_right  = "╟",
        
        .outer_column_t_up     = "╧",
        .outer_column_t_down   = "╤",
        
        .section_column_t_down = "╤",
        .header_column_cross   = "┼",
    },
};

// The shopping list theme from your example:
pub const shopping_systematic = BoxyTheme{
    .vertical = .{
        .outer  = "|",
        .column = "|",
    },
    .horizontal = .{
        .outer   = "=",
        .section = "^",  // Different from outer!
        .header  = "^",  // The ^^^ line
        .row     = "-",
    },
    .junction = .{
        .outer_corner          = "o",
        
        .outer_section_t_left  = "m",
        .outer_section_t_right = "m",
        .outer_header_t_left   = "m",
        .outer_header_t_right  = "m",
        .outer_row_t_left      = "*",
        .outer_row_t_right     = "!",
        
        .section_column_t_down = "w",  // The 'w' you identified!
        .header_column_cross   = "w",  // Could be same or different
        .row_column_cross      = "+",
    },
};