const std = @import("std");
const boxy = @import("boxy");

// Animation frames for faces
const FredFrames = struct {
    const mouths = [_]u8{ 'o', '-', 'o', 'o', '-' };
    const eyes = [_][2]u8{ 
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
        .{ '*', '*' }, 
        .{ '*', '*' },
    };
};

const CharlesFrames = struct {
    const mouths = [_]u8{ 'w','w','v','w', 'v', 'o', 'w', 'o' };
    const eyes = [_][2]u8{
        .{ '.', '.' },
        .{ '.', '.' },
        .{ '.', '<' },
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

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    const stdout = std.io.getStdOut().writer();
    
    // Clear screen and hide cursor
    try stdout.print("\x1b[2J\x1b[H\x1b[?25l", .{});
    defer stdout.print("\x1b[?25h", .{}) catch {}; // Show cursor on exit
    
    // Create layout manager for the entire interface (65 columns x 25 rows)
    var layout_mgr = try boxy.layout(allocator, 65, 45);
    defer layout_mgr.deinit();
    
    var frame: usize = 0;
    while (true) : (frame += 1) {
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
                if (frame % 20 < 10) 
                    "Fred: 'Howdy partner! Those boots'll serve ya well!'"
                else
                    "Charles: 'One gold seems fair for quality boots.'"
            })
            .style(.minimal)
            .alignment(.center)
            .width(.{ .exact = 65 })
            .build();
        defer dialogue.deinit();
        
        // === Position all boxes in the layout ===
        
        // Fred's section (left side, top)
        try layout_mgr.place(&fred_canvas, 0, 1);
        try layout_mgr.place(&fred_label, 7, 0);
        
        // Shop (right side, top)
        try layout_mgr.place(&shop, 0, 15);
        
        // Charles's section (left side, bottom)
        try layout_mgr.place(&charles_canvas, 13, 1);
        try layout_mgr.place(&charles_label, 22, 0);
        
        // Inventory (right side, bottom)
        try layout_mgr.place(&inventory, 13, 15);
        
        // Dialogue
        try layout_mgr.place(&dialogue, 27, 0);
        
        // Trade interface (very bottom)
        try layout_mgr.place(&trade, 33, 0);
        
        // === Render the complete layout ===
        
        // Move cursor to top
        try stdout.print("\x1b[H", .{});
        
        // Render the layout
        const output = try layout_mgr.render();
        defer allocator.free(output);  // Free the rendered output!
        try stdout.writeAll(output);
        
        // Animation speed
        std.time.sleep(200 * std.time.ns_per_ms);
        
        // Exit after 50 frames for demo
        if (frame > 50) break;
    }
    
    try stdout.print("\n\nThanks for visiting the Wild West General Store!\n", .{});
}