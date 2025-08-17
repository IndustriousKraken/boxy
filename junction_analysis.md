# Junction Analysis - Where Inner Meets Outer

## Current Junctions Types

### 1. Section Divider (after title)
```
║     Title      ║
╠════════════════╣  <- junction.left/right
║ Data │ Data    ║
```

### 2. Header Divider (between headers and data)
```
║ Header │ Header ║
╠────────┼────────╣  <- junction.left/right (same as section!)
║ Data   │ Data   ║
```

### 3. Row Divider (between data rows)
```
║ Data │ Data ║
├──────┼──────┤  <- row_left/row_right
║ Data │ Data ║
```

## The Problem

We're using `junction.left/right` for BOTH section and header dividers, but `row_left/row_right` for row dividers. Why?

## Possible Design Approaches

### Option A: One Junction To Rule Them All
Use `junction.left/right` for ANY horizontal line meeting the border.
- PRO: Simple, consistent
- CON: Can't differentiate styles (what if you want ╠ for sections but ├ for rows?)

### Option B: Semantic Junctions
Have different junction types for different purposes:
- `junction.section_left/right` - for section dividers
- `junction.header_left/right` - for header dividers  
- `junction.row_left/right` - for row dividers
- PRO: Maximum flexibility
- CON: Complex, verbose

### Option C: Context-Based (Current Approach)
- `junction.*` - for "major" dividers (sections, headers)
- `row_*` - specifically for row dividers
- PRO: Distinguishes between structural dividers and data dividers
- CON: Inconsistent - why are sections and headers grouped but rows separate?

### Option D: Divider-Centric
Instead of junctions on the theme, have them on the divider types:
```zig
section_divider: struct {
    line: []const u8,
    left: []const u8,
    right: []const u8,
    cross: []const u8,
}
```
- PRO: Each divider type is self-contained
- CON: More verbose theme definitions

## Where would t_left/t_right be used?

These are for PARTIAL dividers within the content area:
```
║ Data │ Data │ Data ║
║      ├──────┤      ║  <- t_left and t_right for partial divider
║ Data │ Data │ Data ║
```

This is different from row dividers which span the full width and touch the borders.

## Question

Is the distinction between "section/header dividers" and "row dividers" meaningful enough to warrant separate junction characters? Or should we simplify?