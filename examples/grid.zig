const std = @import("std");
const boxy = @import("boxy");

pub fn main() !void {
    // Get allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // First, show a data table without row dividers (default)
    var builder1 = boxy.new(allocator);
    var no_grid = try builder1
        .title("Sales Data - No Grid")
        .set("Product", &.{ "Laptop", "Mouse", "Keyboard", "Monitor", "Cable" })
        .set("Q1", &.{ "120", "450", "230", "89", "670" })
        .set("Q2", &.{ "135", "490", "195", "92", "720" })
        .set("Q3", &.{ "142", "503", "210", "97", "695" })
        .set("Q4", &.{ "158", "521", "225", "103", "750" })
        .style(.rounded)
        .build();
    defer no_grid.deinit();

    // Print to stdout
    const stdout = std.io.getStdOut().writer();
    try no_grid.print(stdout);
    
    std.debug.print("\n\n", .{});
    
    // Now with full grid theme (row dividers between each row)
    var builder2 = boxy.new(allocator);
    var full_grid = try builder2
        .title("Sales Data - Full Grid")
        .set("Product", &.{ "Laptop", "Mouse", "Keyboard", "Monitor", "Cable" })
        .set("Q1", &.{ "120", "450", "230", "89", "670" })
        .set("Q2", &.{ "135", "490", "195", "92", "720" })
        .set("Q3", &.{ "142", "503", "210", "97", "695" })
        .set("Q4", &.{ "158", "521", "225", "103", "750" })
        .style(.grid)  // Full grid with row dividers!
        .build();
    defer full_grid.deinit();
    
    try full_grid.print(stdout);
    
    std.debug.print("\n\n", .{});
    
    // And with light spreadsheet theme (subtle dots between rows)
    var builder3 = boxy.new(allocator);
    var spreadsheet = try builder3
        .title("Sales Data - Spreadsheet Style")
        .spreadsheet()  // Spreadsheet mode
        .set("Product", &.{ "Q1", "Q2", "Q3", "Q4", "Total" })
        .set("Laptop", &.{ "120", "135", "142", "158", "555" })
        .set("Mouse", &.{ "450", "490", "503", "521", "1964" })
        .set("Keyboard", &.{ "230", "195", "210", "225", "860" })
        .set("Monitor", &.{ "89", "92", "97", "103", "381" })
        .set("Cable", &.{ "670", "720", "695", "750", "2835" })
        .style(.spreadsheet)  // Light grid with dots
        .exact(80)
        .build();
    defer spreadsheet.deinit();
    
    try spreadsheet.print(stdout);
    
    std.debug.print("\n\nRow dividers help track data across wide tables!\n", .{});
}