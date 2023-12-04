const std = @import("std");
const testing = std.testing;
const expect = testing.expect;

const FILENAME = "adventofcode_2023_03.txt";

const Point = struct {
    x: usize,
    y: usize,
};

const FoundNumber = struct {
    number: u32,
    start: usize,
    end: usize,
};
fn getWholeNumber(str: []const u8, pos: usize) FoundNumber {
    var start = pos;
    var end = pos + 1;
    while (start > 0 and std.ascii.isDigit(str[start - 1])) {
        start -= 1;
    }
    while (end < str.len and std.ascii.isDigit(str[end])) {
        end += 1;
    }

    return .{
        .number = std.fmt.parseInt(u32, str[start..end], 10) catch unreachable,
        .start = start,
        .end = end,
    };
}

test "getWholeNumber" {
    try expect(std.meta.eql(getWholeNumber("123", 1), FoundNumber{
        .number = 123,
        .start = 0,
        .end = 3,
    }));
    try expect(std.meta.eql(getWholeNumber("a456b", 1), FoundNumber{
        .number = 456,
        .start = 1,
        .end = 4,
    }));
}

const ParseOptions = struct {
    allocator: std.mem.Allocator = std.heap.page_allocator,
};
fn parseSchematic(fileName: []const u8, opt: ParseOptions) !u32 {
    const file = try std.fs.cwd().openFile(fileName, .{});
    defer file.close();
    var bufReader = std.io.bufferedReader(file.reader());
    const reader = bufReader.reader();

    var content = std.ArrayList(std.ArrayList(u8)).init(opt.allocator);
    defer {
        for (content.items) |i| {
            i.deinit();
        }
        content.deinit();
    }
    // slurp the whole file
    var lineBuffer = std.ArrayList(u8).init(opt.allocator);
    while (reader.streamUntilDelimiter(lineBuffer.writer(), '\n', null)) {
        try content.append(lineBuffer);
        lineBuffer = std.ArrayList(u8).init(opt.allocator);
    } else |err| {
        switch (err) {
            error.EndOfStream => {},
            else => return err,
        }
    }
    var partSum: u32 = 0;
    var seen = std.AutoHashMap(Point, void).init(opt.allocator);
    defer seen.deinit();

    // iterate over all lines and characters
    for (content.items, 0..) |line, y| {
        for (line.items, 0..) |c, x| {
            if (c != '.' and !std.ascii.isDigit(c)) {
                // scan around the point for digits
                for (if (y == 0) 0 else y - 1..@min(y + 2, content.items.len)) |yi| {
                    for (if (x == 0) 0 else x - 1..@min(x + 2, line.items.len)) |xi| {
                        // if a digit was found get all digits of the number
                        // if the position wasn't seen, yet
                        if (std.ascii.isDigit(content.items[yi].items[xi])) {
                            if (!seen.contains(.{ .x = xi, .y = yi })) {
                                var found = getWholeNumber(content.items[yi].items, xi);
                                partSum += found.number;
                                // mark all positions of digits as seen
                                for (found.start..found.end) |i| {
                                    try seen.put(.{ .x = i, .y = yi }, {});
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    return partSum;
}

test "parseSchematic" {
    try expect(4361 == try parseSchematic(
        "adventofcode_2023_03_test_01.txt",
        .{ .allocator = testing.allocator },
    ));
}

pub fn main() !void {
    const start = std.time.microTimestamp();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var stdoutBuffer = std.io.bufferedWriter(std.io.getStdOut().writer());
    const stdout = stdoutBuffer.writer();

    const partSum = try parseSchematic(
        FILENAME,
        .{ .allocator = arena.allocator() },
    );
    try stdout.print("part sum: {d}\n", .{partSum});
    try stdout.print(
        "time usage: {d} μs\n",
        .{std.time.microTimestamp() - start},
    );

    try stdoutBuffer.flush();
}
