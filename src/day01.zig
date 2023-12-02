const std = @import("std");

const FILENAME = "adventofcode_2023_01.txt";

const Day01Error = error{
    NoDigitFound,
};

const Replacement = struct {
    replacement: u8,
    pattern: []const u8,
};
const REPLACEMENTS = [_]Replacement{
    .{ .replacement = '1', .pattern = "one" },
    .{ .replacement = '2', .pattern = "two" },
    .{ .replacement = '3', .pattern = "three" },
    .{ .replacement = '4', .pattern = "four" },
    .{ .replacement = '5', .pattern = "five" },
    .{ .replacement = '6', .pattern = "six" },
    .{ .replacement = '7', .pattern = "seven" },
    .{ .replacement = '8', .pattern = "eight" },
    .{ .replacement = '9', .pattern = "nine" },
};

fn getCalibrationValue(str: []const u8) Day01Error!u32 {
    var firstDigit: Day01Error!u8 = Day01Error.NoDigitFound;
    var lastDigit: Day01Error!u8 = Day01Error.NoDigitFound;

    for (str) |c| {
        if (std.ascii.isDigit(c)) {
            if (firstDigit == Day01Error.NoDigitFound) {
                firstDigit = c;
            }
            lastDigit = c;
        }
    }

    return std.fmt.parseInt(u32, &[_]u8{ try firstDigit, try lastDigit }, 10) catch unreachable;
}

test "getCalibrationValue" {
    try std.testing.expectEqual(12, comptime try getCalibrationValue("1abc2"));
    try std.testing.expectEqual(38, comptime try getCalibrationValue("pqr3stu8vwx"));
    try std.testing.expectEqual(15, comptime try getCalibrationValue("a1b2c3d4e5f"));
    try std.testing.expectEqual(77, comptime try getCalibrationValue("treb7uchet"));
}

fn getCalibrationValueSpelled(str: []const u8) Day01Error!u32 {
    var firstDigit: Day01Error!u8 = Day01Error.NoDigitFound;
    var lastDigit: Day01Error!u8 = Day01Error.NoDigitFound;

    for (str, 0..) |c, i| {
        if (std.ascii.isDigit(c)) {
            if (firstDigit == Day01Error.NoDigitFound) {
                firstDigit = c;
            }
            lastDigit = c;
        } else {
            for (REPLACEMENTS) |replacement| {
                if (std.mem.startsWith(u8, str[i..], replacement.pattern)) {
                    if (firstDigit == Day01Error.NoDigitFound) {
                        firstDigit = replacement.replacement;
                    }
                    lastDigit = replacement.replacement;
                    break;
                }
            }
        }
    }

    return std.fmt.parseInt(u32, &[_]u8{ try firstDigit, try lastDigit }, 10) catch unreachable;
}

test "getCalibrationValueSpelled" {
    @setEvalBranchQuota(4000);
    try std.testing.expectEqual(12, comptime try getCalibrationValueSpelled("1abc2"));
    try std.testing.expectEqual(38, comptime try getCalibrationValueSpelled("pqr3stu8vwx"));
    try std.testing.expectEqual(15, comptime try getCalibrationValueSpelled("a1b2c3d4e5f"));
    try std.testing.expectEqual(77, comptime try getCalibrationValueSpelled("treb7uchet"));
    try std.testing.expectEqual(29, comptime try getCalibrationValueSpelled("two1nine"));
    try std.testing.expectEqual(83, comptime try getCalibrationValueSpelled("eightwothree"));
    try std.testing.expectEqual(13, comptime try getCalibrationValueSpelled("abcone2threexyz"));
    try std.testing.expectEqual(24, comptime try getCalibrationValueSpelled("xtwone3four"));
    try std.testing.expectEqual(42, comptime try getCalibrationValueSpelled("4nineeightseven2"));
    try std.testing.expectEqual(14, comptime try getCalibrationValueSpelled("zoneight234"));
    try std.testing.expectEqual(76, comptime try getCalibrationValueSpelled("7pqrstsixteen"));
    try std.testing.expectEqual(31, comptime try getCalibrationValueSpelled("3one8ncctmbsixeighttwonegb"));
}

fn getCalibrationSums(fileName: []const u8) ![2]u32 {
    const file = try std.fs.cwd().openFile(fileName, .{});
    defer file.close();
    var bufReader = std.io.bufferedReader(file.reader());
    const reader = bufReader.reader();

    var buffer: [1024 * 4]u8 = undefined;
    var lineBuffer = std.io.fixedBufferStream(&buffer);

    var sum: u32 = 0;
    var sumSpelled: u32 = 0;

    while (reader.streamUntilDelimiter(lineBuffer.writer(), '\n', lineBuffer.buffer.len)) : (lineBuffer.reset()) {
        const line = lineBuffer.getWritten();
        sum += try getCalibrationValue(line);
        sumSpelled += try getCalibrationValueSpelled(line);
    } else |err| {
        switch (err) {
            error.EndOfStream => {},
            else => return err,
        }
    }

    return [_]u32{ sum, sumSpelled };
}

pub fn main() !void {
    const start = std.time.microTimestamp();
    var stdoutBuffer = std.io.bufferedWriter(std.io.getStdOut().writer());
    const stdout = stdoutBuffer.writer();

    const sums = try getCalibrationSums(FILENAME);
    try stdout.print("calibration sum: {d}\n", .{sums[0]});
    try stdout.print("calibration sum spelled: {d}\n", .{sums[1]});
    try stdout.print("time usage: {d}μs\n", .{std.time.microTimestamp() - start});

    try stdoutBuffer.flush();
}
