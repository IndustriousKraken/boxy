const std = @import("std");
const boxy = @import("boxy");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const stdout = std.io.getStdOut().writer();

    // Example 1: Column orientation (default) - NO spreadsheet
    std.debug.print("=== 1. COLUMNS (default) - Each .set() is a column ===\n\n", .{});
    
    var ex1 = boxy.new(allocator);
    var box1 = try ex1
        .set("Name", &.{ "Alice", "Bob", "Carol" })
        .set("Age", &.{ "25", "30", "28" })
        .set("City", &.{ "NYC", "LA", "Chicago" })
        .style(.rounded)
        .build();
    defer box1.deinit();
    try box1.print(stdout);

    // Example 2: Column orientation WITH spreadsheet mode
    std.debug.print("\n\n=== 2. COLUMNS + SPREADSHEET - First .set() becomes column headers ===\n\n", .{});
    
    var ex2 = boxy.new(allocator);
    var box2 = try ex2
        .spreadsheet()  // Enable spreadsheet mode
        .set("Person", &.{ "Name", "Age", "City" })  // This becomes headers!
        .set("Alice", &.{ "Alice", "25", "NYC" })
        .set("Bob", &.{ "Bob", "30", "LA" })
        .set("Carol", &.{ "Carol", "28", "Chicago" })
        .style(.rounded)
        .build();
    defer box2.deinit();
    try box2.print(stdout);

    // Example 3: Row orientation - NO spreadsheet
    std.debug.print("\n\n=== 3. ROWS - Each .set() is a row ===\n\n", .{});
    
    var ex3 = boxy.new(allocator);
    var box3 = try ex3
        .orientation(.rows)  // Switch to rows
        .set("Name", &.{ "Alice", "Bob", "Carol" })
        .set("Age", &.{ "25", "30", "28" })
        .set("City", &.{ "NYC", "LA", "Chicago" })
        .style(.rounded)
        .build();
    defer box3.deinit();
    try box3.print(stdout);

    // Example 4: Row orientation WITH spreadsheet mode
    std.debug.print("\n\n=== 4. ROWS + SPREADSHEET - First .set() becomes column headers ===\n\n", .{});
    
    var ex4 = boxy.new(allocator);
    var box4 = try ex4
        .orientation(.rows)
        .spreadsheet()
        .set("Person", &.{ "Name", "Age", "City" })  // Headers row
        .set("Alice", &.{ "Alice", "25", "NYC" })
        .set("Bob", &.{ "Bob", "30", "LA" })
        .set("Carol", &.{ "Carol", "28", "Chicago" })
        .style(.rounded)
        .build();
    defer box4.deinit();
    try box4.print(stdout);

    // Show the key difference
    std.debug.print("\n\n=== KEY DIFFERENCES ===\n", .{});
    std.debug.print("- ORIENTATION controls how .set() is interpreted (as column vs row)\n", .{});
    std.debug.print("- SPREADSHEET controls whether first dataset becomes headers\n", .{});
    std.debug.print("- They work together but serve different purposes!\n\n", .{});
    
    // Practical example: Sales data
    std.debug.print("=== PRACTICAL EXAMPLE: Sales Data ===\n\n", .{});
    
    // Same data, different approaches
    std.debug.print("Approach 1: Think in COLUMNS (products are columns)\n", .{});
    var sales1 = boxy.new(allocator);
    var sbox1 = try sales1
        .set("Quarter", &.{ "Q1", "Q2", "Q3", "Q4" })
        .set("Apples", &.{ "100", "120", "110", "130" })
        .set("Oranges", &.{ "80", "90", "95", "105" })
        .style(.pipes)
        .build();
    defer sbox1.deinit();
    try sbox1.print(stdout);
    
    std.debug.print("\nApproach 2: Think in ROWS (quarters are rows)\n", .{});
    var sales2 = boxy.new(allocator);
    var sbox2 = try sales2
        .orientation(.rows)
        .set("Product", &.{ "Apples", "Oranges" })
        .set("Q1", &.{ "100", "80" })
        .set("Q2", &.{ "120", "90" })
        .set("Q3", &.{ "110", "95" })
        .set("Q4", &.{ "130", "105" })
        .style(.pipes)
        .build();
    defer sbox2.deinit();
    try sbox2.print(stdout);
    
    std.debug.print("\nBoth produce the same table, but let you think about data differently!\n", .{});
}