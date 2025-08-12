const std = @import("std");
const boxy = @import("boxy");

pub fn main() !void {
    // Get allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a coffee invoice - let's use two separate boxes for now
    var builder = boxy.new(allocator);
    var box = try builder
        .title("☕ COFFEE INVOICE ☕")
        .style(.double)
        .cellPadding(1)
        // Items with headers
        .set("Item", &.{ 
            "Colombian Dark Roast",
            "Ethiopian Light", 
            "Espresso Blend",
            "Decaf House Blend",
            "",
            "",
            "",
            "",
            ""
        })
        .set("Qty", &.{ 
            "10 kg", 
            "15 kg", 
            "20 kg", 
            "5 kg",
            "",
            "",
            "",
            "",
            ""
        })
        .set("Price/kg", &.{ 
            "$12.50", 
            "$15.00", 
            "$14.00", 
            "$11.00",
            "",
            "Subtotal:",
            "Tax (8%):",
            "Shipping:",
            "TOTAL:"
        })
        .set("Total", &.{ 
            "$125.00", 
            "$225.00", 
            "$280.00", 
            "$55.00",
            "--------",
            "$685.00",
            "$54.80",
            "$15.00",
            "$754.80"
        })
        .build();
    defer box.deinit();

    // Print to stdout
    const stdout = std.io.getStdOut().writer();
    try box.print(stdout);
    
    std.debug.print("\n☕ Invoice generated successfully!\n", .{});
}