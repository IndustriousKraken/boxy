const std = @import("std");
const boxy = @import("boxy");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Test with pipes theme to see junction issues clearly
    var builder = boxy.new(allocator);
    var box = try builder
        .title("Junction Test - Pipes Theme")
        .orientation(.columns)
        .set("Column 1", &.{ "A", "B", "C" })
        .set("Column 2", &.{ "D", "E", "F" })
        .set("Column 3", &.{ "G", "H", "I" })
        .style(.pipes)
        .build();
    defer box.deinit();

    const stdout = std.io.getStdOut().writer();
    try box.print(stdout);
    
    // Also test with rounded theme
    var builder2 = boxy.new(allocator);
    var box2 = try builder2
        .title("Junction Test - Rounded Theme")
        .orientation(.columns)
        .set("Column 1", &.{ "A", "B", "C" })
        .set("Column 2", &.{ "D", "E", "F" })
        .set("Column 3", &.{ "G", "H", "I" })
        .style(.rounded)
        .build();
    defer box2.deinit();
    
    try stdout.writeAll("\n");
    try box2.print(stdout);
}