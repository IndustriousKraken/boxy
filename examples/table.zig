const std = @import("std");
const boxy = @import("boxy");

pub fn main() !void {
    // Get allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a table with columns
    var builder = boxy.new(allocator);
    var box = try builder
        .title("Shopping List")
        .style(.pipes)
        .cellPadding(2)  // Nice padding for readability!
        .set("Groceries", &.{ "Carrots", "Tangerines", "Parsley" })
        .set("Colors", &.{ "Orange", "Orange", "Green" })
        .set("Price", &.{ "$2.99", "$4.50", "$1.25" })
        .build();
    defer box.deinit();

    // Print to stdout
    const stdout = std.io.getStdOut().writer();
    try box.print(stdout);
    
    std.debug.print("\nTable rendered successfully!\n", .{});
}