/// Data transformation utilities for Boxy
///
/// This module handles all data transformations including:
/// - Converting between row and column orientations
/// - Spreadsheet mode transformations
/// - Combining and organizing sections

const std = @import("std");
const box = @import("box.zig");
const layout = @import("layout.zig");

const Section = box.Section;
const SectionType = box.SectionType;
const Orientation = layout.Orientation;
const Alignment = layout.Alignment;

/// Empty cell placeholder
pub const EMPTY_CELL: []const u8 = "";

/// Result of transforming columns to spreadsheet format
pub const SpreadsheetResult = struct {
    headers: Section,
    data: ?Section,
};

/// Transform row-oriented sections to column-oriented sections
pub fn rowsToColumns(
    allocator: std.mem.Allocator,
    row_sections: []const Section,
    spreadsheet_mode: bool,
    alignment: Alignment,
) ![]Section {
    if (row_sections.len == 0) {
        return allocator.alloc(Section, 0);
    }
    
    // Determine the number of columns needed
    const num_cols = if (spreadsheet_mode)
        row_sections[0].data.len + 1  // +1 for the row header column
    else
        row_sections[0].data.len + 1; // +1 for the header column
    
    var column_sections = try allocator.alloc(Section, num_cols);
    
    // Create column sections
    for (0..num_cols) |col_idx| {
        var col_headers = try allocator.alloc([]const u8, 1);
        var col_data = try allocator.alloc([]const u8, row_sections.len);
        
        if (spreadsheet_mode) {
            if (col_idx == 0) {
                col_headers[0] = row_sections[0].headers[0];
            } else {
                col_headers[0] = if (col_idx - 1 < row_sections[0].data.len)
                    row_sections[0].data[col_idx - 1]
                else
                    EMPTY_CELL;
            }
            
            // Fill column data from rows
            for (row_sections[1..], 0..) |row_section, row_idx| {
                if (col_idx == 0) {
                    col_data[row_idx] = row_section.headers[0];
                } else if (col_idx - 1 < row_section.data.len) {
                    col_data[row_idx] = row_section.data[col_idx - 1];
                } else {
                    col_data[row_idx] = EMPTY_CELL;
                }
            }
            
            const actual_data = col_data[0..row_sections.len - 1];
            column_sections[col_idx] = Section{
                .section_type = .data,
                .orientation = .columns,
                .headers = col_headers,
                .data = actual_data,
                .alignment = alignment,
            };
        } else {
            // Non-spreadsheet mode transformation
            if (col_idx == 0) {
                // First column contains row headers
                col_headers[0] = EMPTY_CELL; // Corner cell
                for (row_sections, 0..) |row_section, i| {
                    col_data[i] = row_section.headers[0];
                }
            } else {
                // Data columns
                col_headers[0] = try std.fmt.allocPrint(allocator, "Col{}", .{col_idx});
                for (row_sections, 0..) |row_section, i| {
                    col_data[i] = if (col_idx - 1 < row_section.data.len)
                        row_section.data[col_idx - 1]
                    else
                        EMPTY_CELL;
                }
            }
            
            column_sections[col_idx] = Section{
                .section_type = .data,
                .orientation = .columns,
                .headers = col_headers,
                .data = col_data,
                .alignment = alignment,
            };
        }
    }
    
    return column_sections;
}

/// Transform column sections to spreadsheet format (first column becomes headers)
pub fn columnsToSpreadsheet(
    allocator: std.mem.Allocator,
    column_sections: []const Section,
    alignment: Alignment,
) !SpreadsheetResult {
    if (column_sections.len == 0) {
        return SpreadsheetResult{
            .headers = undefined,
            .data = null,
        };
    }
    
    // First set becomes column headers
    const first_set = column_sections[0];
    
    // Column headers: first set's header + its data items
    var col_headers = try allocator.alloc([]const u8, 1 + first_set.data.len);
    col_headers[0] = first_set.headers[0];
    for (first_set.data, 0..) |item, i| {
        col_headers[i + 1] = item;
    }
    
    const headers_section = Section{
        .section_type = .headers,
        .orientation = .columns,
        .headers = col_headers,
        .data = &.{},
        .alignment = alignment,
    };
    
    // Process remaining sets as rows
    if (column_sections.len > 1) {
        const data_section = try createSpreadsheetData(
            allocator,
            column_sections[1..],
            col_headers,
            alignment,
        );
        return SpreadsheetResult{
            .headers = headers_section,
            .data = data_section,
        };
    }
    
    return SpreadsheetResult{
        .headers = headers_section,
        .data = null,
    };
}

/// Create data section for spreadsheet mode
fn createSpreadsheetData(
    allocator: std.mem.Allocator,
    data_sections: []const Section,
    col_headers: [][]const u8,
    alignment: Alignment,
) !Section {
    const num_rows = data_sections.len;
    const num_cols = col_headers.len;
    
    var all_data = try allocator.alloc([]const u8, num_rows * num_cols);
    
    for (data_sections, 0..) |section, row_idx| {
        // First column is the row header
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
            all_data[row_idx * num_cols + col_idx] = EMPTY_CELL;
        }
    }
    
    return Section{
        .section_type = .data,
        .orientation = .columns,
        .headers = col_headers,
        .data = all_data,
        .alignment = alignment,
    };
}

/// Combine multiple columns into a single data section
pub fn combineColumns(
    allocator: std.mem.Allocator,
    column_sections: []const Section,
    alignment: Alignment,
) !Section {
    if (column_sections.len == 0) {
        return Section{
            .section_type = .data,
            .orientation = .columns,
            .headers = &.{},
            .data = &.{},
            .alignment = alignment,
        };
    }
    
    // Collect all headers
    var headers = try allocator.alloc([]const u8, column_sections.len);
    for (column_sections, 0..) |col, i| {
        headers[i] = if (col.headers.len > 0) col.headers[0] else EMPTY_CELL;
    }
    
    // Find max rows across all columns
    var max_rows: usize = 0;
    for (column_sections) |col| {
        max_rows = @max(max_rows, col.data.len);
    }
    
    // Combine data in row-major order
    var combined_data = try allocator.alloc([]const u8, max_rows * column_sections.len);
    
    for (0..max_rows) |row| {
        for (column_sections, 0..) |col, col_idx| {
            const idx = row * column_sections.len + col_idx;
            combined_data[idx] = if (row < col.data.len) col.data[row] else EMPTY_CELL;
        }
    }
    
    return Section{
        .section_type = .data,
        .orientation = .columns,
        .headers = headers,
        .data = combined_data,
        .alignment = alignment,
    };
}

/// Combine headerless rows into a single table section
pub fn combineHeaderlessRows(
    allocator: std.mem.Allocator,
    headerless_sections: []const Section,
    alignment: Alignment,
) !Section {
    if (headerless_sections.len == 0) {
        return Section{
            .section_type = .data,
            .orientation = .columns,
            .headers = &.{},
            .data = &.{},
            .alignment = alignment,
        };
    }
    
    // Determine the number of columns from the first row
    const num_cols = headerless_sections[0].data.len;
    
    // Count total cells needed
    var total_cells: usize = 0;
    for (headerless_sections) |section| {
        total_cells += section.data.len;
    }
    
    // Flatten all rows into one data array
    var flat_data = try allocator.alloc([]const u8, total_cells);
    var idx: usize = 0;
    for (headerless_sections) |section| {
        for (section.data) |cell| {
            flat_data[idx] = cell;
            idx += 1;
        }
    }
    
    // Create empty headers for column count
    const empty_headers = try allocator.alloc([]const u8, num_cols);
    for (empty_headers) |*h| {
        h.* = EMPTY_CELL;
    }
    
    return Section{
        .section_type = .data,
        .orientation = .columns,
        .headers = empty_headers,
        .data = flat_data,
        .alignment = alignment,
    };
}