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
    pub fn orientation(self: *BoxyBuilder, orient: layout.Orientation) *BoxyBuilder {
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
    pub fn theme(self: *BoxyBuilder, box_theme: theme_mod.BoxyTheme) *BoxyBuilder {
        self.config.theme = box_theme;
        return self;
    }
    
    /// Apply a built-in style preset
    pub fn style(self: *BoxyBuilder, style_name: presets.StylePreset) *BoxyBuilder {
        self.config.theme = presets.getTheme(style_name);
        return self;
    }
    
    /// Set exact, minimum, or maximum width
    pub fn width(self: *BoxyBuilder, width_size: layout.Size) *BoxyBuilder {
        self.config.width = width_size;
        return self;
    }
    
    /// Set exact, minimum, or maximum height  
    pub fn height(self: *BoxyBuilder, height_size: layout.Size) *BoxyBuilder {
        self.config.height = height_size;
        return self;
    }
    
    /// Set exact height for the box
    pub fn heightExact(self: *BoxyBuilder, height_value: usize) *BoxyBuilder {
        self.config.height = .{ .exact = height_value };
        return self;
    }
    
    /// Set minimum height for the box
    pub fn heightMin(self: *BoxyBuilder, height_value: usize) *BoxyBuilder {
        self.config.height = .{ .min = height_value };
        return self;
    }
    
    /// Set maximum height for the box
    pub fn heightMax(self: *BoxyBuilder, height_value: usize) *BoxyBuilder {
        self.config.height = .{ .max = height_value };
        return self;
    }
    
    /// Set height range (min and max) for the box
    pub fn heightRange(self: *BoxyBuilder, min_height: usize, max_height: usize) *BoxyBuilder {
        self.config.height = .{ .range = .{ .min = min_height, .max = max_height } };
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
    
    /// Set width range (min and max) for the box
    pub fn range(self: *BoxyBuilder, min_width: usize, max_width: usize) *BoxyBuilder {
        self.config.width = .{ .range = .{ .min = min_width, .max = max_width } };
        return self;
    }
    
    /// Set cell alignment (left, center, right)
    pub fn alignment(self: *BoxyBuilder, align_value: layout.Alignment) *BoxyBuilder {
        self.config.alignment = align_value;
        return self;
    }
    
    /// Apply a size preset for common use cases
    pub fn size(self: *BoxyBuilder, preset: SizePreset) *BoxyBuilder {
        switch (preset) {
            .compact => {
                self.config.padding = 0;
                self.config.cell_padding = 0;
            },
            .comfort => {
                self.config.padding = 1;
                self.config.cell_padding = 1;
            },
            .spacious => {
                self.config.padding = 2;
                self.config.cell_padding = 2;
            },
        }
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
    
    /// Build the final box (consumes the builder)
    pub fn build(self: *BoxyBuilder) !BoxyBox {
        // Validate configuration first
        try self.config.validate();
        
        // Organize sections
        const organized_sections = try self.organizeSections();
        
        // Transfer arena ownership to BoxyBox (pass the pointer)
        return BoxyBox.initWithArenaPtr(self.allocator, self.arena, self.config, organized_sections);
    }
    
    // ===== Private helper methods =====
    
    /// Organize sections based on type and configuration
    fn organizeSections(self: *BoxyBuilder) !std.ArrayList(Section) {
        var organized_sections = std.ArrayList(Section).init(self.arena_allocator);
        
        // Separate sections by type
        const separated = try self.separateSectionsByType();
        
        // Add title sections first
        for (separated.title_sections.items) |section| {
            try organized_sections.append(section);
        }
        
        // Process data sections based on configuration
        if (separated.has_columns) {
            try self.processColumnSections(&organized_sections, separated.column_sections);
        } else if (separated.has_headerless) {
            try self.processHeaderlessSections(&organized_sections, separated.headerless_sections);
        }
        
        return organized_sections;
    }
    
    const SeparatedSections = struct {
        title_sections: std.ArrayList(Section),
        column_sections: std.ArrayList(Section),
        headerless_sections: std.ArrayList(Section),
        has_columns: bool,
        has_headerless: bool,
    };
    
    /// Separate sections by their type for processing
    fn separateSectionsByType(self: *BoxyBuilder) !SeparatedSections {
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
        
        return .{
            .title_sections = title_sections,
            .column_sections = column_sections,
            .headerless_sections = headerless_sections,
            .has_columns = has_columns,
            .has_headerless = has_headerless,
        };
    }
    
    /// Process column sections based on orientation and spreadsheet mode
    fn processColumnSections(self: *BoxyBuilder, organized_sections: *std.ArrayList(Section), column_sections: std.ArrayList(Section)) !void {
        // If orientation is rows, transform the data first
        var working_sections = column_sections;
        if (self.config.orientation == .rows) {
            working_sections = try self.transformRowsToColumns(column_sections);
        }
        
        if (self.config.spreadsheet_mode) {
            // Spreadsheet mode: transform columns to rows with headers
            const transformed = try self.transformToSpreadsheet(working_sections);
            try organized_sections.append(transformed.headers);
            if (transformed.data) |data_section| {
                try organized_sections.append(data_section);
            }
        } else {
            // Normal column mode - organize into headers + data
            try self.processNormalColumns(organized_sections, working_sections);
        }
    }
    
    /// Process normal column layout (non-spreadsheet)
    fn processNormalColumns(self: *BoxyBuilder, organized_sections: *std.ArrayList(Section), working_sections: std.ArrayList(Section)) !void {
        var all_headers = std.ArrayList([]const u8).init(self.arena_allocator);
        var all_columns = std.ArrayList([]const []const u8).init(self.arena_allocator);
        
        for (working_sections.items) |section| {
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
            const combined_data = try self.combineColumnsIntoRows(all_columns.items);
            
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
    
    /// Combine columns into rows for rendering
    fn combineColumnsIntoRows(self: *BoxyBuilder, columns: []const []const []const u8) ![]const u8 {
        // Find the maximum number of rows
        var max_rows: usize = 0;
        for (columns) |col| {
            max_rows = @max(max_rows, col.len);
        }
        
        // Allocate space for all cells
        var combined_data = try self.arena_allocator.alloc([]const u8, max_rows * columns.len);
        
        // Fill in the data
        for (0..max_rows) |row| {
            for (columns, 0..) |col, col_idx| {
                const idx = row * columns.len + col_idx;
                if (row < col.len) {
                    combined_data[idx] = col[row];
                } else {
                    combined_data[idx] = "";  // Empty cell
                }
            }
        }
        
        return combined_data;
    }
    
    /// Process headerless sections
    fn processHeaderlessSections(self: *BoxyBuilder, organized_sections: *std.ArrayList(Section), headerless_sections: std.ArrayList(Section)) !void {
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
    
    /// Transform row sections to column sections when orientation is .rows
    fn transformRowsToColumns(self: *BoxyBuilder, row_sections: std.ArrayList(Section)) !std.ArrayList(Section) {
        // Implementation moved from boxy.zig
        var column_sections = std.ArrayList(Section).init(self.arena_allocator);
        
        if (row_sections.items.len == 0) return column_sections;
        
        // Determine the number of columns needed
        const num_cols = if (self.config.spreadsheet_mode)
            row_sections.items[0].data.len + 1  // +1 for the row header column
        else
            row_sections.items[0].data.len + 1; // +1 for the header column
        
        // Create column sections
        for (0..num_cols) |col_idx| {
            var col_headers = try self.arena_allocator.alloc([]const u8, 1);
            var col_data = try self.arena_allocator.alloc([]const u8, row_sections.items.len);
            
            if (self.config.spreadsheet_mode) {
                // Implementation details...
                if (col_idx == 0) {
                    col_headers[0] = row_sections.items[0].headers[0];
                } else {
                    col_headers[0] = if (col_idx - 1 < row_sections.items[0].data.len)
                        row_sections.items[0].data[col_idx - 1]
                    else
                        "";
                }
                
                // Rest of the implementation...
                for (row_sections.items[1..], 0..) |row_section, row_idx| {
                    if (col_idx == 0) {
                        col_data[row_idx] = row_section.headers[0];
                    } else if (col_idx - 1 < row_section.data.len) {
                        col_data[row_idx] = row_section.data[col_idx - 1];
                    } else {
                        col_data[row_idx] = "";
                    }
                }
                
                const actual_data = col_data[0..row_sections.items.len - 1];
                try column_sections.append(.{
                    .section_type = .data,
                    .orientation = .columns,
                    .headers = col_headers,
                    .data = actual_data,
                    .alignment = self.config.alignment,
                });
            } else {
                // Normal mode implementation...
                if (col_idx == 0) {
                    col_headers[0] = row_sections.items[0].headers[0];
                    
                    for (row_sections.items[1..], 0..) |row_section, row_idx| {
                        col_data[row_idx] = row_section.headers[0];
                    }
                    
                    const actual_data = col_data[0..row_sections.items.len - 1];
                    try column_sections.append(.{
                        .section_type = .data,
                        .orientation = .columns,
                        .headers = col_headers,
                        .data = actual_data,
                        .alignment = self.config.alignment,
                    });
                } else {
                    const data_idx = col_idx - 1;
                    col_headers[0] = if (data_idx < row_sections.items[0].data.len)
                        row_sections.items[0].data[data_idx]
                    else
                        "";
                    
                    for (row_sections.items[1..], 0..) |row_section, row_idx| {
                        col_data[row_idx] = if (data_idx < row_section.data.len)
                            row_section.data[data_idx]
                        else
                            "";
                    }
                    
                    const actual_data = col_data[0..row_sections.items.len - 1];
                    try column_sections.append(.{
                        .section_type = .data,
                        .orientation = .columns,
                        .headers = col_headers,
                        .data = actual_data,
                        .alignment = self.config.alignment,
                    });
                }
            }
        }
        
        return column_sections;
    }
    
    /// Transform column sections for spreadsheet mode
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
            const data_section = try self.createSpreadsheetDataSection(column_sections, col_headers);
            return .{ .headers = headers_section, .data = data_section };
        }
        
        return .{ .headers = headers_section, .data = null };
    }
    
    /// Create data section for spreadsheet mode
    fn createSpreadsheetDataSection(self: *BoxyBuilder, column_sections: std.ArrayList(Section), col_headers: []const u8) !Section {
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
        
        return Section{
            .section_type = .data,
            .orientation = self.config.orientation,
            .headers = col_headers,
            .data = all_data,
            .alignment = self.config.alignment,
        };
    }
};