const std = @import("std");
const io = std.io;
const mem = std.mem;
const fmt = std.fmt;
const testing = std.testing;
const expect = testing.expect;

const Day04Error = error{
    NoCardSeparatorFound,
    NoWinningSeparatorFound,
};

fn matchCount(str: []const u8, opt: ParseOptions) !u32 {
    if (mem.indexOfScalar(u8, str, ':')) |cardSeparator| {
        if (mem.indexOfScalar(u8, str, '|')) |winningSeparator| {
            var matches: u32 = 0;
            var winning = std.AutoHashMap(u32, void).init(opt.allocator);
            defer winning.deinit();

            var winningNumbers = mem.splitScalar(
                u8,
                str[cardSeparator + 1 .. winningSeparator],
                ' ',
            );
            while (winningNumbers.next()) |numberString| {
                if (numberString.len > 0) {
                    try winning.put(
                        try fmt.parseInt(u32, numberString, 10),
                        {},
                    );
                }
            }

            var numbers = mem.splitScalar(
                u8,
                str[winningSeparator + 1 ..],
                ' ',
            );
            while (numbers.next()) |numberString| {
                if (numberString.len > 0) {
                    const number = try fmt.parseInt(u32, numberString, 10);
                    if (winning.contains(number)) {
                        matches += 1;
                    }
                }
            }

            return matches;
        } else {
            return Day04Error.NoWinningSeparatorFound;
        }
    } else {
        return Day04Error.NoCardSeparatorFound;
    }
}

test "matchCount" {
    const opt = ParseOptions{ .allocator = testing.allocator };
    try expect(4 == try matchCount(
        "Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53",
        opt,
    ));
    try expect(2 == try matchCount("Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19", opt));
    try expect(2 == try matchCount("Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1", opt));
    try expect(1 == try matchCount("Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83", opt));
    try expect(0 == try matchCount("Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36", opt));
    try expect(0 == try matchCount("Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11", opt));
}

fn score(matches: u32) u32 {
    return if (matches == 0) 0 else std.math.pow(u32, 2, matches - 1);
}

test "score" {
    try expect(0 == score(0));
    try expect(1 == score(1));
    try expect(2 == score(2));
    try expect(4 == score(3));
    try expect(8 == score(4));
}

const ParseOptions = struct {
    allocator: std.mem.Allocator = std.heap.page_allocator,
};
const ParseResult = struct {
    points: u32,
};
fn parseCards(fileName: []const u8, opt: ParseOptions) !ParseResult {
    const file = try std.fs.cwd().openFile(fileName, .{});
    defer file.close();
    var bufReader = io.bufferedReader(file.reader());
    const reader = bufReader.reader();

    var buffer: [1024 * 4]u8 = undefined;
    var lineBuffer = io.fixedBufferStream(&buffer);

    var result = ParseResult{ .points = 0 };

    while (reader.streamUntilDelimiter(
        lineBuffer.writer(),
        '\n',
        lineBuffer.buffer.len,
    )) : (lineBuffer.reset()) {
        result.points += score(try matchCount(lineBuffer.getWritten(), opt));
    } else |err| {
        switch (err) {
            error.EndOfStream => {},
            else => return err,
        }
    }

    return result;
}

test "parseCards" {
    const parsed = try parseCards(
        "adventofcode_2023_04_test_01.txt",
        .{ .allocator = testing.allocator },
    );
    try expect(13 == parsed.points);
}

pub fn main() !void {
    const heap = std.heap;
    const time = std.time;

    const start = time.microTimestamp();

    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    var stdoutBuffer = io.bufferedWriter(io.getStdOut().writer());
    const stdout = stdoutBuffer.writer();

    const result = try parseCards(
        "adventofcode_2023_04.txt",
        .{ .allocator = arena.allocator() },
    );
    try stdout.print("card point sum: {d}\n", .{result.points});
    try stdout.print(
        "time usage: {d} μs\n",
        .{time.microTimestamp() - start},
    );

    try stdoutBuffer.flush();
}
