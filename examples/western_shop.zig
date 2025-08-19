const std = @import("std");
const boxy = @import("boxy");

// Animation frames for faces
const FredFrames = struct {
    const mouths = [_]u8{ 'o', '-', 'o', 'o', '-', 'o', '-', 'o', 'o', '-', '-', '-', '-' };
    const eyes = [_][2]u8{ 
        .{ '*', '*' }, 
        .{ '>', '<' }, 
        .{ '*', '*' }, 
        .{ '>', '<' },
        .{ '*', '*' }, 
        .{ '*', '*' }, 
        .{ '*', '*' }, 
        .{ '*', '*' }, 
        .{ '*', '*' }, 
        .{ '*', '*' }, 
        .{ '*', '*' }, 
        .{ '*', '*' }, 
        .{ '*', '*' },
    };
};

const CharlesFrames = struct {
    const mouths = [_]u8{ 'w', 'w', 'v', 'w', 'v', 'o', 'w', 'o', 'w', 'w', 'o', 'w', 'o' };
    const eyes = [_][2]u8{
        .{ '.', '.' },
        .{ '.', '.' },
        .{ '.', '.' },
        .{ '.', '.' },
        .{ '.', '<' },
        .{ '.', '.' },
        .{ '.', '.' },
        .{ '.', '.' },
        .{ '.', '.' },
        .{ '.', '.' },
        .{ '.', '.' },
        .{ '>', '<' },
        .{ '.', '.' },
    };
};

fn drawFred(canvas: *boxy.BoxyCanvas, frame: usize) void {
    const mouth = FredFrames.mouths[frame % FredFrames.mouths.len];
    const eyes = FredFrames.eyes[frame % FredFrames.eyes.len];
    
    // Hat
    _ = canvas.blitText(2, 1, "____") catch {};
    _ = canvas.blitText(1, 2, "|    |") catch {};
    // Brim
    _ = canvas.blitText(0, 3, "--------") catch {};
    // Face
    _ = canvas.blitText(1, 4, "| ") catch {};
    canvas.setChar(3, 4, eyes[0]);
    _ = canvas.blitText(4, 4, " ") catch {};
    canvas.setChar(5, 4, eyes[1]);
    _ = canvas.blitText(6, 4, "|") catch {};
    // Mouth
    _ = canvas.blitText(2, 5, "[ ") catch {};
    canvas.setChar(4, 5, mouth);
    _ = canvas.blitText(5, 5, " ]") catch {};
}

fn drawCharles(canvas: *boxy.BoxyCanvas, frame: usize) void {
    const mouth = CharlesFrames.mouths[frame % CharlesFrames.mouths.len];
    const eyes = CharlesFrames.eyes[frame % CharlesFrames.eyes.len];
    
    // Hat
    _ = canvas.blitText(2, 1, "_____") catch {};
    _ = canvas.blitText(1, 2, "(     )") catch {};
    _ = canvas.blitText(1, 3, "|     |/") catch {};
    // Ground
    _ = canvas.blitText(0, 4, "~~~~~~~~~") catch {};
    // Face
    _ = canvas.blitText(1, 5, "| ") catch {};
    canvas.setChar(3, 5, eyes[0]);
    _ = canvas.blitText(4, 5, " ") catch {};
    canvas.setChar(5, 5, eyes[1]);
    _ = canvas.blitText(6, 5, " |") catch {};
    // Mouth
    _ = canvas.blitText(2, 6, "\\ ") catch {};
    canvas.setChar(4, 6, mouth);
    _ = canvas.blitText(5, 6, " /") catch {};
    _ = canvas.blitText(3, 7, "---") catch {};
}

/// Mouse event structure
const MouseEvent = struct {
    x: u16,
    y: u16,
    button: u8,
};

/// Parse mouse click events from terminal input
fn parseMouseEvent(buffer: []const u8) ?MouseEvent {
    // Mouse events in X10 format: ESC[M<button><x><y>
    // SGR format: ESC[<button>;x;yM or ESC[<button>;x;ym
    if (buffer.len < 6) return null;
    
    if (buffer[0] == '\x1b' and buffer[1] == '[') {
        // Check for SGR format (ESC[<...)
        if (buffer[2] == '<') {
            // Parse SGR format: ESC[<button>;col;row[Mm]
            var i: usize = 3;
            var button: u16 = 0;
            var x: u16 = 0;
            var y: u16 = 0;
            var field: usize = 0;
            
            while (i < buffer.len and field < 3) {
                if (buffer[i] >= '0' and buffer[i] <= '9') {
                    const digit = buffer[i] - '0';
                    switch (field) {
                        0 => button = button * 10 + digit,
                        1 => x = x * 10 + digit,
                        2 => y = y * 10 + digit,
                        else => {},
                    }
                } else if (buffer[i] == ';') {
                    field += 1;
                } else if (buffer[i] == 'M' or buffer[i] == 'm') {
                    // Mouse release (m) or press (M)
                    if (buffer[i] == 'M' and button == 0) { // Left button press
                        return MouseEvent{ .x = x, .y = y, .button = 1 };
                    }
                    break;
                }
                i += 1;
            }
        } else if (buffer[2] == 'M' and buffer.len >= 6) {
            // X10 format: ESC[M<button><x+32><y+32>
            const button = buffer[3] - 32;
            const x = buffer[4] - 32;
            const y = buffer[5] - 32;
            if (button == 0) { // Left click
                return MouseEvent{ .x = x, .y = y, .button = 1 };
            }
        }
    }
    return null;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn();
    
    // Save terminal state and set up raw mode
    const termios = std.posix.termios;
    var original_termios: termios = undefined;
    original_termios = try std.posix.tcgetattr(stdin.handle);
    defer std.posix.tcsetattr(stdin.handle, .FLUSH, original_termios) catch {};
    
    // Set raw mode for input
    var raw_termios = original_termios;
    raw_termios.lflag.ICANON = false;
    raw_termios.lflag.ECHO = false;
    raw_termios.cc[@intFromEnum(std.posix.V.MIN)] = 0;
    raw_termios.cc[@intFromEnum(std.posix.V.TIME)] = 0;
    try std.posix.tcsetattr(stdin.handle, .FLUSH, raw_termios);
    
    // Clear screen, hide cursor, and enable mouse tracking
    try stdout.print("\x1b[2J\x1b[H\x1b[?25l", .{});
    // Enable SGR mouse tracking (supports more terminals)
    try stdout.print("\x1b[?1006h\x1b[?1000h", .{});
    defer {
        // Disable mouse tracking and show cursor
        stdout.print("\x1b[?1000l\x1b[?1006l\x1b[?25h", .{}) catch {};
    }
    
    // Create layout manager for the entire interface (65 columns x 36 rows)
    var layout_mgr = try boxy.layout(allocator, 65, 36);
    defer layout_mgr.deinit();
    
    var frame: usize = 0;
    while (true) : (frame += 1) {
        if (frame > 60) {
            frame = 0;
        }
        // === Create all the boxes ===
        
        // Fred's animated face (top-left)
        var fred_canvas_builder = boxy.new(allocator);
        var fred_canvas = try fred_canvas_builder
            .canvas(10, 7)
            .style(.minimal)  // No borders for seamless integration
            .build();
        defer fred_canvas.deinit();
        
        // Draw Fred's face
        if (fred_canvas.getCanvas()) |canvas| {
            drawFred(canvas, frame);
        }
        
        // Fred's name label (below face)
        var fred_label_builder = boxy.new(allocator);
        var fred_label = try fred_label_builder
            .data(&.{"Fred W."})
            .style(.simple)
            .width(.{ .exact = 13 })
            .build();
        defer fred_label.deinit();
        
        // Shop inventory (right side, top)
        var shop_builder = boxy.new(allocator);
        var shop = try shop_builder
            .title("General Store")
            .data(&.{"Boots", "1 gold"})
            .data(&.{"Lasso", "2 silver"})
            .data(&.{"Bread", "1 copper"})
            .data(&.{"Saddle", "12 gold"})
            .data(&.{"Freedom Salt", "1 silver"})
            .data(&.{"", ""})
            .data(&.{"", ""})
            .data(&.{"Money", "25g 33s 107c"})
            .style(.simple)
            .width(.{ .exact = 48 })
            .build();
        defer shop.deinit();
        
        // Charles's animated face (bottom-left)
        var charles_canvas_builder = boxy.new(allocator);
        var charles_canvas = try charles_canvas_builder
            .canvas(10, 8)
            .style(.minimal)  // No borders
            .build();
        defer charles_canvas.deinit();
        
        // Draw Charles's face
        if (charles_canvas.getCanvas()) |canvas| {
            drawCharles(canvas, frame);
        }
        
        // Charles's name label
        var charles_label_builder = boxy.new(allocator);
        var charles_label = try charles_label_builder
            .data(&.{"Charles"})
            .style(.simple)
            .width(.{ .exact = 13 })
            .build();
        defer charles_label.deinit();
        
        // Charles's inventory (right side, middle)
        var inventory_builder = boxy.new(allocator);
        var inventory = try inventory_builder
            .title("Your Items")
            .data(&.{"Fancy hat", "1"})
            .data(&.{"Moustache wax", "3"})
            .data(&.{"Silver lasso", "1"})
            .data(&.{"Buffalo saddle", "1"})
            .data(&.{"Ruined boots", "1"})
            .data(&.{"...", "10 more items"})
            .data(&.{"", ""})
            .data(&.{"Money", "10g 211s 6c"})
            .style(.simple)
            .width(.{ .exact = 48 })
            .build();
        defer inventory.deinit();
        
        // Trade interface (bottom)
        var trade_builder = boxy.new(allocator);
        var trade = try trade_builder
            .data(&.{"Fred: Boots", "You: 1 gold", "[TRADE]"})
            .style(.rounded)
            .width(.{ .exact = 65 })
            .build();
        defer trade.deinit();
        
        // Dialogue box
        var dialogue_builder = boxy.new(allocator);
        var dialogue = try dialogue_builder
            .data(&.{
                if (frame < 30) 
                    "Fred: 'Howdy partner! Those boots'll serve ya well!'"
                else
                    "Charles: 'One gold seems fair for quality boots.'"
            })
            .data(&.{""})
            .data(&.{"-------------------------------------------------"})
            .data(&.{""})
            .data(&.{"*** Click TRADE to end the demo... ***"})
            .style(.minimal)
            .alignment(.center)
            .width(.{ .exact = 65 })
            .build();
        defer dialogue.deinit();
        
        // === Position all boxes in the layout ===
        
        // Fred's section (left side, top)
        try layout_mgr.place(&fred_canvas, 1, 1);
        try layout_mgr.place(&fred_label, 10, 0);
        
        // Shop (right side, top)
        try layout_mgr.place(&shop, 0, 15);
        
        // Charles's section (left side, bottom)
        try layout_mgr.place(&charles_canvas, 13, 1);
        try layout_mgr.place(&charles_label, 23, 0);
        
        // Inventory (right side, bottom, overlaps the 
        // bottom of the shop for seamless transition
        try layout_mgr.place(&inventory, 13, 15);
        
        // Trade interface
        try layout_mgr.place(&trade, 27, 0);
        
        // Remember the trade box position for click detection
        const trade_row = 27;
        // TRADE button is in the third column of the trade box
        // The text "[TRADE]" appears around column 40-47 in the trade box
        const trade_button_col_start = 43;
        const trade_button_col_end = 65;
        const trade_button_row = trade_row + 1; // Inside the box

        // Dialogue
        try layout_mgr.place(&dialogue, 30, 0);
        
        // === Render the complete layout ===
        
        // Move cursor to top
        try stdout.print("\x1b[H", .{});
        
        // Render the layout
        const output = try layout_mgr.render();
        defer allocator.free(output);  // Free the rendered output!
        try stdout.writeAll(output);
        
        // Check for mouse input (non-blocking)
        var input_buffer: [256]u8 = undefined;
        const bytes_read = stdin.read(&input_buffer) catch 0;
        
        if (bytes_read > 0) {
            // Check for escape key to exit
            if (input_buffer[0] == 27 and bytes_read == 1) {
                break; // ESC key pressed
            }
            
            // Parse mouse event
            if (parseMouseEvent(input_buffer[0..bytes_read])) |mouse| {
                // Check if click is within TRADE button area
                // Terminal coordinates are 1-based, so adjust
                const clicked_row = mouse.y - 1;
                const clicked_col = mouse.x - 1;
                
                if (clicked_row == trade_button_row and 
                    clicked_col >= trade_button_col_start and 
                    clicked_col <= trade_button_col_end) {
                    // TRADE button clicked!
                    break;
                }
            }
        }
        
        // Animation speed
        std.time.sleep(200 * std.time.ns_per_ms);
    }
    
    try stdout.print("\n\nTrade completed! Thanks for visiting the Wild West General Store!\n", .{});
}