const std = @import("std");
const boxy = @import("boxy");

pub fn main() !void {
    // Get allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create schedule table in spreadsheet mode
    var builder = boxy.new(allocator);
    var schedule = try builder
        .spreadsheet()  // Enable spreadsheet mode!
        .set("Staff", &.{ "Mon", "Tue", "Wed", "Thu", "Fri" })  // First set becomes column headers
        .set("Alice", &.{ "9-5", "9-5", "Off", "9-5", "9-5" })
        .set("Bob", &.{ "9-5", "Off", "12-8", "12-8", "Off" })
        .set("Carol", &.{ "Off", "9-5", "9-5", "Off", "12-8" })
        .set("Dave", &.{ "12-8", "12-8", "Off", "9-5", "9-5" })
        .style(.rounded)
        .build();
    defer schedule.deinit();

    // Print to stdout
    const stdout = std.io.getStdOut().writer();
    try schedule.print(stdout);
    
    std.debug.print("\n\nNow let's try with a different theme:\n\n", .{});
    
    // Create another schedule with pipes theme
    var builder2 = boxy.new(allocator);
    var schedule2 = try builder2
        .title("Weekly Schedule")
        .spreadsheet()
        .set("Staff", &.{ "Mon", "Tue", "Wed", "Thu", "Fri" })
        .set("Alice", &.{ "9-5", "9-5", "Off", "9-5", "9-5" })
        .set("Bob", &.{ "9-5", "Off", "12-8", "12-8", "Off" })
        .style(.pipes)
        .build();
    defer schedule2.deinit();
    
    try schedule2.print(stdout);
}