const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create the boxy module (library)
    const boxy_module = b.addModule("boxy", .{
        .root_source_file = b.path("src/boxy.zig"),
    });

    // Create a static library artifact
    const lib = b.addStaticLibrary(.{
        .name = "boxy",
        .root_source_file = b.path("src/boxy.zig"),
        .target = target,
        .optimize = optimize,
    });
    
    // Install the library to zig-out/lib/
    b.installArtifact(lib);

    // Create tests
    const tests = b.addTest(.{
        .root_source_file = b.path("src/boxy.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);

    // Create examples step
    const examples_step = b.step("examples", "Build all examples");
    
    // Define all examples
    const example_files = [_]struct { name: []const u8, desc: []const u8 }{
        .{ .name = "minimal", .desc = "Minimal box example" },
        .{ .name = "game", .desc = "Game inventory example" },
        .{ .name = "table", .desc = "Table with headers" },
        .{ .name = "schedule", .desc = "Schedule with spreadsheet mode" },
        .{ .name = "grades", .desc = "Gradebook with spreadsheet mode" },
        .{ .name = "grid", .desc = "Grid theme with row dividers" },
        .{ .name = "headless", .desc = "Table without headers" },
        .{ .name = "invoice", .desc = "Invoice with mixed content" },
        .{ .name = "multiline", .desc = "Multi-line borders example" },
        .{ .name = "canvas_demo", .desc = "Canvas mode for dynamic content" },
        .{ .name = "canvas_animation", .desc = "Canvas animation demo" },
        .{ .name = "canvas_bounce", .desc = "Animated bouncing ball demo" },
        .{ .name = "cjk_test", .desc = "CJK and emoji character width test" },
        .{ .name = "row_orientation", .desc = "Row orientation examples" },
        .{ .name = "orientation_comparison", .desc = "Compare orientation vs spreadsheet mode" },
        .{ .name = "size_constraints", .desc = "Width constraints examples" },
        .{ .name = "extra_space_strategy", .desc = "Extra space distribution strategies" },
        .{ .name = "height_test", .desc = "Height constraint test" },
        .{ .name = "test_junctions", .desc = "Test junction characters" },
        .{ .name = "test_junctions_no_title", .desc = "Test junctions without title" },
    };

    // Build each example
    for (example_files) |example_info| {
        const exe = b.addExecutable(.{
            .name = example_info.name,
            .root_source_file = b.path(b.fmt("examples/{s}.zig", .{example_info.name})),
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addImport("boxy", boxy_module);
        
        // Install to zig-out/bin only when examples step is invoked
        const install_exe = b.addInstallArtifact(exe, .{});
        examples_step.dependOn(&install_exe.step);
        
        // Create individual run step for this example
        const run_cmd = b.addRunArtifact(exe);
        const run_step = b.step(
            b.fmt("run-{s}", .{example_info.name}),
            b.fmt("Run {s}", .{example_info.desc})
        );
        run_step.dependOn(&run_cmd.step);
    }

    // Add a step to run all examples sequentially
    const run_all = b.step("run-all-examples", "Run all examples in sequence");
    for (example_files) |example_info| {
        const exe = b.addExecutable(.{
            .name = example_info.name,
            .root_source_file = b.path(b.fmt("examples/{s}.zig", .{example_info.name})),
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addImport("boxy", boxy_module);
        
        const run_cmd = b.addRunArtifact(exe);
        run_all.dependOn(&run_cmd.step);
        
        // Add a separator between examples (except after the last one)
        if (!std.mem.eql(u8, example_info.name, example_files[example_files.len - 1].name)) {
            const print_separator = b.addSystemCommand(&.{ 
                "echo", 
                "\n================================================================================\n" 
            });
            print_separator.step.dependOn(&run_cmd.step);
            run_all.dependOn(&print_separator.step);
        }
    }

    // Build commands:
    //   zig build                   # Builds static library to zig-out/lib/
    //   zig build examples          # Builds all examples to zig-out/bin/
    //   zig build test              # Runs tests
    //   zig build run-schedule      # Runs specific example
    //   zig build run-all-examples  # Runs all examples
}