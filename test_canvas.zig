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

    std.debug.print("Box created\n", .{});
    
    if (box.getCanvas()) |canvas| {
        std.debug.print("Canvas found! Width: {}, Height: {}\n", .{canvas.width, canvas.height});
        try canvas.blitText(5, 2, "HELLO");
        // Must refresh after modifying canvas directly!
        try box.refreshCanvas();
    } else {
        std.debug.print("No canvas found!\n", .{});
    }
    
    const stdout = std.io.getStdOut().writer();
    try box.print(stdout);
}