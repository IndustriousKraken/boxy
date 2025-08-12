const std = @import("std");
const boxy = @import("boxy");

pub fn main() !void {
    // Get allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a box with multi-line ASCII borders
    var builder = boxy.new(allocator);
    var box = try builder
        .title("Multi-Line Borders Test")
        .style(.ascii)
        .data(&.{ "This", "has", "multi-line", "borders!" })
        .build();
    defer box.deinit();

    // Print to stdout
    const stdout = std.io.getStdOut().writer();
    try box.print(stdout);
    
    std.debug.print("\nMulti-line borders working!\n", .{});
}