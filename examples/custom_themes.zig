/// Example showing how to create custom themes with the new systematic structure
/// This demonstrates different approaches to theme creation and the flexibility available

const std = @import("std");
const boxy = @import("boxy");

// The theme structure is exported from boxy
const BoxyTheme = boxy.BoxyTheme;

/// Custom theme 1: Matrix-style digital rain theme
/// Uses pipe characters and dots for a tech/hacker aesthetic
const matrix_theme = BoxyTheme{
    .vertical = .{
        .outer                      = "¹₀\n⁰₁", 
        .column                     = "┊\n┊",
    },
    .horizontal = .{
        .outer_top                  = "¹⁰¹",
        .outer_bottom               = "₁₀₁",
        .section                    = "…",
        .header                     = "…",
        .row                        = null,
    },
    .junction = .{
        // Corners with special characters
        .outer_top_left             = "ͺᶝ",
        .outer_top_right            = "¹ⱼ",
        .outer_bottom_left          = "ᶩ₀",
        .outer_bottom_right         = "₀ᶡ",
        
        // Section junctions
        .outer_section_t_left       = "¹₀",
        .outer_section_t_right      = "¹₁",
        
        // Header junctions  
        .outer_header_t_left        = "ᶷ₀",
        .outer_header_t_right       = "ᶛ₀",
        
        // Column junctions
        .outer_column_t_up          = "₀",
        .outer_column_t_down        = "╥",
        
        // Inner junctions
        .section_column_t_down      = "…",
        .header_column_cross        = "…",
    },
};

/// Custom theme 2: Ocean wave theme with flowing characters
/// Note: This theme has alignment challenges due to mixing single and double-width chars
/// Better to use consistent widths throughout
const ocean_theme = BoxyTheme{
    .vertical = .{
        .outer                      = "│",  // Single-width vertical
        .column                     = "┆",  // Light dotted
    },
    .horizontal = .{
        .outer                      = "~",   // Single-width tilde instead
        .section                    = "≈",   // Almost equal (wavy)
        .header                     = "~",   // Single-width tilde
        .row                        = null,
    },
    .junction = .{
        // Rounded corners
        .outer_top_left             = "╭",
        .outer_top_right            = "╮",
        .outer_bottom_left          = "╰",
        .outer_bottom_right         = "╯",
        
        // Flowing junctions
        .outer_section_t_left       = "┤",
        .outer_section_t_right      = "├",
        .outer_header_t_left        = "┤",
        .outer_header_t_right       = "├",
        
        .outer_column_t_up          = "┴",
        .outer_column_t_down        = "┬",
        
        .section_column_t_down      = "┬",
        .header_column_cross        = "┼",
    },
};

/// Custom theme 2b: Fullwidth theme - demonstrates proper double-width usage
/// ALL characters must be double-width or use pairs to maintain alignment
const fullwidth_theme = BoxyTheme{
    .vertical = .{
        .outer                      = "｜",  // Fullwidth vertical line (double-width)
        .column                     = "｜",  // Fullwidth for columns too
    },
    .horizontal = .{
        .outer                      = "－",  // Fullwidth hyphen-minus (double-width)
        .section                    = "＝",  // Fullwidth equals (double-width)
        .header                     = "－",  // Fullwidth hyphen
        .row                        = null,
    },
    .junction = .{
        // All corners must be double-width or pairs
        .outer_top_left             = "＋",  // Fullwidth plus
        .outer_top_right            = "＋",  // Fullwidth plus
        .outer_bottom_left          = "＋",  // Fullwidth plus
        .outer_bottom_right         = "＋",  // Fullwidth plus
        
        // All junctions must be double-width
        .outer_section_t_left       = "＋",  // Fullwidth plus
        .outer_section_t_right      = "＋",  // Fullwidth plus
        .outer_header_t_left        = "＋",  // Fullwidth plus
        .outer_header_t_right       = "＋",  // Fullwidth plus
        
        .outer_column_t_up          = "＋",  // Fullwidth plus
        .outer_column_t_down        = "＋",  // Fullwidth plus
        
        .section_column_t_down      = "＋",  // Fullwidth plus
        .header_column_cross        = "＋",  // Fullwidth plus
    },
};

/// Custom theme 3: Shadow box with 3D effect
/// Different characters on each side create depth
const shadow_3d_theme = BoxyTheme{
    .vertical = .{
        .outer_left                 = "█",      // Solid left
        .outer_right                = "█░",     // Right with shadow
        .column                     = "│",
    },
    .horizontal = .{
        .outer_top                  = "▀\nkjsdhf",   
        .outer_bottom               = "▄\nhjkhkjh░",    
        .section                    = "═\ns;ldfks;l",
        .header                     = "─\ndklsfjsdj",
        .row                        = null,
    },
    .junction = .{
        .outer_top_left             = "█",
        .outer_top_right            = "█░",     // Shadow on right
        .outer_bottom_left          = "█",  
        .outer_bottom_right         = "█░",    
        
        .outer_section_t_left       = "█░",
        .outer_section_t_right      = "█",
        .outer_header_t_left        = "█░",
        .outer_header_t_right       = "█",
        
        .outer_column_t_up          = "▄",
        .outer_column_t_down        = "▀",
        
        .section_column_t_down      = "┬",
        .header_column_cross        = "┼",
    },
};

/// Custom theme 4: Minimalist with strategic emphasis
/// Uses spaces mostly but emphasizes headers
const zen_theme = BoxyTheme{
    .vertical = .{
        .outer                      = " ",
        .column                     = " ",
    },
    .horizontal = .{
        .outer                      = " ",
        .section                    = "―",      // Em dash for title separator
        .header                     = "─",      // Light line for headers
        .row                        = null,
    },
    .junction = .{
        .outer_corner               = " ",
        
        // All outer junctions are spaces
        .outer_section_t_left       = " ",
        .outer_section_t_right      = " ",
        .outer_header_t_left        = " ",
        .outer_header_t_right       = " ",
        
        .outer_column_t_up          = " ",
        .outer_column_t_down        = " ",
        
        // But we show structure at intersections
        .section_column_t_down      = "·",
        .header_column_cross        = "·",
    },
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const stdout = std.io.getStdOut().writer();
    
    // Example 1: Matrix theme with technical data
    try stdout.writeAll("\n=== MATRIX THEME ===\n");
    var builder1 = boxy.new(allocator);
    var box1 = try builder1
        .title("System Monitor")
        .theme(matrix_theme)
        .orientation(.columns)
        .set("Process", &.{ "kernel", "systemd", "firefox", "zig" })
        .set("CPU %", &.{ "0.3", "1.2", "15.8", "78.4" })
        .set("Memory", &.{ "128M", "64M", "2.1G", "512M" })
        .build();
    defer box1.deinit();
    try box1.print(stdout);
    
    // Example 2: Ocean theme with travel data
    try stdout.writeAll("\n=== OCEAN THEME ===\n");
    var builder2 = boxy.new(allocator);
    var box2 = try builder2
        .title("Island Hopping Schedule")
        .theme(ocean_theme)
        .orientation(.rows)
        .set("Route", &.{ "Departure", "Arrival", "Duration" })
        .set("Maui → Oahu", &.{ "08:00", "08:45", "45 min" })
        .set("Oahu → Kauai", &.{ "10:30", "11:10", "40 min" })
        .set("Kauai → Big Island", &.{ "14:00", "15:20", "80 min" })
        .build();
    defer box2.deinit();
    try box2.print(stdout);
    
    // Example 3: Shadow 3D theme
    try stdout.writeAll("\n=== SHADOW 3D THEME ===\n");
    var builder3 = boxy.new(allocator);
    var box3 = try builder3
        .title("3D Graphics Settings")
        .theme(shadow_3d_theme)
        .orientation(.columns)
        .set("Setting", &.{ "Resolution", "Anti-alias", "Shadows", "Textures" })
        .set("Value", &.{ "1920x1080", "8x MSAA", "Ultra", "High" })
        .build();
    defer box3.deinit();
    try box3.print(stdout);
    
    // Example 4: Zen minimalist theme
    try stdout.writeAll("\n=== ZEN THEME ===\n");
    var builder4 = boxy.new(allocator);
    var box4 = try builder4
        .title("Daily Meditation")
        .theme(zen_theme)
        .orientation(.rows)
        .set("Morning", &.{ "Breathing", "Gratitude", "Intention" })
        .set("Evening", &.{ "Reflection", "Release", "Peace" })
        .build();
    defer box4.deinit();
    try box4.print(stdout);
    
    // Example 5: Fullwidth theme - demonstrates proper double-width character usage
    try stdout.writeAll("\n=== FULLWIDTH THEME (All Double-Width) ===\n");
    var builder5 = boxy.new(allocator);
    var box5 = try builder5
        .title("Ｆｕｌｌｗｉｄｔｈ")  // Even title in fullwidth!
        .theme(fullwidth_theme)
        .orientation(.columns)
        .set("Ｃｏｌ１", &.{ "Ａ", "Ｂ" })
        .set("Ｃｏｌ２", &.{ "Ｃ", "Ｄ" })
        .build();
    defer box5.deinit();
    try box5.print(stdout);
    
    // Example 6: Combining themes - show how to create variations
    try stdout.writeAll("\n=== CREATING THEME VARIATIONS ===\n");
    
    // Take the matrix theme and modify just the corners
    var matrix_rounded = matrix_theme;
    matrix_rounded.junction.outer_top_left = "╭";
    matrix_rounded.junction.outer_top_right = "╮";
    matrix_rounded.junction.outer_bottom_left = "╰";
    matrix_rounded.junction.outer_bottom_right = "╯";
    
    var builder6 = boxy.new(allocator);
    var box6 = try builder6
        .title("Matrix Theme with Rounded Corners")
        .theme(matrix_rounded)
        .orientation(.columns)
        .set("Modified", &.{ "Yes" })
        .set("Corners", &.{ "Rounded" })
        .set("Rest", &.{ "Same" })
        .build();
    defer box6.deinit();
    try box6.print(stdout);
    
    try stdout.writeAll("\n");
    try stdout.writeAll("This example demonstrates:\n");
    try stdout.writeAll("1. How to define custom themes using the systematic structure\n");
    try stdout.writeAll("2. Different visual styles (tech, nature, 3D, minimal)\n");
    try stdout.writeAll("3. Using different borders for each side (shadow_3d_theme)\n");
    try stdout.writeAll("4. Creating theme variations by modifying existing themes\n");
    try stdout.writeAll("5. How the systematic naming makes themes self-documenting\n");
}