/// Content rendering functionality for Boxy
///
/// This module handles rendering of content within boxes, including
/// individual cells, content rows, and text alignment.

const std = @import("std");
const theme = @import("../theme.zig");
const layout = @import("../layout.zig");
const utils = @import("../utils.zig");

/// Rendering constants
const Constants = struct {
    /// Default ellipsis indicator for truncated text
    const ELLIPSIS = "...";
    
    /// Width of the ellipsis in display columns
    const ELLIPSIS_WIDTH = 3;
    
    /// Minimum width needed to show truncated text with ellipsis
    const MIN_TRUNCATE_WIDTH = 3;
    
    /// Fallback column width when not specified
    const FALLBACK_COLUMN_WIDTH = 10;
};

/// Render a single content row with borders (supports multi-line borders)
pub fn renderContentRow(writer: anytype, box_theme: theme.BoxyTheme, total_width: usize, content: []const u8) !void {
    const left_border = box_theme.getLeft();
    const right_border = box_theme.getRight();
    
    // Split borders into lines (use splitScalar to preserve spaces)
    var left_lines = std.mem.splitScalar(u8, left_border, '\n');
    var right_lines = std.mem.splitScalar(u8, right_border, '\n');
    
    // Count lines in borders
    var max_lines: usize = 1;
    var left_line_count: usize = 0;
    var right_line_count: usize = 0;
    while (left_lines.next()) |_| {
        left_line_count += 1;
    }
    while (right_lines.next()) |_| {
        right_line_count += 1;
    }
    max_lines = @max(left_line_count, right_line_count);
    if (max_lines == 0) max_lines = 1;
    
    // Reset iterators
    left_lines = std.mem.splitScalar(u8, left_border, '\n');
    right_lines = std.mem.splitScalar(u8, right_border, '\n');
    
    // Render each line
    for (0..max_lines) |line_idx| {
        // Get the border parts for this line
        const left_part = left_lines.next() orelse "";
        const right_part = right_lines.next() orelse "";
        
        // Calculate widths
        const left_width = utils.displayWidth(left_part);
        const right_width = utils.displayWidth(right_part);
        const content_width = total_width - left_width - right_width;
        
        // Write left border
        try writer.writeAll(left_part);
        
        // Write content or padding (only on first line)
        if (line_idx == 0) {
            const content_display_width = utils.displayWidth(content);
            if (content_display_width <= content_width) {
                try writer.writeAll(content);
                // Pad with spaces
                for (content_display_width..content_width) |_| {
                    try writer.writeByte(' ');
                }
            } else {
                // Content is too wide, need to truncate to fit display width
                var width_so_far: usize = 0;
                var byte_idx: usize = 0;
                
                while (byte_idx < content.len and width_so_far < content_width) {
                    const byte_count = utils.utf8ByteSequenceLength(content[byte_idx]);
                    const char_width: usize = if (byte_count == 4) 2 else 1;  // Simplified check
                    
                    if (width_so_far + char_width <= content_width) {
                        const end_idx = byte_idx + byte_count;
                        try writer.writeAll(content[byte_idx..end_idx]);
                        width_so_far += char_width;
                        byte_idx = end_idx;
                    } else {
                        break;
                    }
                }
                
                // Pad remaining space
                for (width_so_far..content_width) |_| {
                    try writer.writeByte(' ');
                }
            }
        } else {
            // Subsequent lines get spaces
            for (0..content_width) |_| {
                try writer.writeByte(' ');
            }
        }
        
        // Write right border
        try writer.writeAll(right_part);
        try writer.writeByte('\n');
    }
}

/// Render a single cell with proper alignment and padding
pub fn renderCell(writer: anytype, text: []const u8, width: usize, alignment: layout.Alignment) !void {
    const text_display_width = utils.displayWidth(text);
    
    // Handle text that's too wide
    if (text_display_width > width) {
        // Need to truncate
        if (width < Constants.MIN_TRUNCATE_WIDTH) {
            // Width too small even for ellipsis, just fill with spaces
            for (0..width) |_| {
                try writer.writeByte(' ');
            }
            return;
        }
        
        // Truncate and add ellipsis
        const available_for_text = width - Constants.ELLIPSIS_WIDTH;
        var current_width: usize = 0;
        var byte_idx: usize = 0;
        
        while (byte_idx < text.len and current_width < available_for_text) {
            const byte_count = utils.utf8ByteSequenceLength(text[byte_idx]);
            const char_width: usize = if (byte_count == 4) 2 else 1;
            
            if (current_width + char_width <= available_for_text) {
                try writer.writeAll(text[byte_idx..byte_idx + byte_count]);
                current_width += char_width;
                byte_idx += byte_count;
            } else {
                break;
            }
        }
        
        // Add ellipsis
        try writer.writeAll(Constants.ELLIPSIS);
        return;
    }
    
    // Text fits within width, apply alignment
    const padding_needed = width - text_display_width;
    
    switch (alignment) {
        .left => {
            try writer.writeAll(text);
            for (0..padding_needed) |_| {
                try writer.writeByte(' ');
            }
        },
        .right => {
            for (0..padding_needed) |_| {
                try writer.writeByte(' ');
            }
            try writer.writeAll(text);
        },
        .center => {
            const left_padding = padding_needed / 2;
            const right_padding = padding_needed - left_padding;
            
            for (0..left_padding) |_| {
                try writer.writeByte(' ');
            }
            try writer.writeAll(text);
            for (0..right_padding) |_| {
                try writer.writeByte(' ');
            }
        },
    }
}