const std = @import("std");
const boxy = @import("boxy");

pub fn main() !void {
    // Get allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a schedule table without headers
    // Each call to .data() adds a row
    var builder = boxy.new(allocator);
    var box = try builder
        .title("Weekly Schedule")
        .style(.rounded)
        .cellPadding(2)
        .data(&.{ "Mon", "Tue", "Wed", "Thu", "Fri" })
        .data(&.{ "9am", "10am", "9am", "11am", "9am" })
        .data(&.{ "Team", "Code", "Meet", "Code", "Review" })
        .build();
    defer box.deinit();

    // Print to stdout
    const stdout = std.io.getStdOut().writer();
    try box.print(stdout);
    
    std.debug.print("\nSchedule rendered successfully!\n", .{});
}