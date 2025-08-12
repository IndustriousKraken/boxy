/// Utility functions for Boxy
///
/// This module contains helper functions for text manipulation, UTF-8 handling,
/// data organization, and other common operations used throughout the library.

const std = @import("std");

/// Center text within a specified width
pub fn centerText(allocator: std.mem.Allocator, text: []const u8, width: usize) ![]u8 {
    const text_display_width = displayWidth(text);
    
    if (text_display_width >= width) {
        // Text is too wide, just return it as-is
        return try allocator.dupe(u8, text);
    }
    
    const total_padding = width - text_display_width;
    const left_padding = total_padding / 2;
    const right_padding = total_padding - left_padding;
    
    // The result needs: left_padding spaces + text bytes + right_padding spaces
    const result_len = left_padding + text.len + right_padding;
    var result = try allocator.alloc(u8, result_len);
    
    // Fill left padding with spaces
    @memset(result[0..left_padding], ' ');
    
    // Copy text (keeping all its bytes)
    @memcpy(result[left_padding..left_padding + text.len], text);
    
    // Fill right padding with spaces
    @memset(result[left_padding + text.len..], ' ');
    
    return result;
}

/// Organize flat data into rows based on number of columns
pub fn organizeDataIntoRows(allocator: std.mem.Allocator, data: []const []const u8, num_columns: usize) !std.ArrayList([]const []const u8) {
    var rows = std.ArrayList([]const []const u8).init(allocator);
    
    if (num_columns == 0) return rows;
    
    const num_rows = (data.len + num_columns - 1) / num_columns;
    
    for (0..num_rows) |row| {
        const start = row * num_columns;
        const end = @min(start + num_columns, data.len);
        try rows.append(data[start..end]);
    }
    
    return rows;
}

/// Count UTF-8 characters (not bytes) in a string
pub fn utf8CharCount(text: []const u8) usize {
    var count: usize = 0;
    var i: usize = 0;
    
    while (i < text.len) {
        const byte_count = utf8ByteSequenceLength(text[i]);
        i += byte_count;
        count += 1;
    }
    
    return count;
}

/// Calculate display width of text (emojis count as 2 columns)
pub fn displayWidth(text: []const u8) usize {
    var width: usize = 0;
    var i: usize = 0;
    
    while (i < text.len) {
        const byte_count = utf8ByteSequenceLength(text[i]);
        
        // Most terminals display emojis as 2 columns
        // Box drawing characters are 1 column
        // The coffee emoji ☕ (U+2615) is E2 98 95 in UTF-8
        if (byte_count == 4) {
            width += 2;  // 4-byte sequences are typically emojis
        } else if (byte_count == 3) {
            // Check the actual bytes for common patterns
            if (text[i] == 0xEF and i + 2 < text.len) {
                // Check for variation selectors (zero-width)
                if (text[i + 1] == 0xB8 and (text[i + 2] == 0x8E or text[i + 2] == 0x8F)) {
                    // U+FE0E (text) and U+FE0F (emoji) variation selectors
                    width += 0;  // Zero-width modifiers
                } else {
                    width += 1;  // Other EF sequences
                }
            } else if (text[i] == 0xE2) {
                if (i + 2 < text.len) {
                    // E2 98 XX range includes coffee and other symbols
                    if (text[i + 1] == 0x98) {
                        // Check specifically for skull (E2 98 A0)
                        if (text[i + 2] == 0xA0) {
                            width += 1;  // Skull often displays as single-width
                        } else {
                            width += 2;  // Other emoji-like symbols
                        }
                    } else if (text[i + 1] >= 0x94 and text[i + 1] <= 0x97) {
                        width += 1;  // Box drawing characters
                    } else if (text[i + 1] >= 0x80 and text[i + 1] <= 0x8F) {
                        width += 1;  // Various symbols
                    } else {
                        width += 1;  // Default for E2 range
                    }
                } else {
                    width += 1;
                }
            } else {
                width += 1;  // Most 3-byte sequences are single width
            }
        } else {
            width += 1;  // ASCII and 2-byte characters
        }
        
        i += byte_count;
    }
    
    return width;
}

/// Get the byte length of a UTF-8 character sequence
pub fn utf8ByteSequenceLength(first_byte: u8) usize {
    if (first_byte < 0x80) return 1;
    if (first_byte < 0xE0) return 2;
    if (first_byte < 0xF0) return 3;
    return 4;
}

/// Truncate text to a specified number of UTF-8 characters
pub fn truncateUtf8(text: []const u8, max_chars: usize, indicator: []const u8) []const u8 {
    var char_count: usize = 0;
    var byte_index: usize = 0;
    
    while (byte_index < text.len and char_count < max_chars) {
        const byte_count = utf8ByteSequenceLength(text[byte_index]);
        byte_index += byte_count;
        char_count += 1;
    }
    
    if (byte_index >= text.len) {
        return text; // No truncation needed
    }
    
    // Need to truncate - account for indicator
    const indicator_chars = utf8CharCount(indicator);
    if (max_chars <= indicator_chars) {
        return indicator[0..@min(indicator.len, text.len)];
    }
    
    // Find truncation point
    const keep_chars = max_chars - indicator_chars;
    char_count = 0;
    byte_index = 0;
    
    while (byte_index < text.len and char_count < keep_chars) {
        const byte_count = utf8ByteSequenceLength(text[byte_index]);
        byte_index += byte_count;
        char_count += 1;
    }
    
    return text[0..byte_index]; // Should append indicator, but returning truncated for now
}

/// Split text into lines
pub fn splitLines(text: []const u8) std.mem.TokenIterator(u8, .scalar) {
    return std.mem.tokenizeScalar(u8, text, '\n');
}

/// Join lines with newline separator
pub fn joinLines(allocator: std.mem.Allocator, lines: []const []const u8) ![]u8 {
    if (lines.len == 0) return try allocator.alloc(u8, 0);
    
    // Calculate total size
    var total_size: usize = 0;
    for (lines, 0..) |line, i| {
        total_size += line.len;
        if (i < lines.len - 1) {
            total_size += 1; // newline
        }
    }
    
    var result = try allocator.alloc(u8, total_size);
    var pos: usize = 0;
    
    for (lines, 0..) |line, i| {
        @memcpy(result[pos..pos + line.len], line);
        pos += line.len;
        
        if (i < lines.len - 1) {
            result[pos] = '\n';
            pos += 1;
        }
    }
    
    return result;
}

/// Pad text to a specified width
pub fn padText(allocator: std.mem.Allocator, text: []const u8, width: usize, pad_char: u8) ![]u8 {
    if (text.len >= width) {
        return try allocator.dupe(u8, text[0..width]);
    }
    
    var result = try allocator.alloc(u8, width);
    @memcpy(result[0..text.len], text);
    @memset(result[text.len..], pad_char);
    
    return result;
}

/// Repeat a character or string to create a pattern
pub fn repeatPattern(allocator: std.mem.Allocator, pattern: []const u8, total_width: usize) ![]u8 {
    if (pattern.len == 0 or total_width == 0) {
        return try allocator.alloc(u8, 0);
    }
    
    var result = try allocator.alloc(u8, total_width);
    const full_repeats = total_width / pattern.len;
    const remainder = total_width % pattern.len;
    
    var pos: usize = 0;
    for (0..full_repeats) |_| {
        @memcpy(result[pos..pos + pattern.len], pattern);
        pos += pattern.len;
    }
    
    if (remainder > 0) {
        @memcpy(result[pos..pos + remainder], pattern[0..remainder]);
    }
    
    return result;
}

/// Strip ANSI escape codes from text (for measuring visible length)
pub fn stripAnsiCodes(allocator: std.mem.Allocator, text: []const u8) ![]u8 {
    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();
    
    var i: usize = 0;
    while (i < text.len) {
        if (i + 1 < text.len and text[i] == 0x1B and text[i + 1] == '[') {
            // Skip ANSI escape sequence
            i += 2;
            while (i < text.len and !isAnsiTerminator(text[i])) {
                i += 1;
            }
            if (i < text.len) i += 1; // Skip terminator
        } else {
            try result.append(text[i]);
            i += 1;
        }
    }
    
    return try result.toOwnedSlice();
}

/// Check if a character is an ANSI escape sequence terminator
fn isAnsiTerminator(char: u8) bool {
    return (char >= 'A' and char <= 'Z') or (char >= 'a' and char <= 'z');
}

/// Calculate visible width of text (accounting for ANSI codes and UTF-8)
pub fn visibleWidth(text: []const u8) !usize {
    const stripped = try stripAnsiCodes(std.heap.page_allocator, text);
    defer std.heap.page_allocator.free(stripped);
    return utf8CharCount(stripped);
}

/// Escape special characters for terminal output
pub fn escapeTerminal(allocator: std.mem.Allocator, text: []const u8) ![]u8 {
    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();
    
    for (text) |char| {
        switch (char) {
            '\x1B' => try result.appendSlice("\\e"),
            '\n' => try result.appendSlice("\\n"),
            '\r' => try result.appendSlice("\\r"),
            '\t' => try result.appendSlice("\\t"),
            else => try result.append(char),
        }
    }
    
    return try result.toOwnedSlice();
}