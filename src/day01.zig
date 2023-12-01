const std = @import("std");

const FILENAME = "adventofcode_2023_01.txt";

const Day01Error = error{
    NoDigitFound,
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

fn getCalibrationSum(fileName: []const u8) !u32 {
    const file = try std.fs.cwd().openFile(fileName, .{});
    defer file.close();
    var bufReader = std.io.bufferedReader(file.reader());
    const reader = bufReader.reader();

    var buffer: [1024 * 4]u8 = undefined;
    var lineBuffer = std.io.fixedBufferStream(&buffer);

    var sum: u32 = 0;

    while (reader.streamUntilDelimiter(lineBuffer.writer(), '\n', lineBuffer.buffer.len)) : (lineBuffer.reset()) {
        sum += try getCalibrationValue(lineBuffer.getWritten());
    } else |err| {
        switch (err) {
            error.EndOfStream => {},
            else => return err,
        }
    }

    return sum;
}

pub fn main() !void {
    var stdoutBuffer = std.io.bufferedWriter(std.io.getStdOut().writer());
    const stdout = stdoutBuffer.writer();

    try stdout.print("calibration sum: {d}\n", .{try getCalibrationSum(FILENAME)});

    try stdoutBuffer.flush();
}
