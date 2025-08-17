const std = @import("std");
const boxy = @import("boxy");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Test without title - should show junctions on top and bottom borders
    var builder = boxy.new(allocator);
    var box = try builder
        .orientation(.columns)
        .set("Column 1", &.{ "A", "B", "C" })
        .set("Column 2", &.{ "D", "E", "F" })
        .set("Column 3", &.{ "G", "H", "I" })
        .style(.pipes)
        .build();
    defer box.deinit();

    const stdout = std.io.getStdOut().writer();
    std.debug.print("Pipes theme without title (should have top/bottom junctions):\n", .{});
    try box.print(stdout);
    
    // Also test with rounded theme
    var builder2 = boxy.new(allocator);
    var box2 = try builder2
        .orientation(.columns)
        .set("Column 1", &.{ "A", "B", "C" })
        .set("Column 2", &.{ "D", "E", "F" })
        .set("Column 3", &.{ "G", "H", "I" })
        .style(.rounded)
        .build();
    defer box2.deinit();
    
    try stdout.writeAll("\nRounded theme without title (should have top/bottom junctions):\n");
    try box2.print(stdout);
    
    // Test with spreadsheet mode which should always have junctions
    var builder3 = boxy.new(allocator);
    var box3 = try builder3
        .spreadsheet()
        .set("Headers", &.{ "Col A", "Col B", "Col C" })
        .set("Row 1", &.{ "A1", "B1", "C1" })
        .set("Row 2", &.{ "A2", "B2", "C2" })
        .style(.pipes)
        .build();
    defer box3.deinit();
    
    try stdout.writeAll("\nSpreadsheet mode (should have junctions everywhere):\n");
    try box3.print(stdout);
}