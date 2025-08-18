const std = @import("std");
const boxy = @import("boxy");

// Animation frames for faces
const FredFrames = struct {
    const mouths = [_]u8{ 'o', '-', 'o', 'o', '-' };
    const eyes = [_][2]u8{ 
        .{ '*', '*' }, 
        .{ '>', '<' }, 
        .{ '*', '*' }, 
        .{ '<', '>' },
        .{ '*', '*' },
    };
};

const CharlesFrames = struct {
    const mouths = [_]u8{ 'w', 'v', 'w', 'w', 'o' };
    const eyes = [_][2]u8{
        .{ '.', '.' },
        .{ '-', '-' },
        .{ '.', '.' },
        .{ 'o', 'o' },
        .{ '.', '.' },
    };
};


pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    const stdout = std.io.getStdOut().writer();
    
    // Clear screen and hide cursor
    try stdout.print("\x1b[2J\x1b[H\x1b[?25l", .{});
    defer stdout.print("\x1b[?25h", .{}) catch {}; // Show cursor on exit
    
    var frame: usize = 0;
    while (true) : (frame += 1) {
        // Create the main shop interface as a spreadsheet
        var builder = boxy.new(allocator);
        var box = try builder
            .title("🤠 Wild West General Store 🤠")
            .spreadsheet()
            // Headers row
            .set("", &.{ "Item", "Price", "Stock" })
            // Fred's inventory
            .set("Fred's Shop", &.{ "Boots", "1 gold", "12" })
            .set("", &.{ "Lasso", "2 silver", "8" })
            .set("", &.{ "Bread", "1 copper", "50" })
            .set("", &.{ "Saddle", "12 gold", "3" })
            // Your inventory
            .set("Your Items", &.{ "Fancy hat", "owned", "1" })
            .set("", &.{ "Moustache wax", "owned", "1" })
            .set("", &.{ "Silver lasso", "owned", "1" })
            .style(.spreadsheet)
            .width(.{ .exact = 65 })
            .build();
        defer box.deinit();
        
        // Move cursor to top and render
        try stdout.print("\x1b[H", .{});
        
        // Print animated frame indicators
        const anim_chars = [_][]const u8{ "◐", "◓", "◑", "◒" };
        try stdout.print("\n  {s} Frame: {} {s}\n\n", .{ 
            anim_chars[frame % 4], 
            frame,
            anim_chars[(frame + 2) % 4],
        });
        
        try box.print(stdout);
        
        // Print animated ASCII art below
        try stdout.print("\n", .{});
        try printAnimatedFaces(stdout, frame);
        
        // Check for key press (non-blocking would need platform-specific code)
        // For demo, just sleep
        std.time.sleep(200 * std.time.ns_per_ms);
        
        // Simple exit after 30 frames for demo
        if (frame > 30) break;
    }
    
    try stdout.print("\n\nThanks for visiting the General Store!\n", .{});
}

fn printAnimatedFaces(writer: anytype, frame: usize) !void {
    const fred_mouth = FredFrames.mouths[frame % FredFrames.mouths.len];
    const fred_eyes = FredFrames.eyes[frame % FredFrames.eyes.len];
    const charles_mouth = CharlesFrames.mouths[frame % CharlesFrames.mouths.len];
    const charles_eyes = CharlesFrames.eyes[frame % CharlesFrames.eyes.len];
    
    try writer.print(
        \\     FRED                          CHARLES
        \\      ____                          _____
        \\     |    |                        (     )
        \\    --------                      |     |/
        \\     | {c} {c}|                      ~~~~~~~~~ 
        \\      [ {c} ]                       | {c} {c} |
        \\                                    \\ {c} /
        \\                                     ---
    , .{
        fred_eyes[0], fred_eyes[1], fred_mouth,
        charles_eyes[0], charles_eyes[1], charles_mouth,
    });
}