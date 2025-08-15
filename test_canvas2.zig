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

    // Check the canvas content before and after modification
    if (box.getCanvas()) |canvas| {
        std.debug.print("Initial canvas row 2: ", .{});
        for (canvas.buffer[2]) |char| {
            std.debug.print("{c}", .{char});
        }
        std.debug.print("\n", .{});
        
        try canvas.blitText(5, 2, "HELLO");
        
        std.debug.print("Modified canvas row 2: ", .{});
        for (canvas.buffer[2]) |char| {
            std.debug.print("{c}", .{char});
        }
        std.debug.print("\n", .{});
    }
    
    // Force re-render by clearing cache
    try box.refreshCanvas();
    
    const stdout = std.io.getStdOut().writer();
    try box.print(stdout);
}