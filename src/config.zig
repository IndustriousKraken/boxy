/// Configuration types and structures for Boxy
///
/// This module contains all configuration-related types used throughout
/// the library, providing a centralized place for configuration management.

const std = @import("std");
const theme = @import("theme.zig");
const layout = @import("layout.zig");
const presets = @import("presets.zig");

/// Configuration for a box
pub const BoxyConfig = struct {
    theme: theme.BoxyTheme = presets.default_theme,
    orientation: layout.Orientation = .columns,
    spreadsheet_mode: bool = false,
    width: layout.Size = .{ .auto = {} },
    height: layout.Size = .{ .auto = {} },
    padding: usize = 1,
    cell_padding: usize = 1,  // Padding inside table cells
    alignment: layout.Alignment = .left,
    canvas_width: usize = 0,
    canvas_height: usize = 0,
    extra_space_strategy: ?layout.ExtraSpaceStrategy = null,  // null means auto-detect
    
    pub fn default() BoxyConfig {
        return .{};
    }
    
    /// Get the effective extra space strategy based on configuration
    pub fn getEffectiveExtraSpaceStrategy(self: BoxyConfig) layout.ExtraSpaceStrategy {
        if (self.extra_space_strategy) |strategy| {
            return strategy;
        }
        // Auto-detect based on mode
        return if (self.spreadsheet_mode)
            .first  // Spreadsheet: emphasize row headers
        else
            .last;  // Regular table: emphasize data columns
    }
    
    /// Validate the configuration
    pub fn validate(self: BoxyConfig) !void {
        // Ensure width constraints are logical
        switch (self.width) {
            .range => |r| {
                if (r.min > r.max) {
                    return error.InvalidWidthRange;
                }
            },
            else => {},
        }
        
        // Ensure height constraints are logical
        switch (self.height) {
            .range => |r| {
                if (r.min > r.max) {
                    return error.InvalidHeightRange;
                }
            },
            else => {},
        }
        
        // Canvas dimensions must be positive if set
        if (self.canvas_width > 0 and self.canvas_height == 0) {
            return error.InvalidCanvasDimensions;
        }
        if (self.canvas_height > 0 and self.canvas_width == 0) {
            return error.InvalidCanvasDimensions;
        }
    }
};

/// Factory configuration for creating multiple boxes with consistent settings
pub const FactoryConfig = struct {
    base_config: BoxyConfig,
    
    /// Create a new factory configuration with the given base config
    pub fn init(base: BoxyConfig) FactoryConfig {
        return .{ .base_config = base };
    }
    
    /// Apply factory defaults to a builder config
    pub fn apply(self: FactoryConfig, target: *BoxyConfig) void {
        target.* = self.base_config;
    }
};

/// Terminal UI configuration
pub const TerminalConfig = struct {
    width: usize = 80,
    height: usize = 24,
    use_color: bool = false,
    clear_screen: bool = true,
};