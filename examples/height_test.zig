const std = @import("std");
const boxy = @import("boxy");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const stdout = std.io.getStdOut().writer();
    
    // Test exact height constraint
    try stdout.print("=== Exact Height (10 lines) ===\n", .{});
    var box1 = boxy.new(allocator);
    var built1 = try box1
        .title("Height Constrained Box")
        .heightExact(10)
        .set("Name", &[_][]const u8{ "Alice", "Bob", "Charlie", "David", "Eve", "Frank", "Grace", "Henry" })
        .set("Score", &[_][]const u8{ "95", "87", "92", "88", "91", "85", "93", "90" })
        .build();
    
    try built1.print(stdout);
    try stdout.print("\n", .{});
    
    // Test minimum height
    try stdout.print("=== Minimum Height (15 lines) ===\n", .{});
    var box2 = boxy.new(allocator);
    var built2 = try box2
        .title("Min Height Box")
        .heightMin(15)
        .data(&[_][]const u8{ "Short", "Content" })
        .build();
    
    try built2.print(stdout);
    try stdout.print("\n", .{});
    
    // Test maximum height
    try stdout.print("=== Maximum Height (8 lines) ===\n", .{});
    var box3 = boxy.new(allocator);
    var built3 = try box3
        .title("Max Height Box")
        .heightMax(8)
        .set("Item", &[_][]const u8{ "One", "Two", "Three", "Four", "Five" })
        .set("Value", &[_][]const u8{ "1", "2", "3", "4", "5" })
        .build();
    
    try built3.print(stdout);
    try stdout.print("\n", .{});
    
    // Test height range
    try stdout.print("=== Height Range (10-12 lines) ===\n", .{});
    var box4 = boxy.new(allocator);
    var built4 = try box4
        .title("Range Height Box")
        .heightRange(10, 12)
        .set("Day", &[_][]const u8{ "Mon", "Tue", "Wed" })
        .set("Task", &[_][]const u8{ "Code", "Review", "Deploy" })
        .build();
    
    try built4.print(stdout);
}