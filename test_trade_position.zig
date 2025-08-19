const std = @import("std");
const boxy = @import("boxy");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    // Create the exact same trade box
    var trade_builder = boxy.new(allocator);
    var trade = try trade_builder
        .data(&.{"Fred: Boots", "You: 1 gold", "[TRADE]"})
        .style(.rounded)
        .width(.{ .exact = 65 })
        .build();
    defer trade.deinit();
    
    // Render it
    const output = try trade.render();
    defer allocator.free(output);
    
    // Print with column numbers
    std.debug.print("0123456789012345678901234567890123456789012345678901234567890123456789\n", .{});
    std.debug.print("0         1         2         3         4         5         6\n", .{});
    std.debug.print("{s}\n", .{output});
    
    // Find "[TRADE]" in the output
    var lines = std.mem.splitScalar(u8, output, '\n');
    var row: usize = 0;
    while (lines.next()) |line| : (row += 1) {
        if (std.mem.indexOf(u8, line, "[TRADE]")) |pos| {
            std.debug.print("Found [TRADE] at row {d}, starting at column {d}\n", .{row, pos});
            std.debug.print("The text '[TRADE]' spans columns {d}-{d}\n", .{pos, pos + 6});
        }
    }
}