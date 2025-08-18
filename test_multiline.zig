const std = @import("std");
const boxy = @import("src/boxy.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a theme with multi-line borders everywhere
    const multiline_theme = boxy.BoxyTheme{
        .horizontal = .{
            .outer_top = "═\n─",        // Two-line top border
            .outer_bottom = "═\n─",     // Two-line bottom border
            .header = "━\n╌",           // Two-line header divider
            .section = "─\n⋯",          // Two-line section divider  
            .row = "┈\n⋅",              // Two-line row divider
        },
        .vertical = .{
            .outer_left = "║\n│",      // Two-line left border
            .outer_right = "║\n│",     // Two-line right border
            .column = "┊\n¦",          // Two-line column separator
        },
        .junction = .{
            .outer_top_left = "╔\n┌",
            .outer_top_right = "╗\n┐",
            .outer_bottom_left = "╚\n└",
            .outer_bottom_right = "╝\n┘",
        },
    };

    var builder = boxy.new(allocator);
    var box = try builder
        .theme(multiline_theme)
        .title("Multi-line Border Test")
        .set("Column 1", &.{"Data 1", "Data 2"})
        .set("Column 2", &.{"Data 3", "Data 4"})
        .build();

    defer box.deinit();

    const stdout = std.io.getStdOut().writer();
    try box.print(stdout);
}