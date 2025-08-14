const std = @import("std");
const boxy = @import("boxy");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const stdout = std.io.getStdOut().writer();
    
    // Test with CJK characters in title
    var box1 = boxy.new(allocator);
    var built1 = try box1
        .title("〜 Wave Dash Test 〜")
        .data(&[_][]const u8{
            "Regular", "Text",
            "Works", "Fine",
        })
        .build();
    
    try built1.print(stdout);
    std.debug.print("\n", .{});
    
    // Test with CJK characters in data using .set() for columns with headers
    var box2 = boxy.new(allocator);
    var built2 = try box2
        .title("CJK in Data")
        .set("Item", &[_][]const u8{ "Wave", "Mixed", "Emoji" })
        .set("Value", &[_][]const u8{ "〜〜〜", "Text〜Wave", "🎾 Tennis" })
        .build();
    
    try built2.print(stdout);
    std.debug.print("\n", .{});
    
    // Test with various double-width characters
    var box3 = boxy.new(allocator);
    var built3 = try box3
        .title("Width Test Collection")
        .set("Type", &[_][]const u8{ "Wave Dash", "Emoji", "ASCII", "Box Drawing", "Coffee", "Mixed" })
        .set("Character", &[_][]const u8{ "〜", "🎾", "A", "─", "☕", "A〜B" })
        .set("Expected Width", &[_][]const u8{ "2", "2", "1", "1", "2", "4" })
        .build();
    
    try built3.print(stdout);
}