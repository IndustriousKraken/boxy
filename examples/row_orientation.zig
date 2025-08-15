const std = @import("std");
const boxy = @import("boxy");

pub fn main() !void {
    // Get allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Example 1: Column orientation (default)
    std.debug.print("=== Column Orientation (default) ===\n", .{});
    std.debug.print("Each .set() call adds a column\n\n", .{});
    
    var col_builder = boxy.new(allocator);
    var col_box = try col_builder
        .title("Sales by Product (Columns)")
        .set("Product", &.{ "Apples", "Oranges", "Bananas" })
        .set("Q1", &.{ "100", "150", "200" })
        .set("Q2", &.{ "120", "140", "210" })
        .set("Q3", &.{ "130", "160", "190" })
        .style(.rounded)
        .build();
    defer col_box.deinit();
    
    const stdout = std.io.getStdOut().writer();
    try col_box.print(stdout);
    
    // Example 2: Row orientation
    std.debug.print("\n\n=== Row Orientation ===\n", .{});
    std.debug.print("Each .set() call adds a row\n\n", .{});
    
    var row_builder = boxy.new(allocator);
    var row_box = try row_builder
        .title("Sales by Product (Rows)")
        .orientation(.rows)  // Switch to row orientation!
        .set("Product", &.{ "Apples", "Oranges", "Bananas" })
        .set("Q1", &.{ "100", "150", "200" })
        .set("Q2", &.{ "120", "140", "210" })
        .set("Q3", &.{ "130", "160", "190" })
        .style(.rounded)
        .build();
    defer row_box.deinit();
    
    try row_box.print(stdout);
    
    // Example 3: Row orientation with spreadsheet mode
    std.debug.print("\n\n=== Row Orientation with Spreadsheet Mode ===\n", .{});
    std.debug.print("First row becomes column headers\n\n", .{});
    
    var spread_builder = boxy.new(allocator);
    var spread_box = try spread_builder
        .title("Employee Schedule (Row-based)")
        .orientation(.rows)
        .spreadsheet()
        .set("Staff", &.{ "Alice", "Bob", "Carol", "Dave" })  // Column headers
        .set("Mon", &.{ "9-5", "9-5", "Off", "12-8" })
        .set("Tue", &.{ "9-5", "Off", "9-5", "12-8" })
        .set("Wed", &.{ "Off", "12-8", "9-5", "Off" })
        .set("Thu", &.{ "9-5", "12-8", "Off", "9-5" })
        .set("Fri", &.{ "9-5", "Off", "12-8", "9-5" })
        .style(.bold)
        .build();
    defer spread_box.deinit();
    
    try spread_box.print(stdout);
}