const std = @import("std");
const boxy = @import("boxy");

// Example usage:
//   var box = try boxy.new(allocator)
//       .title("My Box")
//       .exact(80)
//       .alignment(.center)
//       .set("Column1", &.{"Data"})
//       .build();

pub fn main() !void {
    // Get allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create inventory table
    var builder1 = boxy.new(allocator);
    var inventory = try builder1
        .title("Inventory")
        .exact(80)
        .style(.ascii)
        .alignment(.left)  // Center align cells
        .cellPadding(2)  // Nice padding for readability!
        .set("Weapons", &.{ "Silver Sword", "Iron Spear", "Jute Bolo" })
        .set("Armor", &.{ "Goblin Shield", "Obsidian Scale", "Leather Boots" })
        .set("Treasure", &.{ "Silver (175)", "Gold Orc Statue", "Ruby (SSS)" })
        .build();
    defer inventory.deinit();

    // Create store table
    var builder2 = boxy.new(allocator);
    var store = try builder2
        .title("Store")
        .exact(80)
        .style(.tribal)  // Use a different style to distinguish them!
        .alignment(.left)  // Right align cells
        .cellPadding(2)  // Nice padding for readability!
        .set("Weapons", &.{ "Goblin Dagger", "Oak Cudgel", "Darts (6)" })
        .set("Armor", &.{ "Tribal Shield", "Swampweed Coat of Revenge", "Lizard Scale Boots" })
        .set("Treasure", &.{ "Silver (301)", "Gold (5)", "Rosewood Icon" })
        .build();
    defer store.deinit();

    // Print to stdout
    const stdout = std.io.getStdOut().writer();
    try store.print(stdout);
    try inventory.print(stdout);
    
    std.debug.print("\nWould you like to trade those leather boots for some silver, sir?\n", .{});
}