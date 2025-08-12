const std = @import("std");
const boxy = @import("src/boxy.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Test .first strategy explicitly
    var builder1 = boxy.new(allocator);
    var box1 = try builder1
        .title("Extra Space → First Column")
        .set("Column A", &.{ "Data 1", "Data 2" })
        .set("Column B", &.{ "Data 3", "Data 4" })
        .set("Column C", &.{ "Data 5", "Data 6" })
        .exact(50)
        .extraSpaceStrategy(.first)
        .build();
    defer box1.deinit();

    const stdout = std.io.getStdOut().writer();
    try box1.print(stdout);
    
    std.debug.print("\n\n", .{});
    
    // Test .last strategy explicitly
    var builder2 = boxy.new(allocator);
    var box2 = try builder2
        .title("Extra Space → Last Column")
        .set("Column A", &.{ "Data 1", "Data 2" })
        .set("Column B", &.{ "Data 3", "Data 4" })
        .set("Column C", &.{ "Data 5", "Data 6" })
        .exact(50)
        .extraSpaceStrategy(.last)
        .build();
    defer box2.deinit();
    
    try box2.print(stdout);
    
    std.debug.print("\n\n", .{});
    
    // Test .center strategy
    var builder3 = boxy.new(allocator);
    var box3 = try builder3
        .title("Extra Space → Center Column")
        .set("Column A", &.{ "Data 1", "Data 2" })
        .set("Column B", &.{ "Data 3", "Data 4" })
        .set("Column C", &.{ "Data 5", "Data 6" })
        .exact(50)
        .extraSpaceStrategy(.center)
        .build();
    defer box3.deinit();
    
    try box3.print(stdout);
}