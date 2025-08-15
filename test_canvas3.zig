const std = @import("std");
const boxy = @import("src/boxy.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var builder = boxy.new(allocator);
    var box = try builder
        .title("Canvas Test")
        .canvas(20, 5)
        .style(.simple)
        .build();
    defer box.deinit();

    // Modify canvas before first render
    if (box.getCanvas()) |canvas| {
        std.debug.print("Canvas pointer: {*}\n", .{canvas});
        try canvas.blitText(5, 2, "HELLO");
        std.debug.print("Canvas row 2 after modification: ", .{});
        for (canvas.buffer[2]) |char| {
            std.debug.print("{c}", .{char});
        }
        std.debug.print("\n", .{});
    }
    
    const stdout = std.io.getStdOut().writer();
    try box.print(stdout);
}