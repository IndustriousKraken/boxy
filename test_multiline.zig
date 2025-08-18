const std = @import("std");
const boxy = @import("src/boxy.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a theme with multi-line horizontal borders
    const multiline_theme = boxy.BoxyTheme{
        .horizontal = .{
            .outer_top = "═\n─",     // Two-line top border
            .outer_bottom = "═\n─",  // Two-line bottom border
            .header = "═",
            .section = "═",
        },
        .vertical = .{
            .outer_left = "║",
            .outer_right = "║",
            .column = "│",
        },
        .junction = .{
            .outer_top_left = "╔",
            .outer_top_right = "╗",
            .outer_bottom_left = "╚",
            .outer_bottom_right = "╝",
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