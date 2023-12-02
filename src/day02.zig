const std = @import("std");

const FILENAME = "adventofcode_2023_02.txt";

const Day01Error = error{
    NoGameSeparatorFound,
    NoGameIdSeparatorFound,
    NoCubesSeparatorFound,
    InvalidColor,
};

const GameRecord = struct {
    id: u32,
    valid: bool,
    minimumRed: u32 = 0,
    minimumGreen: u32 = 0,
    minimumBlue: u32 = 0,

    fn power(self: GameRecord) u32 {
        return self.minimumRed * self.minimumGreen * self.minimumBlue;
    }
};

const Cubes = union(enum) {
    Red: u32,
    Green: u32,
    Blue: u32,
};

fn isValid(cubes: Cubes) bool {
    return switch (cubes) {
        .Red => |n| n <= 12,
        .Green => |n| n <= 13,
        .Blue => |n| n <= 14,
    };
}

fn parseCubes(str: []const u8) !Cubes {
    const trimmed = std.mem.trim(u8, str, " ");
    if (std.mem.indexOfScalar(u8, trimmed, ' ')) |spacePos| {
        const quantity = try std.fmt.parseInt(u32, trimmed[0..spacePos], 10);
        return switch (trimmed[spacePos + 1]) {
            'r' => Cubes{ .Red = quantity },
            'g' => Cubes{ .Green = quantity },
            'b' => Cubes{ .Blue = quantity },
            else => error.InvalidColor,
        };
    }
    return error.NoCubesSeparatorFound;
}

fn parseGame(line: []const u8) !GameRecord {
    if (std.mem.indexOfScalar(u8, line, ':')) |colonPos| {
        var record = GameRecord{ .id = 0, .valid = true };
        if (std.mem.indexOfScalar(u8, line[0..colonPos], ' ')) |spacePos| {
            record.id = try std.fmt.parseInt(u32, line[spacePos + 1 .. colonPos], 10);
        } else {
            return error.NoGameIdSeparatorFound;
        }
        var handIterator = std.mem.splitAny(u8, line[colonPos + 1 ..], ";");
        while (handIterator.next()) |hand| {
            var cubesIterator = std.mem.splitAny(u8, hand, ",");
            while (cubesIterator.next()) |cubesString| {
                const cubes = try parseCubes(cubesString);
                record.valid = record.valid and isValid(cubes);
                switch (cubes) {
                    .Red => |n| record.minimumRed = @max(record.minimumRed, n),
                    .Green => |n| record.minimumGreen = @max(record.minimumGreen, n),
                    .Blue => |n| record.minimumBlue = @max(record.minimumBlue, n),
                }
            }
        }
        return record;
    }
    return error.NoGameSeparatorFound;
}

test "parseGame valid" {
    try std.testing.expect((try parseGame("Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green")).valid);
    try std.testing.expect((try parseGame("Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue")).valid);
    try std.testing.expect(!(try parseGame("Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red")).valid);
    try std.testing.expect(!(try parseGame("Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red")).valid);
    try std.testing.expect((try parseGame("Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green")).valid);
}

test "parseGame power()" {
    try std.testing.expect(48 == (try parseGame("Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green")).power());
    try std.testing.expect(12 == (try parseGame("Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue")).power());
    try std.testing.expect(1560 == (try parseGame("Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red")).power());
    try std.testing.expect(630 == (try parseGame("Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red")).power());
    try std.testing.expect(36 == (try parseGame("Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green")).power());
}

fn parseGames(fileName: []const u8) ![2]u32 {
    const file = try std.fs.cwd().openFile(fileName, .{});
    defer file.close();
    var bufReader = std.io.bufferedReader(file.reader());
    const reader = bufReader.reader();

    var buffer: [1024 * 4]u8 = undefined;
    var lineBuffer = std.io.fixedBufferStream(&buffer);

    var validIdSum: u32 = 0;
    var powerSum: u32 = 0;

    while (reader.streamUntilDelimiter(lineBuffer.writer(), '\n', lineBuffer.buffer.len)) : (lineBuffer.reset()) {
        const record = try parseGame(lineBuffer.getWritten());
        if (record.valid) {
            validIdSum += record.id;
        }
        powerSum += record.power();
    } else |err| {
        switch (err) {
            error.EndOfStream => {},
            else => return err,
        }
    }

    return [_]u32{ validIdSum, powerSum };
}
pub fn main() !void {
    const start = std.time.microTimestamp();
    var stdoutBuffer = std.io.bufferedWriter(std.io.getStdOut().writer());
    const stdout = stdoutBuffer.writer();

    const gameSums = try parseGames(FILENAME);
    try stdout.print("valid id sum: {d}\n", .{gameSums[0]});
    try stdout.print("power sum: {d}\n", .{gameSums[1]});
    try stdout.print("time usage: {d}μs\n", .{std.time.microTimestamp() - start});

    try stdoutBuffer.flush();
}
