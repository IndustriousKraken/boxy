/// Complete theme structure accounting for ALL junction types
/// This includes inner-to-inner junctions we were missing!

const std = @import("std");

pub const BoxyTheme = struct {
    // Outer borders - edges of the box
    outer: OuterBorders = .{},
    
    // Inner dividers - lines inside the box
    inner: InnerDividers = .{},
    
    // Junctions - where outer borders meet inner dividers
    junction: OuterJunctions = .{},
    
    // Crosses - where inner dividers meet each other (NEW!)
    cross: InnerCrosses = .{},
};

/// Outer borders of the box
pub const OuterBorders = struct {
    // Simple mode
    h: ?[]const u8 = null,              // horizontal (top and bottom)
    v: ?[]const u8 = null,              // vertical (left and right)
    corner: ?[]const u8 = null,         // all four corners
    
    // Detailed mode
    top: ?[]const u8 = null,
    bottom: ?[]const u8 = null,
    left: ?[]const u8 = null,
    right: ?[]const u8 = null,
    
    top_left: ?[]const u8 = null,
    top_right: ?[]const u8 = null,
    bottom_left: ?[]const u8 = null,
    bottom_right: ?[]const u8 = null,
};

/// Inner dividers within the box
pub const InnerDividers = struct {
    // Basic dividers
    h: []const u8 = "─",                // horizontal divider
    v: []const u8 = "│",                // vertical divider
    
    // Specialized dividers
    header_h: ?[]const u8 = null,       // line between headers and data
    section_h: ?[]const u8 = null,      // line after title section
    row_h: ?[]const u8 = null,          // line between data rows
    
    // Partial dividers (for future features)
    partial_h: ?[]const u8 = null,      // doesn't span full width
    partial_v: ?[]const u8 = null,      // doesn't span full height
};

/// Where outer borders meet inner dividers
pub const OuterJunctions = struct {
    // Default junctions (used unless overridden)
    t_down: []const u8 = "┬",           // Top border meets vertical divider
    t_up: []const u8 = "┴",             // Bottom border meets vertical divider
    t_right: []const u8 = "├",          // Left border meets horizontal divider
    t_left: []const u8 = "┤",           // Right border meets horizontal divider
    
    // Specialized junctions (optional refinements)
    header_t_down: ?[]const u8 = null,  // Top border meets header divider
    header_t_up: ?[]const u8 = null,    // Bottom border meets header divider
    header_t_right: ?[]const u8 = null, // Left border meets header divider
    header_t_left: ?[]const u8 = null,  // Right border meets header divider
    
    section_t_right: ?[]const u8 = null, // Left border meets section divider
    section_t_left: ?[]const u8 = null,  // Right border meets section divider
    
    row_t_right: ?[]const u8 = null,    // Left border meets row divider
    row_t_left: ?[]const u8 = null,     // Right border meets row divider
};

/// Where inner dividers meet each other (NEW!)
pub const InnerCrosses = struct {
    // Basic cross
    cross: []const u8 = "┼",            // Generic h meets v
    
    // Specialized crosses (optional refinements)
    header_cross: ?[]const u8 = null,   // Column divider meets header line
    header_t_down: ?[]const u8 = null,  // Column starts at header line
    header_t_up: ?[]const u8 = null,    // Column ends at header line
    
    section_cross: ?[]const u8 = null,  // Column divider meets section line
    
    row_cross: ?[]const u8 = null,      // Column divider meets row divider
    row_t_down: ?[]const u8 = null,     // Row divider starts from column
    row_t_up: ?[]const u8 = null,       // Row divider ends at column
    
    // For partial dividers (future)
    partial_start: ?[]const u8 = null,  // Where partial divider begins
    partial_end: ?[]const u8 = null,    // Where partial divider ends
    partial_t_right: ?[]const u8 = null, // Partial meets vertical from left
    partial_t_left: ?[]const u8 = null,  // Partial meets vertical from right
};

// Example: Your shopping list box
pub const shopping_list_theme = BoxyTheme{
    .outer = .{
        .corner       = "o",
        .h            = "=",
        .v            = "|",
    },
    .inner = .{
        .v            = "|",
        .header_h     = "^",      // The ^^^ line
        .row_h        = "-",       // Full row dividers
        .partial_h    = ":",       // Partial row dividers (future)
    },
    .junction = .{
        .header_t_right = "m",    // Left border meets header line
        .header_t_left  = "m",    // Right border meets header line
        .row_t_right    = "!",    // Left border meets row divider
        .row_t_left     = "*",    // Right border meets row divider
    },
    .cross = .{
        .header_cross   = "w",    // Column meets header line
        .row_cross      = "+",    // Column meets row divider (if you had one)
        // For partial rows (future):
        .partial_start  = ",",    // Partial row starts from column
        .partial_end    = ";",    // Partial row ends at column
    },
};

// This structure now accounts for:
// 1. All outer border configurations
// 2. All types of inner dividers (full and partial)
// 3. All outer-to-inner junctions
// 4. All inner-to-inner crosses (NEW!)
// 5. Room for future extensions like partial dividers

// For composition (boxes within boxes), we'd use canvas mode
// and potentially a new feature to embed boxes within cells