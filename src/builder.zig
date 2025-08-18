/// Builder pattern implementation for Boxy
///
/// This module provides the fluent builder interface for constructing
/// boxes with a clean, chainable API.

const std = @import("std");
const config = @import("config.zig");
const box = @import("box.zig");
const theme_mod = @import("theme.zig");
const layout = @import("layout.zig");
const presets = @import("presets.zig");
const transform = @import("transform.zig");

const BoxyBox = box.BoxyBox;
const BoxyConfig = config.BoxyConfig;
const Section = box.Section;
const SectionType = box.SectionType;

/// Size presets for common padding configurations
pub const SizePreset = enum {
    compact,   // No padding
    comfort,   // Default padding (1)
    spacious,  // Extra padding (2)
};

/// Main builder for creating boxes with a fluent interface
pub const BoxyBuilder = struct {
    allocator: std.mem.Allocator,
    arena: *std.heap.ArenaAllocator,  // Arena for all builder allocations
    arena_allocator: std.mem.Allocator,  // Pre-computed allocator from arena
    config: BoxyConfig,
    sections: std.ArrayList(Section),
    
    // ===== Memory helpers to reduce repetition =====
    
    /// Duplicate a string in the arena
    fn dupe(self: *BoxyBuilder, text: []const u8) []u8 {
        return self.arena_allocator.dupe(u8, text) catch unreachable;
    }
    
    /// Allocate an array in the arena
    fn alloc(self: *BoxyBuilder, comptime T: type, n: usize) []T {
        return self.arena_allocator.alloc(T, n) catch unreachable;
    }
    
    /// Append a section
    fn addSection(self: *BoxyBuilder, section: Section) void {
        self.sections.append(section) catch unreachable;
    }
    
    // ===== Public API =====
    
    /// Initialize a new builder
    pub fn init(allocator: std.mem.Allocator) BoxyBuilder {
        // Create arena on heap so we can get a stable pointer
        const arena = allocator.create(std.heap.ArenaAllocator) catch unreachable;
        arena.* = std.heap.ArenaAllocator.init(allocator);
        const arena_allocator = arena.allocator();
        
        return .{
            .allocator = allocator,
            .arena = arena,
            .arena_allocator = arena_allocator,
            .config = BoxyConfig.default(),
            .sections = std.ArrayList(Section).init(arena_allocator),
        };
    }
    
    /// Set the title of the box (can be multi-line)
    pub fn title(self: *BoxyBuilder, text: []const u8) *BoxyBuilder {
        const text_copy = self.dupe(text);
        const title_data = self.alloc([]const u8, 1);
        title_data[0] = text_copy;
        
        self.addSection(.{
            .section_type = .title,
            .orientation = self.config.orientation,
            .headers = &.{},
            .data = title_data,
            .alignment = self.config.alignment,
        });
        return self;
    }
    
    /// Set the orientation for data layout (columns or rows)
    pub fn orientation(self: *BoxyBuilder, orient: layout.Orientation) *BoxyBuilder {
        self.config.orientation = orient;
        return self;
    }
    
    /// Add raw data row without headers (for headerless tables)
    /// Each call adds one row to the table
    pub fn data(self: *BoxyBuilder, row: []const []const u8) *BoxyBuilder {
        const row_copy = self.alloc([]const u8, row.len);
        for (row, 0..) |cell, i| {
            row_copy[i] = self.dupe(cell);
        }
        
        self.addSection(.{
            .section_type = .data,
            .orientation = self.config.orientation,
            .headers = &.{},  // Empty headers = no header row
            .data = row_copy,
            .alignment = self.config.alignment,
        });
        
        return self;
    }
    
    /// Add a data set (interpreted based on orientation)
    pub fn set(self: *BoxyBuilder, header: []const u8, items: []const []const u8) *BoxyBuilder {
        const header_copy = self.dupe(header);
        const data_copy = self.alloc([]const u8, items.len);
        for (items, 0..) |item, i| {
            data_copy[i] = self.dupe(item);
        }
        
        // Create section with single header
        const headers_array = self.alloc([]const u8, 1);
        headers_array[0] = header_copy;
        
        self.addSection(.{
            .section_type = .data,
            .orientation = self.config.orientation,
            .headers = headers_array,
            .data = data_copy,
            .alignment = self.config.alignment,
        });
        
        return self;
    }
    
    /// Enable spreadsheet mode
    pub fn spreadsheet(self: *BoxyBuilder) *BoxyBuilder {
        self.config.spreadsheet_mode = true;
        return self;
    }
    
    /// Set the theme
    pub fn theme(self: *BoxyBuilder, box_theme: theme_mod.BoxyTheme) *BoxyBuilder {
        self.config.theme = box_theme;
        return self;
    }
    
    /// Use a preset style
    pub fn style(self: *BoxyBuilder, style_name: presets.StylePreset) *BoxyBuilder {
        self.config.theme = presets.getTheme(style_name);
        return self;
    }
    
    /// Set width constraint
    pub fn width(self: *BoxyBuilder, width_size: layout.Size) *BoxyBuilder {
        self.config.width = width_size;
        return self;
    }
    
    /// Set height constraint
    pub fn height(self: *BoxyBuilder, height_size: layout.Size) *BoxyBuilder {
        self.config.height = height_size;
        return self;
    }
    
    /// Set exact height
    pub fn heightExact(self: *BoxyBuilder, height_value: usize) *BoxyBuilder {
        self.config.height = .{ .exact = height_value };
        return self;
    }
    
    /// Set minimum height
    pub fn heightMin(self: *BoxyBuilder, height_value: usize) *BoxyBuilder {
        self.config.height = .{ .min = height_value };
        return self;
    }
    
    /// Set maximum height
    pub fn heightMax(self: *BoxyBuilder, height_value: usize) *BoxyBuilder {
        self.config.height = .{ .max = height_value };
        return self;
    }
    
    /// Set height range
    pub fn heightRange(self: *BoxyBuilder, min_height: usize, max_height: usize) *BoxyBuilder {
        self.config.height = .{ .range = .{ .min = min_height, .max = max_height } };
        return self;
    }
    
    /// Set cell padding
    pub fn cellPadding(self: *BoxyBuilder, padding: usize) *BoxyBuilder {
        self.config.cell_padding = padding;
        return self;
    }
    
    /// Set exact width (convenience method)
    pub fn exact(self: *BoxyBuilder, width_value: usize) *BoxyBuilder {
        self.config.width = .{ .exact = width_value };
        return self;
    }
    
    /// Set extra space distribution strategy
    pub fn extraSpaceStrategy(self: *BoxyBuilder, strategy: layout.ExtraSpaceStrategy) *BoxyBuilder {
        self.config.extra_space_strategy = strategy;
        return self;
    }
    
    /// Set minimum width
    pub fn min(self: *BoxyBuilder, width_value: usize) *BoxyBuilder {
        self.config.width = .{ .min = width_value };
        return self;
    }
    
    /// Set maximum width
    pub fn max(self: *BoxyBuilder, width_value: usize) *BoxyBuilder {
        self.config.width = .{ .max = width_value };
        return self;
    }
    
    /// Set width range
    pub fn range(self: *BoxyBuilder, min_width: usize, max_width: usize) *BoxyBuilder {
        self.config.width = .{ .range = .{ .min = min_width, .max = max_width } };
        return self;
    }
    
    /// Set text alignment
    pub fn alignment(self: *BoxyBuilder, align_value: layout.Alignment) *BoxyBuilder {
        self.config.alignment = align_value;
        return self;
    }
    
    /// Apply a size preset
    pub fn size(self: *BoxyBuilder, preset: SizePreset) *BoxyBuilder {
        switch (preset) {
            .compact => {
                self.config.cell_padding = 0;
            },
            .comfort => {
                self.config.cell_padding = 1;
            },
            .spacious => {
                self.config.cell_padding = 2;
            },
        }
        return self;
    }
    
    /// Add a canvas section
    pub fn canvas(self: *BoxyBuilder, canvas_width: usize, canvas_height: usize) *BoxyBuilder {
        self.addSection(.{
            .section_type = .canvas,
            .orientation = self.config.orientation,
            .headers = &.{},
            .data = &.{},
            .alignment = self.config.alignment,
            .canvas_width = canvas_width,
            .canvas_height = canvas_height,
        });
        return self;
    }
    
    /// Build the final box
    pub fn build(self: *BoxyBuilder) !BoxyBox {
        // Validate configuration first
        try self.config.validate();
        
        // Organize sections using the transform module
        const organized_sections = try self.organizeSections();
        
        // Transfer arena ownership to BoxyBox
        return BoxyBox.initWithArenaPtr(self.allocator, self.arena, self.config, organized_sections);
    }
    
    // ===== Private section organization =====
    
    /// Organize sections based on type and configuration
    fn organizeSections(self: *BoxyBuilder) !std.ArrayList(Section) {
        var organized = std.ArrayList(Section).init(self.arena_allocator);
        
        // Separate sections by type
        var title_sections = std.ArrayList(Section).init(self.arena_allocator);
        var column_sections = std.ArrayList(Section).init(self.arena_allocator);
        var headerless_sections = std.ArrayList(Section).init(self.arena_allocator);
        
        for (self.sections.items) |section| {
            switch (section.section_type) {
                .title, .canvas, .divider => try title_sections.append(section),
                .data => {
                    if (section.headers.len > 0) {
                        try column_sections.append(section);
                    } else {
                        try headerless_sections.append(section);
                    }
                },
                .headers => {},
            }
        }
        
        // Add title sections first
        for (title_sections.items) |section| {
            try organized.append(section);
        }
        
        // Process data sections
        if (column_sections.items.len > 0) {
            try self.processColumnSections(&organized, column_sections.items);
        } else if (headerless_sections.items.len > 0) {
            const combined = try transform.combineHeaderlessRows(
                self.arena_allocator,
                headerless_sections.items,
                self.config.alignment,
            );
            try organized.append(combined);
        }
        
        return organized;
    }
    
    /// Process column sections based on orientation and spreadsheet mode
    fn processColumnSections(self: *BoxyBuilder, organized: *std.ArrayList(Section), sections: []Section) !void {
        // Transform rows to columns if needed
        const working_sections = if (self.config.orientation == .rows)
            try transform.rowsToColumns(
                self.arena_allocator,
                sections,
                self.config.spreadsheet_mode,
                self.config.alignment,
            )
        else
            sections;
        
        if (self.config.spreadsheet_mode) {
            // Transform to spreadsheet format
            const result = try transform.columnsToSpreadsheet(
                self.arena_allocator,
                working_sections,
                self.config.alignment,
            );
            try organized.append(result.headers);
            if (result.data) |data_section| {
                try organized.append(data_section);
            }
        } else {
            // Normal column mode - combine into single section
            const combined = try transform.combineColumns(
                self.arena_allocator,
                working_sections,
                self.config.alignment,
            );
            
            // Split into headers and data sections
            if (combined.headers.len > 0) {
                try organized.append(.{
                    .section_type = .headers,
                    .orientation = self.config.orientation,
                    .headers = combined.headers,
                    .data = &.{},
                    .alignment = self.config.alignment,
                });
            }
            
            if (combined.data.len > 0) {
                try organized.append(.{
                    .section_type = .data,
                    .orientation = self.config.orientation,
                    .headers = combined.headers,
                    .data = combined.data,
                    .alignment = self.config.alignment,
                });
            }
        }
    }
};