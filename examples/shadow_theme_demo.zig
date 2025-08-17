const std = @import("std");
const theme = @import("../src/theme_new.zig");

// Shadow box theme with 3D effect
pub const shadow_theme = theme.BoxyTheme{
    .vertical = .{
        .outer_left                 = "█",
        .outer_right                = "█░",
        .column                     = "│",
    },
    .horizontal = .{
        .outer_top                  = "▀",
        .outer_bottom                = "▄▄░",
        .section                    = "═",
        .header                     = "─",
    },
    .junction = .{
        .outer_top_left             = "▛",
        .outer_top_right            = "▜░",
        .outer_bottom_left          = "▙",
        .outer_bottom_right         = "▟░░",
        
        .outer_section_t_left       = "█░",
        .outer_section_t_right      = "█",
        .outer_header_t_left        = "┤░",
        .outer_header_t_right       = "├",
        
        .outer_column_t_up          = "▄┴▄░",
        .outer_column_t_down        = "▀┬▀",
        
        .section_column_t_down      = "┬",
        .header_column_cross        = "┼",
    },
};

// Bevel theme with inset appearance
pub const bevel_theme = theme.BoxyTheme{
    .vertical = .{
        .outer_left                 = "▒",
        .outer_right                = "▌",
        .column                     = "│",
    },
    .horizontal = .{
        .outer_top                  = "▒",
        .outer_bottom                = "▀",
        .section                    = "─",
        .header                     = "─",
    },
    .junction = .{
        .outer_top_left             = "▒",
        .outer_top_right            = "▐",
        .outer_bottom_left          = "▒",
        .outer_bottom_right         = "▀",
        
        .outer_section_t_left       = "▌",
        .outer_section_t_right      = "▒",
        .outer_header_t_left        = "▌",
        .outer_header_t_right       = "▒",
        
        .outer_column_t_up          = "▀",
        .outer_column_t_down        = "▒",
        
        .section_column_t_down      = "┬",
        .header_column_cross        = "┼",
    },
};

// Double shadow theme - more elaborate
pub const double_shadow_theme = theme.BoxyTheme{
    .vertical = .{
        .outer_left                 = "░▒",
        .outer_right                = "▒░",
        .column                     = "│",
    },
    .horizontal = .{
        .outer_top                  = "░░",
        .outer_bottom                = "▒▒",
        .section                    = "══",
        .header                     = "──",
    },
    .junction = .{
        .outer_top_left             = "░░",
        .outer_top_right            = "▒░",
        .outer_bottom_left          = "░▒",
        .outer_bottom_right         = "▒▒",
        
        .outer_section_t_left       = "▒░",
        .outer_section_t_right      = "░▒",
        .outer_header_t_left        = "▒░",
        .outer_header_t_right       = "░▒",
        
        .outer_column_t_up          = "▒▒",
        .outer_column_t_down        = "░░",
        
        .section_column_t_down      = "╤╤",
        .header_column_cross        = "┼┼",
    },
};

pub fn main() !void {
    // These themes would be used like:
    // var box = try Boxy.new(allocator)
    //     .theme(shadow_theme)
    //     .title("3D Shadow Box")
    //     .build();
    
    std.debug.print("Shadow and bevel themes defined!\n", .{});
    std.debug.print("These demonstrate different borders for each side.\n", .{});
}