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
const theme = @import("theme.zig");
const box = @import("box.zig");
const canvas = @import("canvas.zig");
const layout = @import("layout.zig");
const render = @import("render.zig");
const presets = @import("presets.zig");

// Public exports
pub const BoxyTheme = theme.BoxyTheme;
pub const BoxyBox = box.BoxyBox;
pub const BoxyCanvas = canvas.BoxyCanvas;
pub const Orientation = layout.Orientation;
pub const Alignment = layout.Alignment;
pub const Size = layout.Size;
const Section = box.Section;  // Use the Section from box.zig
const SectionType = box.SectionType;

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
pub fn factory(allocator: std.mem.Allocator, config: BoxyConfig) BoxyFactory {
    return BoxyFactory.init(allocator, config);
}

/// Creates a terminal UI context for advanced positioning and layouts
///
/// This is for advanced users who want to create complex terminal UIs with
/// multiple positioned boxes. Returns a context that manages the terminal state.
pub fn terminal(allocator: std.mem.Allocator) !TerminalUI {
    return TerminalUI.init(allocator);
}

/// Main builder for creating boxes with a fluent interface
pub const BoxyBuilder = struct {
    allocator: std.mem.Allocator,
    arena: *std.heap.ArenaAllocator,  // Arena for all builder allocations
    arena_allocator: std.mem.Allocator,  // Pre-computed allocator from arena
    config: BoxyConfig,
    sections: std.ArrayList(Section),
    
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
        // Allocate in arena - no need to track for cleanup
        const text_copy = self.arena_allocator.dupe(u8, text) catch unreachable;
        const title_data = self.arena_allocator.alloc([]const u8, 1) catch unreachable;
        title_data[0] = text_copy;
        
        self.sections.append(.{
            .section_type = .title,
            .orientation = self.config.orientation,
            .headers = &.{},
            .data = title_data,
            .alignment = self.config.alignment,
        }) catch unreachable;
        return self;
    }
    
    /// Set the orientation for data layout (columns or rows)
    pub fn orientation(self: *BoxyBuilder, orient: Orientation) *BoxyBuilder {
        self.config.orientation = orient;
        return self;
    }
    
    /// Add raw data row without headers (for headerless tables)
    /// Each call adds one row to the table
    pub fn data(self: *BoxyBuilder, row: []const []const u8) *BoxyBuilder {
        // Copy the row data
        const row_copy = self.arena_allocator.alloc([]const u8, row.len) catch unreachable;
        for (row, 0..) |cell, i| {
            row_copy[i] = self.arena_allocator.dupe(u8, cell) catch unreachable;
        }
        
        // Store as a headerless data row (will be combined in build)
        self.sections.append(.{
            .section_type = .data,
            .orientation = self.config.orientation,
            .headers = &.{},  // Empty headers = no header row
            .data = row_copy,
            .alignment = self.config.alignment,
        }) catch unreachable;
        
        return self;
    }
    
    /// Add a data set (interpreted based on orientation)
    pub fn set(self: *BoxyBuilder, header: []const u8, items: []const []const u8) *BoxyBuilder {
        // Store column data - all in arena, no tracking needed
        const header_copy = self.arena_allocator.dupe(u8, header) catch unreachable;
        
        // Copy all data strings
        const data_copy = self.arena_allocator.alloc([]const u8, items.len) catch unreachable;
        for (items, 0..) |item, i| {
            data_copy[i] = self.arena_allocator.dupe(u8, item) catch unreachable;
        }
        
        // Create headers array
        const headers = self.arena_allocator.alloc([]const u8, 1) catch unreachable;
        headers[0] = header_copy;
        
        // Store as a data section
        self.sections.append(.{
            .section_type = .data,
            .orientation = self.config.orientation,
            .headers = headers,
            .data = data_copy,
            .alignment = self.config.alignment,
        }) catch unreachable;
        
        return self;
    }
    
    /// Enable spreadsheet mode with row and column headers
    pub fn spreadsheet(self: *BoxyBuilder) *BoxyBuilder {
        self.config.spreadsheet_mode = true;
        return self;
    }
    
    /// Apply a theme to the box
    pub fn theme(self: *BoxyBuilder, box_theme: BoxyTheme) *BoxyBuilder {
        self.config.theme = box_theme;
        return self;
    }
    
    /// Apply a built-in style preset
    pub fn style(self: *BoxyBuilder, style_name: presets.StylePreset) *BoxyBuilder {
        self.config.theme = presets.getTheme(style_name);
        return self;
    }
    
    
    /// Set exact, minimum, or maximum width
    pub fn width(self: *BoxyBuilder, size: Size) *BoxyBuilder {
        self.config.width = size;
        return self;
    }
    
    /// Set exact, minimum, or maximum height  
    pub fn height(self: *BoxyBuilder, size: Size) *BoxyBuilder {
        self.config.height = size;
        return self;
    }
    
    /// Set padding for table cells
    pub fn cellPadding(self: *BoxyBuilder, padding: usize) *BoxyBuilder {
        self.config.cell_padding = padding;
        return self;
    }
    
    /// Set exact width for the box
    pub fn exact(self: *BoxyBuilder, width_value: usize) *BoxyBuilder {
        self.config.width = .{ .exact = width_value };
        return self;
    }
    
    /// Set strategy for distributing extra space when width is constrained
    /// If not set, defaults to .first for spreadsheet mode, .last for others
    pub fn extraSpaceStrategy(self: *BoxyBuilder, strategy: layout.ExtraSpaceStrategy) *BoxyBuilder {
        self.config.extra_space_strategy = strategy;
        return self;
    }
    
    /// Set minimum width for the box
    pub fn min(self: *BoxyBuilder, width_value: usize) *BoxyBuilder {
        self.config.width = .{ .min = width_value };
        return self;
    }
    
    /// Set maximum width for the box
    pub fn max(self: *BoxyBuilder, width_value: usize) *BoxyBuilder {
        self.config.width = .{ .max = width_value };
        return self;
    }
    
    /// Set cell alignment (left, center, right)
    pub fn alignment(self: *BoxyBuilder, align_value: Alignment) *BoxyBuilder {
        self.config.alignment = align_value;
        return self;
    }
    
    /// Create a canvas section with specified dimensions
    pub fn canvas(self: *BoxyBuilder, canvas_width: usize, canvas_height: usize) *BoxyBuilder {
        // Create a canvas section - we'll actually create the canvas during build
        const canvas_section = Section{
            .section_type = .canvas,
            .orientation = self.config.orientation,
            .headers = &.{},
            .data = &.{},
            .alignment = self.config.alignment,
            .canvas_width = canvas_width,
            .canvas_height = canvas_height,
        };
        self.sections.append(canvas_section) catch unreachable;
        return self;
    }
    
    /// Transform column sections for spreadsheet mode
    /// First set becomes column headers, rest become rows with row headers
    fn transformToSpreadsheet(self: *BoxyBuilder, column_sections: std.ArrayList(Section)) !struct { headers: Section, data: ?Section } {
        if (column_sections.items.len == 0) {
            return .{ .headers = undefined, .data = null };
        }
        
        // First set becomes column headers (including the "Staff" label or similar)
        const first_set = column_sections.items[0];
        
        // Column headers: first set's header + its data items
        var col_headers = try self.arena_allocator.alloc([]const u8, 1 + first_set.data.len);
        col_headers[0] = first_set.headers[0]; // e.g., "Staff"
        for (first_set.data, 0..) |item, i| {
            col_headers[i + 1] = item; // e.g., "Mon", "Tue", etc.
        }
        
        const headers_section = Section{
            .section_type = .headers,
            .orientation = self.config.orientation,
            .headers = col_headers,
            .data = &.{},
            .alignment = self.config.alignment,
        };
        
        // Process remaining sets as rows
        if (column_sections.items.len > 1) {
            // Each subsequent set: header becomes row header, data becomes row data
            const num_data_rows = column_sections.items.len - 1;
            const num_cols = col_headers.len; // Including row header column
            
            var all_data = try self.arena_allocator.alloc([]const u8, num_data_rows * num_cols);
            
            for (column_sections.items[1..], 0..) |section, row_idx| {
                // First column is the row header (e.g., "Alice")
                all_data[row_idx * num_cols] = section.headers[0];
                
                // Rest of columns are the data
                for (section.data, 0..) |cell, col_idx| {
                    if (col_idx + 1 < num_cols) {
                        all_data[row_idx * num_cols + col_idx + 1] = cell;
                    } else {
                        break; // Too many data items for columns
                    }
                }
                
                // Fill any remaining columns with empty strings
                for (section.data.len + 1..num_cols) |col_idx| {
                    all_data[row_idx * num_cols + col_idx] = "";
                }
            }
            
            const data_section = Section{
                .section_type = .data,
                .orientation = self.config.orientation,
                .headers = col_headers,
                .data = all_data,
                .alignment = self.config.alignment,
            };
            
            return .{ .headers = headers_section, .data = data_section };
        }
        
        return .{ .headers = headers_section, .data = null };
    }

    /// Build the final box (consumes the builder)
    pub fn build(self: *BoxyBuilder) !BoxyBox {
        // Don't deinit anything here - we'll transfer the arena to BoxyBox
        
        var organized_sections = std.ArrayList(Section).init(self.arena_allocator);
        
        // Separate title/divider sections from data sections
        var title_sections = std.ArrayList(Section).init(self.arena_allocator);
        var column_sections = std.ArrayList(Section).init(self.arena_allocator);
        var headerless_sections = std.ArrayList(Section).init(self.arena_allocator);
        var has_columns = false;
        var has_headerless = false;
        
        for (self.sections.items) |section| {
            switch (section.section_type) {
                .title, .canvas, .divider => {
                    try title_sections.append(section);
                },
                .data => {
                    if (section.headers.len > 0) {
                        // This is a column from .set()
                        has_columns = true;
                        try column_sections.append(section);
                    } else {
                        // This is headerless data from .data()
                        has_headerless = true;
                        try headerless_sections.append(section);
                    }
                },
                .headers => {},
            }
        }
        
        // Add title sections first
        for (title_sections.items) |section| {
            try organized_sections.append(section);
        }
        
        // If we have columns, organize them into a table
        if (has_columns) {
            if (self.config.spreadsheet_mode) {
                // Spreadsheet mode: transform columns to rows with headers
                const transformed = try self.transformToSpreadsheet(column_sections);
                try organized_sections.append(transformed.headers);
                if (transformed.data) |data_section| {
                    try organized_sections.append(data_section);
                }
            } else {
                // Normal column mode - organize into headers + data
                var all_headers = std.ArrayList([]const u8).init(self.arena_allocator);
                var all_columns = std.ArrayList([]const []const u8).init(self.arena_allocator);
            
                for (column_sections.items) |section| {
                    // We know these are all data sections with headers
                    try all_headers.append(section.headers[0]);
                    try all_columns.append(section.data);
                }
            
                // If we have columns, create header and data sections
                if (all_headers.items.len > 0) {
                    // Add headers section
            try organized_sections.append(.{
                .section_type = .headers,
                .orientation = self.config.orientation,
                .headers = try self.arena_allocator.dupe([]const u8, all_headers.items),
                .data = &.{},
                .alignment = self.config.alignment,
            });
            
            // Combine columns into rows for data section
            const num_rows = blk: {
                var max_rows: usize = 0;
                for (all_columns.items) |col| {
                    max_rows = @max(max_rows, col.len);
                }
                break :blk max_rows;
            };
            
            var combined_data = try self.arena_allocator.alloc([]const u8, num_rows * all_columns.items.len);
            for (0..num_rows) |row| {
                for (all_columns.items, 0..) |col, col_idx| {
                    const idx = row * all_columns.items.len + col_idx;
                    if (row < col.len) {
                        combined_data[idx] = col[row];
                    } else {
                        combined_data[idx] = "";  // Empty cell
                    }
                }
            }
            
                    // Add combined data section
                    try organized_sections.append(.{
                        .section_type = .data,
                        .orientation = self.config.orientation,
                        .headers = try self.arena_allocator.dupe([]const u8, all_headers.items),
                        .data = combined_data,
                        .alignment = self.config.alignment,
                    });
                }
            }
        } else if (has_headerless) {
            // Combine all headerless rows into one table section
            // First, determine the number of columns from the first row
            const num_cols = if (headerless_sections.items.len > 0) 
                headerless_sections.items[0].data.len 
            else 0;
            
            // Count total cells needed
            var total_cells: usize = 0;
            for (headerless_sections.items) |section| {
                total_cells += section.data.len;
            }
            
            // Flatten all rows into one data array
            const flat_data = try self.arena_allocator.alloc([]const u8, total_cells);
            var idx: usize = 0;
            for (headerless_sections.items) |section| {
                for (section.data) |cell| {
                    flat_data[idx] = cell;
                    idx += 1;
                }
            }
            
            // Create empty headers for column count
            const empty_headers = try self.arena_allocator.alloc([]const u8, num_cols);
            for (empty_headers) |*h| {
                h.* = "";
            }
            
            // Add as single data section
            try organized_sections.append(.{
                .section_type = .data,
                .orientation = self.config.orientation,
                .headers = empty_headers,
                .data = flat_data,
                .alignment = self.config.alignment,
            });
        }
        
        // Transfer arena ownership to BoxyBox (pass the pointer)
        return BoxyBox.initWithArenaPtr(self.allocator, self.arena, self.config, organized_sections);
    }
};

/// Factory for creating multiple boxes with consistent configuration
pub const BoxyFactory = struct {
    allocator: std.mem.Allocator,
    base_config: BoxyConfig,
    
    pub fn init(allocator: std.mem.Allocator, config: BoxyConfig) BoxyFactory {
        return .{
            .allocator = allocator,
            .base_config = config,
        };
    }
    
    /// Create a new builder with the factory's base configuration
    pub fn new(self: *const BoxyFactory) BoxyBuilder {
        var builder = BoxyBuilder.init(self.allocator);
        builder.config = self.base_config;
        return builder;
    }
};

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
    
    /// Render all positioned boxes to the terminal
    pub fn render(self: *TerminalUI) !void {
        _ = self;
        // Implementation placeholder
    }
};

/// Configuration for a box
const BoxyConfig = struct {
    theme: BoxyTheme = presets.default_theme,
    orientation: Orientation = .columns,
    spreadsheet_mode: bool = false,
    width: Size = .{ .auto = {} },
    height: Size = .{ .auto = {} },
    padding: usize = 1,
    cell_padding: usize = 1,  // Padding inside table cells
    alignment: Alignment = .left,
    canvas_width: usize = 0,
    canvas_height: usize = 0,
    extra_space_strategy: ?layout.ExtraSpaceStrategy = null,  // null means auto-detect
    
    pub fn default() BoxyConfig {
        return .{};
    }
};


const PositionedBox = struct {
    box: BoxyBox,
    row: usize,
    col: usize,
};