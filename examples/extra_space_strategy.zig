const std = @import("std");
const boxy = @import("boxy");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const stdout = std.io.getStdOut().writer();

    // Create sample data
    _ = &[_][]const u8{ "A", "B", "C", "D", "E" };
    _ = &[_][]const u8{ "1", "2", "3", "4", "5" };

    std.debug.print("=== EXTRA SPACE DISTRIBUTION STRATEGIES ===\n", .{});
    std.debug.print("When a box has a fixed width larger than its content,\n", .{});
    std.debug.print("extra space must be distributed among columns.\n\n", .{});

    // Example 1: First strategy (default for spreadsheet mode)
    std.debug.print("1. FIRST - Extra space goes to first columns\n", .{});
    std.debug.print("   Good for spreadsheets where first column has row headers\n\n", .{});
    
    var ex1 = boxy.new(allocator);
    var box1 = try ex1
        .exact(60)
        .extraSpaceStrategy(.first)
        .set("A", &.{ "1", "2" })
        .set("B", &.{ "1", "2" })
        .set("C", &.{ "1", "2" })
        .set("D", &.{ "1", "2" })
        .set("E", &.{ "1", "2" })
        .style(.pipes)
        .build();
    defer box1.deinit();
    try box1.print(stdout);

    // Example 2: Last strategy (default for regular tables)
    std.debug.print("\n\n2. LAST - Extra space goes to last columns\n", .{});
    std.debug.print("   Good for data tables where last columns might have longer content\n\n", .{});
    
    var ex2 = boxy.new(allocator);
    var box2 = try ex2
        .exact(60)
        .extraSpaceStrategy(.last)
        .set("A", &.{ "1", "2" })
        .set("B", &.{ "1", "2" })
        .set("C", &.{ "1", "2" })
        .set("D", &.{ "1", "2" })
        .set("E", &.{ "1", "2" })
        .style(.pipes)
        .build();
    defer box2.deinit();
    try box2.print(stdout);

    // Example 3: Distributed strategy
    std.debug.print("\n\n3. DISTRIBUTED - Extra space spread evenly\n", .{});
    std.debug.print("   Good for uniform grids and balanced layouts\n\n", .{});
    
    var ex3 = boxy.new(allocator);
    var box3 = try ex3
        .exact(60)
        .extraSpaceStrategy(.distributed)
        .set("A", &.{ "1", "2" })
        .set("B", &.{ "1", "2" })
        .set("C", &.{ "1", "2" })
        .set("D", &.{ "1", "2" })
        .set("E", &.{ "1", "2" })
        .style(.pipes)
        .build();
    defer box3.deinit();
    try box3.print(stdout);

    // Example 4: Center strategy
    std.debug.print("\n\n4. CENTER - Extra space goes to center columns\n", .{});
    std.debug.print("   Good for highlighting middle columns\n\n", .{});
    
    var ex4 = boxy.new(allocator);
    var box4 = try ex4
        .exact(60)
        .extraSpaceStrategy(.center)
        .set("A", &.{ "1", "2" })
        .set("B", &.{ "1", "2" })
        .set("C", &.{ "1", "2" })
        .set("D", &.{ "1", "2" })
        .set("E", &.{ "1", "2" })
        .style(.pipes)
        .build();
    defer box4.deinit();
    try box4.print(stdout);

    // Practical example: Spreadsheet with row headers
    std.debug.print("\n\n=== PRACTICAL EXAMPLE: Spreadsheet ===\n", .{});
    std.debug.print("Using 'first' strategy to give more space to row headers\n\n", .{});
    
    var spread = boxy.new(allocator);
    var spreadbox = try spread
        .exact(70)
        .spreadsheet()
        .extraSpaceStrategy(.first)  // Extra space to first column (row headers)
        .set("Product", &.{ "Q1", "Q2", "Q3", "Q4" })
        .set("Laptops", &.{ "150", "165", "180", "195" })
        .set("Phones", &.{ "300", "320", "310", "330" })
        .set("Tablets", &.{ "80", "85", "90", "95" })
        .style(.rounded)
        .build();
    defer spreadbox.deinit();
    try spreadbox.print(stdout);

    // Show automatic strategy selection
    std.debug.print("\n\n=== AUTOMATIC STRATEGY SELECTION ===\n", .{});
    
    std.debug.print("Spreadsheet mode automatically uses 'first':\n", .{});
    var auto1 = boxy.new(allocator);
    var autobox1 = try auto1
        .exact(50)
        .spreadsheet()
        // No explicit strategy - will use 'first'
        .set("Item", &.{ "A", "B" })
        .set("Val1", &.{ "1", "2" })
        .set("Val2", &.{ "3", "4" })
        .style(.minimal)
        .build();
    defer autobox1.deinit();
    try autobox1.print(stdout);
    
    std.debug.print("\nRegular tables automatically use 'last':\n", .{});
    var auto2 = boxy.new(allocator);
    var autobox2 = try auto2
        .exact(50)
        // No explicit strategy - will use 'last'
        .set("A", &.{ "1", "2" })
        .set("B", &.{ "3", "4" })
        .set("C", &.{ "5", "6" })
        .style(.minimal)
        .build();
    defer autobox2.deinit();
    try autobox2.print(stdout);
}