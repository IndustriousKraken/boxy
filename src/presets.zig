/// Built-in themes and style presets for Boxy
///
/// This module contains pre-defined themes that users can apply to their boxes
/// for consistent, professional-looking output. Themes range from simple ASCII
/// to Unicode box-drawing characters to fun decorative styles.

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
    tribal,      // Because why not?
    minimal,     // Spaces only
    retro,       // Retro terminal: ▀ ▄ █ ▐
    festive,     // Holiday themed
    neon,        // Cyberpunk style
    wooden,      // Crate-like: [=] style
    grid,        // Full grid with row dividers
    spreadsheet, // Light grid for data tables
};

/// Get a theme by preset name
pub fn getTheme(preset: StylePreset) theme.BoxyTheme {
    return switch (preset) {
        .simple   => simple_theme,
        .pipes    => pipes_theme,
        .rounded  => rounded_theme,
        .double   => double_theme,
        .bold     => bold_theme,
        .dotted   => dotted_theme,
        .ascii    => ascii_theme,
        .tribal   => tribal_theme,
        .minimal  => minimal_theme,
        .retro    => retro_theme,
        .festive  => festive_theme,
        .neon     => neon_theme,
        .wooden   => wooden_theme,
        .grid     => grid_theme,
        .spreadsheet => spreadsheet_theme,
    };
}

/// Default theme (used when no theme is specified)
pub const default_theme = pipes_theme;

/// Simple ASCII theme using basic characters
pub const simple_theme = theme.BoxyTheme{
    .h_border = "-",
    .v_border = "|",
    .tl = "+",
    .tr = "+",
    .bl = "+",
    .br = "+",
    .inner = .{
        .h = "-",
        .v = "|",
        .section = "-",
        .cross = "+",
        .t_down = "+",
        .t_up = "+",
        .t_right = "+",
        .t_left = "+",
    },
    .junction = .{
        .top = "+",
        .bottom = "+",
        .left = "+",
        .right = "+",
    },
};

/// Classic pipes theme (the example from README)
pub const pipes_theme = theme.BoxyTheme{
    .h_border = "═",
    .v_border = "║",
    .tl = "╔",
    .tr = "╗",
    .bl = "╚",
    .br = "╝",
    .inner = .{
        .h = "─",
        .v = "│",
        .section = "═",
        .cross = "┼",
        .t_down = "╤",
        .t_up = "╧",
        .t_right = "╟",
        .t_left = "╢",
    },
    .junction = .{
        .top = "╤",
        .bottom = "╧",
        .left = "╠",
        .right = "╣",
    },
};

/// Rounded corners theme
pub const rounded_theme = theme.BoxyTheme{
    .h_border = "─",
    .v_border = "│",
    .tl = "╭",
    .tr = "╮",
    .bl = "╰",
    .br = "╯",
    .inner = .{
        .h = "─",
        .v = "│",
        .section = "─",
        .cross = "┼",
        .t_down = "┬",
        .t_up = "┴",
        .t_right = "├",
        .t_left = "┤",
    },
    .junction = .{
        .top = "┬",
        .bottom = "┴",
        .left = "├",
        .right = "┤",
    },
};

/// Double line theme
pub const double_theme = theme.BoxyTheme{
    .h_border = "═",
    .v_border = "║",
    .tl = "╔",
    .tr = "╗",
    .bl = "╚",
    .br = "╝",
    .inner = .{
        .h = "═",
        .v = "║",
        .section = "═",
        .cross = "╬",
        .t_down = "╦",
        .t_up = "╩",
        .t_right = "╠",
        .t_left = "╣",
    },
    .junction = .{
        .top = "╦",
        .bottom = "╩",
        .left = "╠",
        .right = "╣",
    },
};

/// Bold line theme
pub const bold_theme = theme.BoxyTheme{
    .h_border = "━",
    .v_border = "┃",
    .tl = "┏",
    .tr = "┓",
    .bl = "┗",
    .br = "┛",
    .inner = .{
        .h = "━",
        .v = "┃",
        .section = "━",
        .cross = "╋",
        .t_down = "┳",
        .t_up = "┻",
        .t_right = "┣",
        .t_left = "┫",
    },
    .junction = .{
        .top = "┳",
        .bottom = "┻",
        .left = "┣",
        .right = "┫",
    },
};

/// Dotted theme
pub const dotted_theme = theme.BoxyTheme{
    .h_border = "⋯",
    .v_border = "⋮",
    .tl = "·",
    .tr = "·",
    .bl = "·",
    .br = "·",
    .inner = .{
        .h = "⋯",
        .v = "⋮",
        .section = "⋯",
        .cross = "·",
        .t_down = "·",
        .t_up = "·",
        .t_right = "·",
        .t_left = "·",
    },
    .junction = .{
        .top = "·",
        .bottom = "·",
        .left = "·",
        .right = "·",
    },
};

/// Pure ASCII theme (no extended characters)
pub const ascii_theme = theme.BoxyTheme{
    .h_border = "=",
    .v_border = "||\n||", // Same # characters on each line, use empty spaces. 
    .tl = "++",
    .tr = "++",
    .bl = "++",
    .br = "++",
    .inner = .{
        .h = "-",
        .v = "|\n|",
        .section = "=",
        .cross = "+",
        .t_down = "+",
        .t_up = "+",
        .t_right = "+",
        .t_left = "+",
    },
    .junction = .{
        .top    = "+",
        .bottom = "+",
        .left   = "||",
        .right  = "||",
    },
};

/// Ancestors, hear me!
pub const tribal_theme = theme.BoxyTheme{
    .h_border = "=-=",
    .v_border = "\\/\n/\\", // Same # characters on each line, use empty spaces. 
    .tl = "oo",
    .tr = "oo",
    .bl = "oo",
    .br = "oo",
    .inner = .{
        .h = "…",
        .v = "::\n::",
        .section = "…",
        .cross   = "::",
        .t_down  = "::",
        .t_up    = "::",
        .t_right = "…",
        .t_left  = "…",
    },
    .junction = .{
        .top    = "✴",
        .bottom = "✴",
        .left   = "oo",
        .right  = "oo",
    },
};

/// Minimal theme (mostly spaces)
pub const minimal_theme = theme.BoxyTheme{
    .h_border = " ",
    .v_border = " ",
    .tl = " ",
    .tr = " ",
    .bl = " ",
    .br = " ",
    .inner = .{
        .h = " ",
        .v = " ",
        .section = "-",
        .cross = " ",
        .t_down = " ",
        .t_up = " ",
        .t_right = " ",
        .t_left = " ",
    },
    .junction = .{
        .top = " ",
        .bottom = " ",
        .left = " ",
        .right = " ",
    },
};

/// Retro terminal theme
pub const retro_theme = theme.BoxyTheme{
    .top = "▀",
    .bottom = "▄",
    .left = "▌",
    .right = "▐",
    .tl = "▛",
    .tr = "▜",
    .bl = "▙",
    .br = "▟",
    .inner = .{
        .h = "─",
        .v = "│",
        .section = "═",
        .cross = "┼",
    },
    .junction = .{
        .top = "▀",
        .bottom = "▄",
        .left = "▌",
        .right = "▐",
    },
};

/// Festive/holiday theme
pub const festive_theme = theme.BoxyTheme{
    .h_border = "~*~",
    .v_border = "║",
    .tl = "◢",
    .tr = "◣",
    .bl = "◥",
    .br = "◤",
    .inner = .{
        .h = "~",
        .v = "|",
        .section = "~*~",
        .cross = "*",
    },
    .junction = .{
        .top = "*",
        .bottom = "*",
        .left = "*",
        .right = "*",
    },
};

/// Neon/cyberpunk theme
pub const neon_theme = theme.BoxyTheme{
    .h_border = "◊◊◊",
    .v_border = "◊\n◊",
    .tl = "◊",
    .tr = "◊",
    .bl = "◊",
    .br = "◊",
    .inner = .{
        .h = "─",
        .v = "│",
        .section = "═",
        .cross = "◊",
    },
    .junction = .{
        .top = "◊",
        .bottom = "◊",
        .left = "◊",
        .right = "◊",
    },
};

/// Wooden crate theme
pub const wooden_theme = theme.BoxyTheme{
    .h_border = "[=]",
    .v_border = "[|]",
    .tl = "[╔]",
    .tr = "[╗]",
    .bl = "[╚]",
    .br = "[╝]",
    .inner = .{
        .h = "---",
        .v = " | ",
        .section = "[=]",
        .cross = "-|-",
    },
    .junction = .{
        .top = "[T]",
        .bottom = "[⊥]",
        .left = "[├]",
        .right = "[┤]",
    },
};

/// Shadow box theme (3D effect)
pub const shadow_theme = theme.BoxyTheme{
    .top = "▀",
    .bottom = "▄▄▄░",
    .left = "█",
    .right = "█▓",
    .tl = "▛",
    .tr = "▜▓",
    .bl = "▙",
    .br = "▟░",
    .inner = .{
        .h = "─",
        .v = "│",
        .section = "═",
        .cross = "┼",
    },
};

/// Full grid theme (like a spreadsheet with all lines)
pub const grid_theme = theme.BoxyTheme{
    .h_border = "─",
    .v_border = "│",
    .tl = "┌",
    .tr = "┐",
    .bl = "└",
    .br = "┘",
    .inner = .{
        .h = "─",
        .v = "│",
        .section = "─",
        .cross = "┼",
        .t_down = "┬",
        .t_up = "┴",
        .t_right = "├",
        .t_left = "┤",
        // Row dividers for full grid
        .row_divider = "─",
        .row_cross = "┼",
        .row_left = "├",
        .row_right = "┤",
    },
    .junction = .{
        .top = "┬",
        .bottom = "┴",
        .left = "├",
        .right = "┤",
    },
};

/// Light spreadsheet theme (subtle grid lines)
pub const spreadsheet_theme = theme.BoxyTheme{
    .h_border = "═",
    .v_border = "║",
    .tl = "╔",
    .tr = "╗",
    .bl = "╚",
    .br = "╝",
    .inner = .{
        .h = "─",
        .v = "│",
        .section = "═",
        .cross = "┼",
        .t_down = "╤",  // Match double-line style
        .t_up = "╧",
        .t_right = "╟",
        .t_left = "╢",
        // Light row dividers
        .row_divider = "…",
        .row_cross = "│",
        .row_left = "║",
        .row_right = "║",
    },
    .junction = .{
        .top = "╤",     // Match double-line style
        .bottom = "╧",
        .left = "╠",
        .right = "╣",
    },
};