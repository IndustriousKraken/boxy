# Boxy Implementation Plan

> **Last Updated**: 2025-08-14  
> **Status**: Active Development - Phases 1, 3, 4 Complete | Phase 2, 5 Partial | Canvas & Factory Implemented

## Core Philosophy
Boxy is a focused library that does ONE thing exceptionally well: creating beautiful text boxes for terminal applications. It is composable, not comprehensive - providing primitives that others can build upon rather than trying to be a complete framework.

## Architecture Overview

### 1. Core Data Structures

#### BoxyTheme
- **Purpose**: Defines the visual appearance of box borders
- **Key Design Decisions**:
  - Support both simple (h/v only) and complex (per-side) border definitions
  - Allow multi-line borders for 3D effects using '\n' separators
  - Pattern-based borders that repeat to fill space
  - Separate inner borders from outer borders for flexibility
  - Theme inheritance/composition for consistency

#### BoxyBox
- **Purpose**: The main container that holds content and applies styling
- **Key Design Decisions**:
  - Builder pattern for intuitive API
  - Lazy evaluation - only compute layout when .build() is called
  - Immutable after building (functional approach)
  - Separation of concerns: structure vs. style vs. content

#### BoxyCanvas
- **Purpose**: A drawable area within a box for dynamic content
- **Key Design Decisions**:
  - 2D array of u8 for direct character manipulation
  - Blit operations for efficient bulk updates
  - Separate refresh mechanism to avoid full redraws
  - Raw buffer access for power users

### 2. Layout Engine

#### Column/Row Orientation
- **Why**: Users think in terms of data sets, not pre-formatted tables
- **Implementation Strategy**:
  - Store data as provided (columns or rows)
  - Transform during rendering based on orientation setting
  - Handle ragged arrays gracefully (different lengths)
  - Auto-detect optimal layout when not specified

#### Sizing and Constraints
- **Flexible System**:
  - Exact: Fixed dimensions
  - Min/Max: Bounded flexibility
  - Auto: Content-driven sizing
- **Priority Order**:
  1. User-specified constraints
  2. Content requirements
  3. Terminal dimensions
  4. Default preferences

#### Text Alignment and Truncation
- **Per-cell Control**: Each cell can have its own alignment
- **Smart Truncation**: 
  - Customizable indicators ("...", "→", etc.)
  - Word-aware breaking when possible
  - Preserve important parts (start vs. end vs. middle)

### 3. Rendering Pipeline

#### Multi-pass Rendering
1. **Measure Pass**: Calculate required dimensions
2. **Layout Pass**: Assign positions and sizes
3. **Draw Pass**: Generate the actual output

#### Buffer Management
- **Why Not Direct Write**: 
  - Allows pre-computation and validation
  - Enables partial updates
  - Supports compositing multiple boxes
- **Implementation**:
  - Internal string buffer building
  - Efficient memory allocation strategies
  - Minimal copying during construction

### 4. API Design Principles

#### Progressive Disclosure
- **Level 1**: Simple presets that just work
  ```zig
  Boxy.simple(title, data)
  ```
- **Level 2**: Common customizations
  ```zig
  Boxy.new().title().style().build()
  ```
- **Level 3**: Full control
  ```zig
  Boxy.new().customBorder().canvas().getRawBuffer()
  ```

#### Fluent Interface
- **Why**: Readable, discoverable, composable
- **Key Decisions**:
  - Each method returns self for chaining
  - Clear method names that read like English
  - Consistent parameter patterns

#### Factory Pattern
- **Purpose**: Reusable configurations
- **Benefits**:
  - Team/app consistency
  - Reduced boilerplate
  - Semantic naming (ErrorBox, InfoBox)

### 5. Memory Management

#### Allocation Strategy
- **Arena Allocator Friendly**: 
  - Bulk allocations where possible
  - Clear ownership model
  - Predictable cleanup with defer

#### String Handling
- **Concerns**:
  - UTF-8 awareness for proper character counting
  - Efficient string building without excessive allocation
  - Handle multi-byte characters in truncation

### 6. Extensibility Points

#### Hooks and Callbacks
- **Not Event Handlers**: We don't handle input
- **Rendering Hooks**: 
  - Pre/post render callbacks
  - Custom cell renderers
  - Buffer access for modifications

#### Coordinate System
- **Exposed Information**:
  - Box position in terminal
  - Content area dimensions
  - Individual cell coordinates
- **Why**: Enables overlays, animations, and interactive layers

### 7. Non-Goals (Explicit Boundaries)

#### What Boxy Does NOT Do:
- **Input handling**: No keyboard/mouse events
- **Terminal management**: No screen clearing or cursor control
- **Colors**: Users can insert ANSI codes themselves
- **State management**: Boxes are immutable after building
- **Scrolling**: Terminal or other libraries handle this
- **Persistence**: No save/load functionality

### 8. Testing Strategy

#### Unit Tests
- Border pattern repetition
- Text truncation edge cases
- Layout calculations with constraints
- UTF-8 character handling

#### Integration Tests
- Complex nested layouts
- Theme application
- Canvas operations
- Memory leak detection

#### Visual Tests
- Example gallery showing all features
- Performance benchmarks for large tables
- Terminal compatibility checks

### 9. Performance Considerations

#### Optimization Opportunities
- **Lazy Evaluation**: Only compute what's needed
- **Caching**: Reuse calculated dimensions
- **Batch Operations**: Update multiple cells at once
- **Incremental Updates**: Refresh only changed content

#### Trade-offs
- **Memory vs. Speed**: Pre-compute common patterns
- **Flexibility vs. Performance**: Builder pattern overhead
- **Safety vs. Speed**: Bounds checking on canvas operations

### 10. Future Extensibility

#### Planned Extension Points (Not in V1):
- Animation framework (built on top)
- Color theme system (as separate module)
- Serialization support (if needed)
- Template library (common box patterns)

#### Community Ecosystem
- Encourage wrapper libraries for specific uses:
  - boxy-games: Game UI helpers
  - boxy-dashboard: Monitoring layouts
  - boxy-forms: Interactive forms
  - boxy-charts: ASCII charts and graphs

## Implementation Phases

### Phase 1: Core Foundation ✅ DONE
1. ✅ Basic BoxyTheme structure
2. ✅ Simple border rendering
3. ✅ Single box with fixed content
4. ✅ Basic print() functionality

### Phase 2: Layout Engine ✅ DONE
1. ✅ Column/row orientation (both implemented with automatic transposition)
2. ✅ Size constraints (exact/min/max/range all implemented with builder methods)
3. ✅ Text alignment
4. ✅ Multi-section boxes

### Phase 3: Advanced Borders ✅ DONE
1. ✅ Custom border patterns
2. ✅ Multi-line borders
3. ✅ Inner vs. outer borders
4. ✅ Border themes (13 themes implemented)

### Phase 4: Canvas System ✅ DONE
1. ✅ Canvas creation (BoxyCanvas with init/deinit)
2. ✅ Blit operations (blitText, blitBlock, blitCanvas)
3. ✅ Partial refresh (dirty flag tracking)
4. ✅ Raw buffer access (getRawBuffer, getRow)

### Phase 5: Factory and Themes 🚧 PARTIAL
1. ✅ Factory pattern (BoxyFactory implemented with .new() method)
2. ⬜ Theme registry
3. ✅ Preset themes (13 themes)
4. ⬜ Configuration system

### Phase 6: Polish and Optimization 🚧 PARTIAL
1. ✅ Performance optimization (parameter objects)
2. ✅ Memory efficiency (arena allocators)
3. ✅ UTF-8 edge cases (emoji width, variation selectors)
4. 🚧 Documentation and examples (README done, needs more examples)

## Current Implementation Status

### ✅ Completed Features
- Builder pattern API with fluent interface
- 13 built-in themes (pipes, rounded, bold, tribal, neon, etc.)
- Multi-line border support for 3D effects
- UTF-8 and emoji support with proper width calculations
- Text alignment (left, center, right)
- Cell padding for better readability
- Title sections with automatic centering
- Header/data separation with dividers
- Pattern-based borders that repeat to fill space
- Truncation with ellipsis for long text
- Parameter objects for clean architecture (RenderContext, TableRenderOptions)
- Named constants for maintainability
- **Spreadsheet mode** - First .set() becomes columns, rest become rows with row headers
- Organized build system separating library from examples
- **Canvas System** - Full implementation with blitting, drawing primitives, and dirty tracking
- **Factory Pattern** - BoxyFactory for reusable configurations
- **Size Constraints** - Complete width control with exact/min/max/range methods
- Arena allocator for efficient memory management
- Canvas view/sub-canvas support for windowing
- **Row Orientation** - Data can be provided as rows instead of columns with automatic transposition
- **Size Presets** - .compact/.comfort/.spacious for consistent padding
- **Extra Space Strategy** - Control distribution of extra space in fixed-width boxes (first/last/distributed/center)
- **Height Constraints** - Basic exact/min/max methods (needs proper implementation - see todo #8)

### ⬜ Not Yet Implemented (Priority Order)

#### Medium Priority - Enhanced API
1. **Column Width Control** - Per-column size constraints
2. **Custom Truncation Indicators** - Beyond "..."
3. **Coordinate System** - getCoords(), getContentArea()
4. **Word-Aware Breaking** - Smart text wrapping
5. **Terminal UI Context** - Advanced positioning (stub exists)

#### Low Priority - Advanced Features
6. **Height Constraints (Proper Implementation)** - Fix height constraint logic to:
   - Only apply when explicitly set (not auto)
   - Track constraint state in LayoutInfo
   - Intelligently truncate/scroll content when constrained
   - Support min/max/exact height with proper content clipping
7. **Theme Inheritance** - Compose themes from base themes
8. **Hooks/Callbacks** - Pre/post render extensibility
9. **Canvas Incremental Updates** - refreshCanvas() method implementation
10. **Theme Registry** - Global theme management
11. **Configuration System** - Load settings from files
12. **Multi-canvas support** - Multiple canvases in one box

## Success Metrics

- **API Simplicity**: ✅ Can create a box in < 5 lines
- **Performance**: ❓ Not yet benchmarked for 100x100 tables
- **Flexibility**: ✅ Canvas mode implemented for game UIs
- **Reliability**: ✅ No panics in current implementation
- **Size**: ✅ Zero dependencies, small footprint

## Key Insight

The magic of Boxy is NOT in doing everything, but in doing boxes so well that everything else becomes easy to build on top. Like LEGO blocks - simple, solid, composable.

## Next Steps (Recommended Order)

1. **Column Width Control** - Add per-column size constraints
2. **Custom Truncation Indicators** - Allow customizing "..." for truncated text
3. **Word-Aware Breaking** - Smart text wrapping for long content
4. **Benchmark Performance** - Validate 100x100 table rendering speed
5. **Height Constraints (Proper)** - Fix the implementation when explicitly set
5. **More Examples** - Add examples for canvas animations, factory usage, and advanced layouts