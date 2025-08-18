/// Built-in themes and style presets for Boxy - Systematic structure
///
/// This module contains pre-defined themes using the systematic structure
/// where all characters are aligned in columns for easy comparison

const theme = @import("theme.zig");

/// Available style presets
pub const StylePreset = enum {
    simple,      // Basic ASCII: - | + +
    pipes,       // Classic pipes: ═ ║ ╔ ╗ ╚ ╝
    rounded,     // Rounded corners: ─ │ ╭ ╮ ╰ ╯
    double,      // Double lines: ═ ║ ╔ ╗ ╚ ╝
    bold,        // Bold lines: ━ ┃ ┏ ┓ ┗ ┛
    dotted,      // Dotted style: ⋯ ⋮ 
    ascii,       // Pure ASCII: - | + +
    tribal,      // Decorative style
    minimal,     // Spaces only
    retro,       // Retro terminal: ▀ ▄ █ ▐
    festive,     // Holiday themed
    neon,        // Cyberpunk style
    wooden,      // Crate-like: [=] style
    grid,        // Full grid with row dividers
    spreadsheet, // Light grid for data tables
    shadow,      // BIOS style UTF shadows
};

/// Get a theme by preset name
pub fn getTheme(preset: StylePreset) theme.BoxyTheme {
    return switch (preset) {
        .simple      => simple_theme,
        .pipes       => pipes_theme,
        .rounded     => rounded_theme,
        .double      => double_theme,
        .bold        => bold_theme,
        .dotted      => dotted_theme,
        .ascii       => ascii_theme,
        .tribal      => tribal_theme,
        .minimal     => minimal_theme,
        .retro       => retro_theme,
        .festive     => festive_theme,
        .neon        => neon_theme,
        .wooden      => wooden_theme,
        .grid        => grid_theme,
        .spreadsheet => spreadsheet_theme,
        .shadow      => shadow_theme,
    };
}

/// Default theme (used when no theme is specified)
pub const default_theme = pipes_theme;

/// Simple ASCII theme using basic characters
/// Uses only ASCII characters: - | +
pub const simple_theme = theme.BoxyTheme{
    .vertical = .{
        .outer                      = "|",
        .column                     = "|",
    },
    .horizontal = .{
        .outer                      = "-",
        .section                    = "-",
        .header                     = "-",
        .row                        = null,
    },
    .junction = .{
        .outer_corner               = "+",
        
        .outer_section_t_left       = "+",
        .outer_section_t_right      = "+",
        .outer_header_t_left        = "+",
        .outer_header_t_right       = "+",
        
        .outer_column_t_up          = "+",
        .outer_column_t_down        = "+",
        
        .section_column_t_down      = "+",
        .header_column_cross        = "+",
    },
};

/// Classic pipes theme with double-line outer borders
/// Uses double lines for borders, single lines for inner dividers
pub const pipes_theme = theme.BoxyTheme{
    .vertical = .{
        .outer                      = "║",
        .column                     = "│",
    },
    .horizontal = .{
        .outer                      = "═",
        .section                    = "═",
        .header                     = "─",
        .row                        = null,
    },
    .junction = .{
        .outer_top_left             = "╔",
        .outer_top_right            = "╗",
        .outer_bottom_left          = "╚",
        .outer_bottom_right         = "╝",
        
        .outer_section_t_left       = "╣",
        .outer_section_t_right      = "╠",
        .outer_header_t_left        = "╢",
        .outer_header_t_right       = "╟",
        
        .outer_column_t_up          = "╧",
        .outer_column_t_down        = "╤",
        
        .section_column_t_down      = "╤",
        .header_column_cross        = "┼",
    },
};

/// Rounded corners theme with softer appearance
/// Uses single lines with rounded corners
pub const rounded_theme = theme.BoxyTheme{
    .vertical = .{
        .outer                      = "│",
        .column                     = "│",
    },
    .horizontal = .{
        .outer                      = "─",
        .section                    = "─",
        .header                     = "─",
        .row                        = null,
    },
    .junction = .{
        .outer_top_left             = "╭",
        .outer_top_right            = "╮",
        .outer_bottom_left          = "╰",
        .outer_bottom_right         = "╯",
        
        .outer_section_t_left       = "┤",
        .outer_section_t_right      = "├",
        .outer_header_t_left        = "┤",
        .outer_header_t_right       = "├",
        
        .outer_column_t_up          = "┴",
        .outer_column_t_down        = "┬",
        
        .section_column_t_down      = "┬",
        .header_column_cross        = "┼",
    },
};

/// Double line theme - all double lines
/// Uses double lines throughout
pub const double_theme = theme.BoxyTheme{
    .vertical = .{
        .outer                      = "║",
        .column                     = "║",
    },
    .horizontal = .{
        .outer                      = "═",
        .section                    = "═",
        .header                     = "═",
        .row                        = null,
    },
    .junction = .{
        .outer_top_left             = "╔",
        .outer_top_right            = "╗",
        .outer_bottom_left          = "╚",
        .outer_bottom_right         = "╝",
        
        .outer_section_t_left       = "╣",
        .outer_section_t_right      = "╠",
        .outer_header_t_left        = "╣",
        .outer_header_t_right       = "╠",
        
        .outer_column_t_up          = "╩",
        .outer_column_t_down        = "╦",
        
        .section_column_t_down      = "╦",
        .header_column_cross        = "╬",
    },
};

/// Bold line theme - heavy strokes
/// Uses bold/heavy box drawing characters
pub const bold_theme = theme.BoxyTheme{
    .vertical = .{
        .outer                      = "┃",
        .column                     = "┃",
    },
    .horizontal = .{
        .outer                      = "━",
        .section                    = "━",
        .header                     = "━",
        .row                        = null,
    },
    .junction = .{
        .outer_top_left             = "┏",
        .outer_top_right            = "┓",
        .outer_bottom_left          = "┗",
        .outer_bottom_right         = "┛",
        
        .outer_section_t_left       = "┫",
        .outer_section_t_right      = "┣",
        .outer_header_t_left        = "┫",
        .outer_header_t_right       = "┣",
        
        .outer_column_t_up          = "┻",
        .outer_column_t_down        = "┳",
        
        .section_column_t_down      = "┳",
        .header_column_cross        = "╋",
    },
};

/// Pure ASCII theme with double-thick borders
/// Uses multi-line borders for thickness effect
pub const ascii_theme = theme.BoxyTheme{
    .vertical = .{
        .outer                      = "||\n||",
        .column                     = "|\n|",
    },
    .horizontal = .{
        .outer                      = "==",
        .section                    = "==",
        .header                     = "--",
        .row                        = null,
    },
    .junction = .{
        .outer_corner               = "++",
        
        .outer_section_t_left       = "++",
        .outer_section_t_right      = "++",
        .outer_header_t_left        = "++",
        .outer_header_t_right       = "++",
        
        .outer_column_t_up          = "+",
        .outer_column_t_down        = "+",
        
        .section_column_t_down      = "+",
        .header_column_cross        = "+",
    },
};

/// Full grid theme with row dividers
/// Shows all grid lines including between data rows
pub const grid_theme = theme.BoxyTheme{
    .vertical = .{
        .outer                      = "│",
        .column                     = "│",
    },
    .horizontal = .{
        .outer                      = "─",
        .section                    = "─",
        .header                     = "─",
        .row                        = "─",
    },
    .junction = .{
        .outer_top_left             = "┌",
        .outer_top_right            = "┐",
        .outer_bottom_left          = "└",
        .outer_bottom_right         = "┘",
        
        .outer_section_t_left       = "┤",
        .outer_section_t_right      = "├",
        .outer_header_t_left        = "┤",
        .outer_header_t_right       = "├",
        .outer_row_t_left           = "┤",
        .outer_row_t_right          = "├",
        
        .outer_column_t_up          = "┴",
        .outer_column_t_down        = "┬",
        
        .section_column_t_down      = "┬",
        .header_column_cross        = "┼",
        .row_column_cross           = "┼",
    },
};

/// Spreadsheet theme with mixed styles
/// Double outer borders, single inner, light row dividers
pub const spreadsheet_theme = theme.BoxyTheme{
    .vertical = .{
        .outer                      = "║",
        .column                     = "│",
    },
    .horizontal = .{
        .outer                      = "═",
        .section                    = "═",
        .header                     = "─",
        .row                        = "…",
    },
    .junction = .{
        .outer_top_left             = "╔",
        .outer_top_right            = "╗",
        .outer_bottom_left          = "╚",
        .outer_bottom_right         = "╝",
        
        .outer_section_t_left       = "╣",
        .outer_section_t_right      = "╠",
        .outer_header_t_left        = "╢",
        .outer_header_t_right       = "╟",
        .outer_row_t_left           = "║",  // Row divider blends into border
        .outer_row_t_right          = "║",  // Row divider blends into border
        
        .outer_column_t_up          = "╧",
        .outer_column_t_down        = "╤",
        
        .section_column_t_down      = "╤",
        .header_column_cross        = "┼",
        .row_column_cross           = "│",  // Light - column continues through
    },
};

/// Dotted theme using Unicode dot characters
/// Creates a softer, less defined appearance
pub const dotted_theme = theme.BoxyTheme{
    .vertical = .{
        .outer                      = "⋮",
        .column                     = "⋮",
    },
    .horizontal = .{
        .outer                      = "⋯",
        .section                    = "⋯",
        .header                     = "⋯",
        .row                        = null,
    },
    .junction = .{
        .outer_corner               = "·",
        
        .outer_section_t_left       = "·",
        .outer_section_t_right      = "·",
        .outer_header_t_left        = "·",
        .outer_header_t_right       = "·",
        
        .outer_column_t_up          = "·",
        .outer_column_t_down        = "·",
        
        .section_column_t_down      = "·",
        .header_column_cross        = "·",
    },
};

/// Tribal theme with decorative patterns
/// Uses multi-line borders for a unique look
pub const tribal_theme = theme.BoxyTheme{
    .vertical = .{
        .outer                      = "\\/\n/\\",
        .column                     = "::\n::",
    },
    .horizontal = .{
        .outer                      = "=-=",
        .section                    = "=-=",
        .header                     = "…",
        .row                        = null,
    },
    .junction = .{
        .outer_corner               = "oo",
        
        .outer_section_t_left       = "✴✴",
        .outer_section_t_right      = "✴✴",
        .outer_header_t_left        = "::",
        .outer_header_t_right       = "::",
        
        .outer_column_t_up          = "✴✴",
        .outer_column_t_down        = "✴✴",
        
        .section_column_t_down      = "✴✴",
        .header_column_cross        = "……",
    },
};

/// Minimal theme - mostly spaces
/// For when you want structure without visual noise
pub const minimal_theme = theme.BoxyTheme{
    .vertical = .{
        .outer                      = " ",
        .column                     = " ",
    },
    .horizontal = .{
        .outer                      = " ",
        .section                    = "-",
        .header                     = " ",
        .row                        = null,
    },
    .junction = .{
        .outer_corner               = " ",
        
        .outer_section_t_left       = " ",
        .outer_section_t_right      = " ",
        .outer_header_t_left        = " ",
        .outer_header_t_right       = " ",
        
        .outer_column_t_up          = " ",
        .outer_column_t_down        = " ",
        
        .section_column_t_down      = " ",
        .header_column_cross        = " ",
    },
};

/// Retro terminal theme with block characters
/// Evokes old-school terminal aesthetics
pub const retro_theme = theme.BoxyTheme{
    .vertical = .{
        .outer_left                 = "▌",
        .outer_right                = "▐",
        .column                     = "│",
    },
    .horizontal = .{
        .outer_top                  = "▀",
        .outer_bottom                = "▄",
        .section                    = "═",
        .header                     = "─",
        .row                        = null,
    },
    .junction = .{
        .outer_top_left             = "▛",
        .outer_top_right            = "▜",
        .outer_bottom_left          = "▙",
        .outer_bottom_right         = "▟",
        
        .outer_section_t_left       = "▐",
        .outer_section_t_right      = "▌",
        .outer_header_t_left        = "▐",
        .outer_header_t_right       = "▌",
        
        .outer_column_t_up          = "▄",
        .outer_column_t_down        = "▀",
        
        .section_column_t_down      = "┬",
        .header_column_cross        = "┼",
    },
};

/// Festive/holiday theme with decorative elements
/// Fun and whimsical appearance
pub const festive_theme = theme.BoxyTheme{
    .vertical = .{
        .outer                      = "║",
        .column                     = "|",
    },
    .horizontal = .{
        .outer                      = "~*~",
        .section                    = "~*~",
        .header                     = "~",
        .row                        = null,
    },
    .junction = .{
        .outer_top_left             = "◢",
        .outer_top_right            = "◣",
        .outer_bottom_left          = "◥",
        .outer_bottom_right         = "◤",
        
        .outer_section_t_left       = "*",
        .outer_section_t_right      = "*",
        .outer_header_t_left        = "*",
        .outer_header_t_right       = "*",
        
        .outer_column_t_up          = "*",
        .outer_column_t_down        = "*",
        
        .section_column_t_down      = "*",
        .header_column_cross        = "*",
    },
};

/// Neon/cyberpunk theme with diamond patterns
/// Futuristic aesthetic with multi-line borders
pub const neon_theme = theme.BoxyTheme{
    .vertical = .{
        .outer                      = "◊\n◊",
        .column                     = "│\n│",
    },
    .horizontal = .{
        .outer                      = "◊◊◊",
        .section                    = "═",
        .header                     = "─",
        .row                        = null,
    },
    .junction = .{
        .outer_corner               = "◊",
        
        .outer_section_t_left       = "◊",
        .outer_section_t_right      = "◊",
        .outer_header_t_left        = "◊",
        .outer_header_t_right       = "◊",
        
        .outer_column_t_up          = "◊",
        .outer_column_t_down        = "◊",
        
        .section_column_t_down      = "◊",
        .header_column_cross        = "◊",
    },
};

/// Wooden crate theme with bracketed style
/// Gives a constructed, solid appearance
pub const wooden_theme = theme.BoxyTheme{
    .vertical = .{
        .outer                      = "[|]",
        .column                     = " | ",
    },
    .horizontal = .{
        .outer                      = "[=]",
        .section                    = "[=]",
        .header                     = "---",
        .row                        = null,
    },
    .junction = .{
        .outer_top_left             = "[╔]",
        .outer_top_right            = "[╗]",
        .outer_bottom_left          = "[╚]",
        .outer_bottom_right         = "[╝]",
        
        .outer_section_t_left       = "[┤]",
        .outer_section_t_right      = "[├]",
        .outer_header_t_left        = "[┤]",
        .outer_header_t_right       = "[├]",
        
        .outer_column_t_up          = "[⊥]",
        .outer_column_t_down        = "[T]",
        
        .section_column_t_down      = "[T]",
        .header_column_cross        = "-|-",
    },
};

const shadow_theme = theme.BoxyTheme{
    .vertical = .{
        .outer_left                 = "█",      // Solid left
        .outer_right                = "█░",     // Right with shadow
        .column                     = "│",
    },
    .horizontal = .{
        .outer_top                  = "▀",   
        .outer_bottom               = "▄\n░",    
        .section                    = "═",
        .header                     = "─",
        .row                        = null,
    },
    .junction = .{
        .outer_top_left             = "█",
        .outer_top_right            = "█ ",
        .outer_bottom_left          = "█\n ",  
        .outer_bottom_right         = "█░",    
        
        .outer_section_t_left       = "█░",
        .outer_section_t_right      = "█",
        .outer_header_t_left        = "█░",
        .outer_header_t_right       = "█",
        
        .outer_column_t_up          = "▄",
        .outer_column_t_down        = "▀",
        
        .section_column_t_down      = "╤",
        .header_column_cross        = "┼",
    },
};