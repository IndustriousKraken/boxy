const std = @import("std");
const boxy = @import("boxy");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const stdout = std.io.getStdOut().writer();

    // Example 1: Exact width
    std.debug.print("=== 1. EXACT WIDTH (50 chars) ===\n\n", .{});
    
    var ex1 = boxy.new(allocator);
    var box1 = try ex1
        .title("Exact Width Box")
        .exact(50)  // Exactly 50 characters wide
        .set("Name", &.{ "Alice", "Bob" })
        .set("Score", &.{ "95", "87" })
        .style(.rounded)
        .build();
    defer box1.deinit();
    try box1.print(stdout);

    // Example 2: Minimum width
    std.debug.print("\n\n=== 2. MINIMUM WIDTH (60 chars) ===\n\n", .{});
    
    var ex2 = boxy.new(allocator);
    var box2 = try ex2
        .title("Min Width Box")
        .min(60)  // At least 60 characters wide
        .set("A", &.{ "1", "2" })
        .set("B", &.{ "3", "4" })
        .style(.pipes)
        .build();
    defer box2.deinit();
    try box2.print(stdout);

    // Example 3: Maximum width with long content
    std.debug.print("\n\n=== 3. MAXIMUM WIDTH (40 chars) - Content gets truncated ===\n\n", .{});
    
    var ex3 = boxy.new(allocator);
    var box3 = try ex3
        .title("Max Width Box with Long Content That Should Be Truncated")
        .max(40)  // At most 40 characters wide
        .set("Product", &.{ "Super Long Product Name That Goes On Forever", "Another Really Long Name" })
        .set("Price", &.{ "$999.99", "$1234.56" })
        .style(.bold)
        .build();
    defer box3.deinit();
    try box3.print(stdout);

    // Example 4: Range constraint
    std.debug.print("\n\n=== 4. RANGE WIDTH (30-70 chars) ===\n\n", .{});
    
    // Small content - should expand to minimum
    var ex4a = boxy.new(allocator);
    var box4a = try ex4a
        .title("Range: Small")
        .range(30, 70)  // Between 30 and 70 chars
        .set("X", &.{ "1" })
        .set("Y", &.{ "2" })
        .style(.rounded)
        .build();
    defer box4a.deinit();
    std.debug.print("Small content (expands to min 30):\n", .{});
    try box4a.print(stdout);
    
    // Large content - should constrain to maximum
    var ex4b = boxy.new(allocator);
    var box4b = try ex4b
        .title("Range: Large Content That Would Normally Be Very Wide")
        .range(30, 70)  // Between 30 and 70 chars
        .set("Description", &.{ "This is a very long description that would make the box extremely wide" })
        .set("Status", &.{ "Active with lots of additional information" })
        .style(.rounded)
        .build();
    defer box4b.deinit();
    std.debug.print("\nLarge content (constrains to max 70):\n", .{});
    try box4b.print(stdout);

    // Example 5: Width constraint with spreadsheet mode
    std.debug.print("\n\n=== 5. WIDTH CONSTRAINTS WITH SPREADSHEET MODE ===\n\n", .{});
    
    var ex5 = boxy.new(allocator);
    var box5 = try ex5
        .title("Fixed Width Schedule")
        .exact(60)
        .spreadsheet()
        .set("Day", &.{ "Monday", "Tuesday", "Wednesday" })
        .set("Morning", &.{ "Meeting", "Coding", "Review" })
        .set("Afternoon", &.{ "Development", "Testing", "Planning" })
        .style(.grid)
        .build();
    defer box5.deinit();
    try box5.print(stdout);

    // Example 6: Using the generic width() method
    std.debug.print("\n\n=== 6. USING GENERIC width() METHOD ===\n\n", .{});
    
    var ex6 = boxy.new(allocator);
    var box6 = try ex6
        .title("Generic Width Method")
        .width(.{ .range = .{ .min = 40, .max = 60 } })
        .set("Method", &.{ "width()", "exact()", "min()", "max()", "range()" })
        .set("Type", &.{ "Generic", "Shortcut", "Shortcut", "Shortcut", "Shortcut" })
        .style(.neon)
        .build();
    defer box6.deinit();
    try box6.print(stdout);
}