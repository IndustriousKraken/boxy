/// Global constants used throughout the Boxy library
///
/// This module centralizes all magic numbers and constants to improve
/// maintainability and make the codebase more self-documenting.

const std = @import("std");

/// Layout constants
pub const Layout = struct {
    /// Default width for columns when no content is available
    pub const DEFAULT_COLUMN_WIDTH = 10;
    
    /// Minimum width for displaying truncated text with ellipsis
    pub const MIN_TRUNCATE_WIDTH = 3;
    
    /// Default cell padding on each side
    pub const DEFAULT_CELL_PADDING = 1;
    
    /// Extra rows allocated for headers and padding  
    pub const EXTRA_ROW_BUFFER = 5;
    
    /// Default padding around box content
    pub const DEFAULT_BOX_PADDING = 1;
    
    /// Space reserved for borders in height calculation
    pub const BORDER_HEIGHT_RESERVE = 4; // Top + bottom + header divider + padding
    
    /// Minimum box width
    pub const MIN_BOX_WIDTH = 3;
    
    /// Minimum box height
    pub const MIN_BOX_HEIGHT = 3;
};

/// Rendering constants
pub const Render = struct {
    /// Maximum line length before wrapping
    pub const MAX_LINE_LENGTH = 4096;
    
    /// Buffer size for rendering operations
    pub const RENDER_BUFFER_SIZE = 8192;
    
    /// Default truncation indicator
    pub const DEFAULT_TRUNCATION_INDICATOR = "...";
    
    /// Maximum number of border lines
    pub const MAX_BORDER_LINES = 10;
    
    /// Title padding (spaces on each side)
    pub const TITLE_PADDING = 2;
    
    /// Section divider padding
    pub const DIVIDER_PADDING = 1;
};

/// Terminal constants
pub const Terminal = struct {
    /// Default terminal width if not detected
    pub const DEFAULT_WIDTH = 80;
    
    /// Default terminal height if not detected
    pub const DEFAULT_HEIGHT = 24;
    
    /// Maximum supported terminal width
    pub const MAX_WIDTH = 500;
    
    /// Maximum supported terminal height
    pub const MAX_HEIGHT = 200;
    
    /// ANSI escape sequences
    pub const ANSI = struct {
        pub const CLEAR_SCREEN = "\x1b[2J";
        pub const CURSOR_HOME = "\x1b[H";
        pub const CURSOR_HIDE = "\x1b[?25l";
        pub const CURSOR_SHOW = "\x1b[?25h";
        
        /// Move cursor to row, col (1-indexed)
        pub fn moveCursor(row: usize, col: usize) [16]u8 {
            var buf: [16]u8 = undefined;
            const slice = std.fmt.bufPrint(&buf, "\x1b[{};{}H", .{ row, col }) catch unreachable;
            var result: [16]u8 = undefined;
            @memcpy(result[0..slice.len], slice);
            @memset(result[slice.len..], 0);
            return result;
        }
    };
};

/// Unicode constants
pub const Unicode = struct {
    /// Maximum UTF-8 bytes per character
    pub const MAX_UTF8_BYTES = 4;
    
    /// Replacement character for invalid UTF-8
    pub const REPLACEMENT_CHAR = '?';
    
    /// Zero-width joiner
    pub const ZWJ = '\u{200D}';
    
    /// Variation selector-16 (emoji presentation)
    pub const VS16 = '\u{FE0F}';
};

/// Memory constants
pub const Memory = struct {
    /// Initial capacity for dynamic arrays
    pub const INITIAL_CAPACITY = 16;
    
    /// Growth factor for dynamic arrays
    pub const GROWTH_FACTOR = 2;
    
    /// Maximum allocation size (1GB)
    pub const MAX_ALLOCATION = 1024 * 1024 * 1024;
};

/// Theme constants
pub const Theme = struct {
    /// Maximum length for border characters
    pub const MAX_BORDER_LENGTH = 16;
    
    /// Default inner section separator
    pub const DEFAULT_SECTION_SEPARATOR = "=";
};

/// Error messages
pub const ErrorMessages = struct {
    pub const INVALID_WIDTH_RANGE = "Width range minimum must be less than or equal to maximum";
    pub const INVALID_HEIGHT_RANGE = "Height range minimum must be less than or equal to maximum";
    pub const INVALID_CANVAS_DIMENSIONS = "Canvas dimensions must be positive if specified";
    pub const ALLOCATION_FAILED = "Memory allocation failed";
    pub const UTF8_DECODE_ERROR = "Invalid UTF-8 sequence";
    pub const RENDER_BUFFER_OVERFLOW = "Render buffer overflow";
};