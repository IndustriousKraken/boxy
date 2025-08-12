const std = @import("std");
const boxy = @import("boxy");

pub fn main() !void {
    // Get allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a minimal box with just a title
    var builder = boxy.new(allocator);
    var box = try builder
        .title("Test")
        .style(.simple)
        .build();
    defer box.deinit();

    // Print to stdout
    const stdout = std.io.getStdOut().writer();
    try box.print(stdout);
    
    std.debug.print("Minimal box printed successfully!\n", .{});
}