const std = @import("std");
const boxy = @import("boxy");

pub fn main() !void {
    // Get allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a box with canvas for animation demo
    var builder = boxy.new(allocator);
    var box = try builder
        .title("Dynamic Canvas - Frame Animation")
        .canvas(50, 10)
        .style(.rounded)
        .build();
    defer box.deinit();

    const stdout = std.io.getStdOut().writer();
    
    // Frame 1: Ball on left
    if (box.getCanvas()) |canvas| {
        canvas.clear();
        try canvas.blitText(5, 5, "O");
        try canvas.blitText(2, 1, "Frame 1");
    }
    try stdout.print("=== Animation Frame 1 ===\n", .{});
    try box.print(stdout);
    
    // Frame 2: Ball in middle
    if (box.getCanvas()) |canvas| {
        canvas.clear();
        try canvas.blitText(25, 5, "O");
        try canvas.blitText(2, 1, "Frame 2");
    }
    try stdout.print("\n=== Animation Frame 2 ===\n", .{});
    try box.refreshCanvas();
    try box.print(stdout);
    
    // Frame 3: Ball on right
    if (box.getCanvas()) |canvas| {
        canvas.clear();
        try canvas.blitText(45, 5, "O");
        try canvas.blitText(2, 1, "Frame 3");
    }
    try stdout.print("\n=== Animation Frame 3 ===\n", .{});
    try box.refreshCanvas();
    try box.print(stdout);
    
    std.debug.print("\nAnimation demo complete! Canvas can be updated dynamically.\n", .{});
    
    // Demo: Drawing shapes
    var shape_builder = boxy.new(allocator);
    var shape_box = try shape_builder
        .title("Canvas Drawing Primitives")
        .canvas(60, 12)
        .style(.double)
        .build();
    defer shape_box.deinit();
    
    if (shape_box.getCanvas()) |canvas| {
        // Draw a rectangle
        canvas.drawRect(5, 2, 15, 6, '*');
        
        // Draw horizontal and vertical lines
        canvas.drawHLine(25, 4, 20, '=');
        canvas.drawVLine(35, 6, 5, '|');
        
        // Fill a small rectangle
        canvas.fillRect(48, 2, 8, 3, '#');
        
        // Add labels
        try canvas.blitText(7, 8, "Rectangle");
        try canvas.blitText(27, 5, "Lines");
        try canvas.blitText(48, 6, "Filled");
    }
    
    try stdout.print("\n=== Drawing Primitives ===\n", .{});
    try shape_box.print(stdout);
}