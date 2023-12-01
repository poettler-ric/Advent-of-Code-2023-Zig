const std = @import("std");

const Command = struct {
    name: []const u8,
    source: []const u8,
    unittest: bool = false,
    run: bool = false,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const run_step = b.step("run", "Run test junk");
    const test_step = b.step("test", "Run unit tests");

    const commands = [_]Command{
        .{
            .name = "day01",
            .source = "src/day01.zig",
            .unittest = true,
            .run = true,
        },
    };

    for (commands) |command| {
        const artifact = b.addExecutable(.{
            .name = command.name,
            .root_source_file = .{ .path = command.source },
            .target = target,
            .optimize = optimize,
        });
        b.installArtifact(artifact);

        if (command.unittest) {
            const unit_test = b.addTest(.{
                .root_source_file = .{ .path = command.source },
                .target = target,
                .optimize = optimize,
            });
            const run_unit_test = b.addRunArtifact(unit_test);
            test_step.dependOn(&run_unit_test.step);
        }

        if (command.run) {
            const cmd = b.addRunArtifact(artifact);
            cmd.step.dependOn(b.getInstallStep());
            run_step.dependOn(&cmd.step);
        }
    }
}
