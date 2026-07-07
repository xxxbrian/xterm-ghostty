const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const ghostty_src = b.option(
        []const u8,
        "ghostty-src",
        "Path to a Ghostty source checkout",
    ) orelse "upstream/ghostty";

    const ghostty_terminfo = b.createModule(.{
        .root_source_file = .{ .cwd_relative = b.pathJoin(&.{
            ghostty_src,
            "src/terminfo/ghostty.zig",
        }) },
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "xterm-ghostty-generate",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/generate.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .imports = &.{.{
                .name = "ghostty_terminfo",
                .module = ghostty_terminfo,
            }},
        }),
    });

    const run = b.addRunArtifact(exe);
    run.has_side_effects = true;

    const generate_step = b.step("generate", "Print xterm-ghostty terminfo source");
    generate_step.dependOn(&run.step);
}
