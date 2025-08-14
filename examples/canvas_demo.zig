const std = @import("std");
const boxy = @import("boxy");

pub fn main() !void {
    // Get allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a box with a canvas for drawing
    var builder = boxy.new(allocator);
    var box = try builder
        .title("Canvas Demo - ASCII Art Playground")
        .canvas(40, 10)  // 40 chars wide, 10 lines tall
        .style(.rounded)
        .build();
    defer box.deinit();

    // Get the canvas for drawing
    if (box.getCanvas()) |canvas| {
        // Draw a simple smiley face
        try canvas.blitText(15, 2, "  .-\"\"\"-.");
        try canvas.blitText(15, 3, " /       \\");
        try canvas.blitText(15, 4, "|  o   o  |");
        try canvas.blitText(15, 5, "|    >    |");
        try canvas.blitText(15, 6, "|   ___   |");
        try canvas.blitText(15, 7, " \\  \\_/  /");
        try canvas.blitText(15, 8, "  '-...-'");
        
        // Add some text
        try canvas.blitText(2, 1, "Hello!");
        try canvas.blitText(2, 9, "Canvas mode works!");
    }

    // Print to stdout
    const stdout = std.io.getStdOut().writer();
    try box.print(stdout);
    
    std.debug.print("\nCanvas demo printed successfully!\n", .{});
    
    // Now let's create another example with dynamic content
    var game_builder = boxy.new(allocator);
    var game_box = try game_builder
        .title("Mini Game Display")
        .canvas(50, 15)
        .style(.bold)
        .build();
    defer game_box.deinit();
    
    if (game_box.getCanvas()) |canvas| {
        // Draw a simple game scene
        // Draw ground
        canvas.drawHLine(0, 12, 50, '=');
        
        // Draw a tree
        try canvas.blitBlock(5, 8, 
            \\  /\
            \\ /  \
            \\/ __ \
            \\  ||
        );
        
        // Draw player
        try canvas.blitText(20, 11, "@");
        try canvas.blitText(18, 10, "\\o/");
        
        // Draw enemy
        try canvas.blitText(35, 11, "X");
        
        // Draw score
        try canvas.blitText(2, 1, "Score: 1000");
        try canvas.blitText(35, 1, "Lives: 3");
        
        // Draw some clouds
        try canvas.blitText(10, 3, "~~~");
        try canvas.blitText(30, 2, "~~~");
        try canvas.blitText(40, 4, "~~");
    }
    
    try game_box.print(stdout);
    std.debug.print("\nGame display demo printed successfully!\n", .{});
}