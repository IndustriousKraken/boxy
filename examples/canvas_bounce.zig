const std = @import("std");
const boxy = @import("boxy");

// Animation state for bouncing ball
const Ball = struct {
    x: f32,
    y: f32,
    vx: f32,
    vy: f32,
    trail: std.ArrayList([2]usize),
    
    pub fn init(allocator: std.mem.Allocator) Ball {
        return .{
            .x = 5,
            .y = 3,
            .vx = 1.5,
            .vy = 0.8,
            .trail = std.ArrayList([2]usize).init(allocator),
        };
    }
    
    pub fn deinit(self: *Ball) void {
        self.trail.deinit();
    }
    
    pub fn update(self: *Ball, width: usize, height: usize) !void {
        // Update position
        self.x += self.vx;
        self.y += self.vy;
        
        // Add current position to trail
        try self.trail.append(.{ @as(usize, @intFromFloat(self.x)), @as(usize, @intFromFloat(self.y)) });
        if (self.trail.items.len > 5) {
            _ = self.trail.orderedRemove(0);
        }
        
        // Bounce off walls
        if (self.x <= 0 or self.x >= @as(f32, @floatFromInt(width - 1))) {
            self.vx = -self.vx;
            self.x = if (self.x <= 0) 1 else @as(f32, @floatFromInt(width - 2));
        }
        if (self.y <= 0 or self.y >= @as(f32, @floatFromInt(height - 1))) {
            self.vy = -self.vy;
            self.y = if (self.y <= 0) 1 else @as(f32, @floatFromInt(height - 2));
        }
        
        // Add some gravity effect
        self.vy += 0.1;
        if (self.vy > 2.0) self.vy = 2.0;
        if (self.vy < -2.0) self.vy = -2.0;
    }
};

pub fn main() !void {
    // Get allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a box with canvas for animation
    var builder = boxy.new(allocator);
    var box = try builder
        .title("🎾 Bouncing Ball Animation - Press Ctrl+C to stop")
        .canvas(60, 15)
        .style(.rounded)
        .build();
    defer box.deinit();

    const stdout = std.io.getStdOut().writer();
    
    // Clear screen and hide cursor
    try stdout.print("\x1b[2J\x1b[H\x1b[?25l", .{});
    
    // Animation state
    var ball = Ball.init(allocator);
    defer ball.deinit();
    
    var stars = std.ArrayList([2]usize).init(allocator);
    defer stars.deinit();
    
    // Add some stars for visual effect
    var prng = std.Random.DefaultPrng.init(@as(u64, @intCast(std.time.timestamp())));
    const random = prng.random();
    for (0..15) |_| {
        try stars.append(.{ 
            random.intRangeAtMost(usize, 1, 58),
            random.intRangeAtMost(usize, 1, 13) 
        });
    }
    
    // Animation loop
    var frame: usize = 0;
    while (frame < 200) : (frame += 1) {
        // Clear canvas
        if (box.getCanvas()) |canvas| {
            canvas.clear();
            
            // Draw stars (twinkling effect)
            for (stars.items) |star| {
                const char: u8 = if (frame % 3 == 0) '.' else if (frame % 5 == 0) '+' else '*';
                canvas.setChar(star[0], star[1], char);
            }
            
            // Draw ball trail
            for (ball.trail.items, 0..) |pos, i| {
                const trail_char: u8 = switch (i) {
                    0 => '.',
                    1 => 'o',
                    2 => 'o',
                    3 => 'O',
                    else => 'O',
                };
                canvas.setChar(pos[0], pos[1], trail_char);
            }
            
            // Draw ball
            const ball_x = @as(usize, @intFromFloat(ball.x));
            const ball_y = @as(usize, @intFromFloat(ball.y));
            canvas.setChar(ball_x, ball_y, '@');
            
            // Draw score/info
            var buf: [100]u8 = undefined;
            const info = try std.fmt.bufPrint(&buf, "Frame: {d:3} Pos: ({d:2},{d:2})", .{ 
                frame, ball_x, ball_y 
            });
            try canvas.blitText(2, 0, info);
            
            // Draw velocity indicator
            const vx_bar_len = @abs(@as(i32, @intFromFloat(ball.vx * 5)));
            
            if (ball.vx > 0) {
                canvas.drawHLine(45, 0, @as(usize, @intCast(vx_bar_len)), '>');
            } else {
                canvas.drawHLine(45 - @as(usize, @intCast(vx_bar_len)), 0, @as(usize, @intCast(vx_bar_len)), '<');
            }
        }
        
        // Move cursor to home position and render
        try stdout.print("\x1b[H", .{});
        try box.refreshCanvas();
        try box.print(stdout);
        
        // Update physics
        try ball.update(60, 15);
        
        // Sleep for animation (approximately 30 FPS)
        std.time.sleep(33_333_333); // 33ms
    }
    
    // Show cursor again
    try stdout.print("\x1b[?25h\n", .{});
    std.debug.print("Animation complete! The ball bounced for 200 frames.\n", .{});
    
    // Demo 2: Simple sine wave animation
    try stdout.print("\n=== Press Enter for sine wave demo ===", .{});
    _ = try std.io.getStdIn().reader().readByte();
    
    // Clear screen again
    try stdout.print("\x1b[2J\x1b[H\x1b[?25l", .{});
    
    var wave_builder = boxy.new(allocator);
    var wave_box = try wave_builder
        .title("〜 Sine Wave Animation 〜")
        .canvas(70, 12)
        .style(.rounded)
        .build();
    defer wave_box.deinit();
    
    // Wave animation
    frame = 0;
    while (frame < 150) : (frame += 1) {
        if (wave_box.getCanvas()) |canvas| {
            canvas.clear();
            
            // Draw sine wave
            for (0..70) |x| {
                const angle = @as(f32, @floatFromInt(x)) * 0.2 + @as(f32, @floatFromInt(frame)) * 0.1;
                const y_float = @sin(angle) * 4.0 + 5.5;
                const y = @as(usize, @intFromFloat(y_float));
                
                if (y < 12) {
                    canvas.setChar(x, y, '~');
                    
                    // Add some decorative elements
                    if (x % 10 == 0) {
                        if (y > 0) canvas.setChar(x, y - 1, '.');
                        if (y < 11) canvas.setChar(x, y + 1, '.');
                    }
                }
            }
            
            // Draw axis
            canvas.drawHLine(0, 6, 70, '-');
            
            // Add time display
            var buf: [50]u8 = undefined;
            const time_str = try std.fmt.bufPrint(&buf, "t = {d:.1}", .{
                @as(f32, @floatFromInt(frame)) * 0.1
            });
            try canvas.blitText(2, 10, time_str);
        }
        
        // Render
        try stdout.print("\x1b[H", .{});
        try wave_box.refreshCanvas();
        try wave_box.print(stdout);
        
        std.time.sleep(50_000_000); // 50ms for slower wave
    }
    
    // Restore cursor
    try stdout.print("\x1b[?25h\n", .{});
    std.debug.print("Wave animation complete!\n", .{});
}