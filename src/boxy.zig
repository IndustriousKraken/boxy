/// Boxy - A delightful library for creating beautiful text boxes in the terminal
/// 
/// This is the main entry point for the Boxy library. Import this module to get
/// access to all Boxy functionality.
///
/// Basic usage:
/// ```zig
/// const boxy = @import("boxy");
/// 
/// var box = try boxy.new(allocator)
///     .title("Hello World")
///     .build();
/// defer box.deinit(allocator);
/// ```

const std = @import("std");

// Internal modules
const theme_mod = @import("theme.zig");
const box_mod = @import("box.zig");
const canvas_mod = @import("canvas.zig");
const layout_mod = @import("layout.zig");
const render_mod = @import("render.zig");
const presets_mod = @import("presets.zig");
const config_mod = @import("config.zig");
const builder_mod = @import("builder.zig");
const factory_mod = @import("factory.zig");

// Public exports
pub const BoxyTheme = theme_mod.BoxyTheme;
pub const BoxyBox = box_mod.BoxyBox;
pub const BoxyCanvas = canvas_mod.BoxyCanvas;
pub const Orientation = layout_mod.Orientation;
pub const Alignment = layout_mod.Alignment;
pub const Size = layout_mod.Size;
pub const SizePreset = builder_mod.SizePreset;
pub const BoxyBuilder = builder_mod.BoxyBuilder;
pub const BoxyFactory = factory_mod.BoxyFactory;
pub const BoxyConfig = config_mod.BoxyConfig;

/// Creates a new Boxy builder for constructing boxes with a fluent interface
/// 
/// This is the primary entry point for creating boxes. Returns a builder
/// that can be configured with various methods before calling .build()
pub fn new(allocator: std.mem.Allocator) BoxyBuilder {
    return BoxyBuilder.init(allocator);
}

/// Creates a factory with pre-configured settings for consistent box creation
///
/// Useful when you need to create multiple boxes with the same theme and settings
/// Example:
/// ```zig
/// const ErrorBox = boxy.factory(allocator, .{ .theme = RedTheme });
/// var box = try ErrorBox.new().title("Error!").build();
/// ```
pub fn factory(allocator: std.mem.Allocator, factory_config: BoxyConfig) BoxyFactory {
    return BoxyFactory.init(allocator, factory_config);
}

/// Creates a terminal UI context for advanced positioning and layouts
///
/// This is for advanced users who want to create complex terminal UIs with
/// multiple positioned boxes. Returns a context that manages the terminal state.
pub fn terminal(allocator: std.mem.Allocator) !TerminalUI {
    return TerminalUI.init(allocator);
}

/// Terminal UI context for advanced positioning
pub const TerminalUI = struct {
    allocator: std.mem.Allocator,
    width: usize,
    height: usize,
    boxes: std.ArrayList(PositionedBox),
    
    pub fn init(allocator: std.mem.Allocator) !TerminalUI {
        // Get terminal dimensions
        // Implementation placeholder
        return .{
            .allocator = allocator,
            .width = 80,  // Placeholder
            .height = 24, // Placeholder
            .boxes = std.ArrayList(PositionedBox).init(allocator),
        };
    }
    
    pub fn deinit(self: *TerminalUI) void {
        self.boxes.deinit();
    }
    
    /// Add a box at specific coordinates
    pub fn addBox(self: *TerminalUI, box: BoxyBox, row: usize, col: usize) !void {
        try self.boxes.append(.{
            .box = box,
            .row = row,
            .col = col,
        });
    }
    
    /// Render all positioned boxes to the terminal
    pub fn render(self: *TerminalUI, writer: anytype) !void {
        // Clear screen
        try writer.print("\x1b[2J\x1b[H", .{});
        
        // Render each box at its position
        for (self.boxes.items) |positioned| {
            // Position cursor
            try writer.print("\x1b[{};{}H", .{ positioned.row, positioned.col });
            // Render box
            try positioned.box.print(writer);
        }
    }
};

const PositionedBox = struct {
    box: BoxyBox,
    row: usize,
    col: usize,
};