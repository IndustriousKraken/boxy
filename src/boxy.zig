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
const layout_manager_mod = @import("layout_manager.zig");
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
pub const LayoutManager = layout_manager_mod.LayoutManager;
pub const BoxBounds = layout_manager_mod.BoxBounds;

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

/// Creates a layout manager for positioning multiple boxes
///
/// Use this to create complex layouts with multiple boxes side-by-side
/// Example:
/// ```zig
/// var layout = try boxy.layout(allocator, 80, 25);
/// defer layout.deinit();
/// layout.place(box1, 0, 0);
/// layout.place(box2, 0, 40);
/// const output = try layout.render();
/// ```
pub fn layout(allocator: std.mem.Allocator, width: usize, height: usize) !LayoutManager {
    return LayoutManager.init(allocator, width, height);
}