/// Factory pattern implementation for Boxy
///
/// This module provides factory functionality for creating multiple
/// boxes with consistent configuration.

const std = @import("std");
const config = @import("config.zig");
const builder = @import("builder.zig");

const BoxyConfig = config.BoxyConfig;
const BoxyBuilder = builder.BoxyBuilder;

/// Factory for creating multiple boxes with consistent configuration
pub const BoxyFactory = struct {
    allocator: std.mem.Allocator,
    base_config: BoxyConfig,
    
    pub fn init(allocator: std.mem.Allocator, factory_config: BoxyConfig) BoxyFactory {
        return .{
            .allocator = allocator,
            .base_config = factory_config,
        };
    }
    
    /// Create a new builder with the factory's base configuration
    pub fn new(self: *const BoxyFactory) BoxyBuilder {
        var new_builder = BoxyBuilder.init(self.allocator);
        new_builder.config = self.base_config;
        return new_builder;
    }
};