const std = @import("std");
const boxy = @import("boxy");

pub fn main() !void {
    // Get allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a gradebook in spreadsheet mode
    var builder = boxy.new(allocator);
    var gradebook = try builder
        .title("CS101 Gradebook - Fall 2024")
        .spreadsheet()  
        .set("Student", &.{ "Quiz 1", "Quiz 2", "Midterm", "Project", "Final" })
        .set("Alice Johnson", &.{ "95", "88", "92", "A", "89" })
        .set("Bob Smith", &.{ "78", "82", "75", "B+", "80" })
        .set("Carol Davis", &.{ "92", "94", "88", "A-", "91" })
        .set("Dave Wilson", &.{ "85", "79", "83", "B", "85" })
        .set("Eve Brown", &.{ "90", "93", "95", "A+", "94" })
        .style(.double)
        .cellPadding(1)
        .exact(80)
        .build();
    defer gradebook.deinit();

    // Print to stdout
    const stdout = std.io.getStdOut().writer();
    try gradebook.print(stdout);
    
    std.debug.print("\n\nSpreadsheet mode works great for tabular data with row headers!\n", .{});
}