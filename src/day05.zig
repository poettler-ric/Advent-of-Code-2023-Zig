const std = @import("std");
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;
const testing = std.testing;
const expect = testing.expect;

const Day05Error = error{
    NoSeedSeparator,
    NoDestinationStart,
    NoSourceStart,
    NoRange,
};

const Mapping = struct {
    start: i64,
    end: i64,
    delta: i64,

    fn contains(self: Mapping, i: i64) bool {
        return self.start <= i and i < self.end;
    }

    fn map(self: Mapping, i: i64) i64 {
        return i + self.delta;
    }
};

test "Mapping.contains" {
    const m = Mapping{
        .start = 2,
        .end = 5,
        .delta = 0,
    };
    try expect(!m.contains(1));
    try expect(m.contains(2));
    try expect(m.contains(3));
    try expect(m.contains(4));
    try expect(!m.contains(5));
}

const ParseOptions = struct {
    allocator: std.mem.Allocator = std.heap.page_allocator,
};
const ParseResult = struct {
    location: i64,
};
fn parseMapping(fileName: []const u8, opt: ParseOptions) !ParseResult {
    const file = try std.fs.cwd().openFile(fileName, .{});
    defer file.close();
    var bufReader = io.bufferedReader(file.reader());
    const reader = bufReader.reader();

    var lineBuffer = std.ArrayList(u8).init(opt.allocator);
    defer lineBuffer.deinit();

    // read seeds
    try reader.streamUntilDelimiter(lineBuffer.writer(), '\n', null);

    var sources = std.ArrayList(i64).init(opt.allocator);
    defer sources.deinit();

    const seedsLine = lineBuffer.items;
    if (mem.indexOfScalar(u8, seedsLine, ':')) |pos| {
        var seedsIterator = mem.splitScalar(u8, seedsLine[pos + 2 ..], ' ');
        while (seedsIterator.next()) |seedString| {
            try sources.append(try fmt.parseInt(i64, seedString, 10));
        }
    } else {
        return Day05Error.NoSeedSeparator;
    }

    // ignore empty line
    try reader.streamUntilDelimiter(lineBuffer.writer(), '\n', null);
    lineBuffer.clearRetainingCapacity();

    // parse mappings
    var deltas = std.ArrayList(Mapping).init(opt.allocator);
    defer deltas.deinit();

    while (reader.streamUntilDelimiter(
        lineBuffer.writer(),
        '\n',
        null,
    )) : (lineBuffer.clearRetainingCapacity()) {
        const line = lineBuffer.items;
        if (line.len == 0) {
            for (sources.items, 0..) |s, i| {
                for (deltas.items) |d| {
                    if (d.contains(s)) {
                        sources.items[i] = d.map(s);
                        break;
                    }
                }
            }
            deltas.clearRetainingCapacity();
        } else if (std.ascii.isDigit(line[0])) {
            var mapIteraor = mem.splitScalar(u8, line, ' ');
            var destinationStart: Day05Error!i64 = Day05Error.NoDestinationStart;
            var sourceStart: Day05Error!i64 = Day05Error.NoSourceStart;
            var range: Day05Error!i64 = Day05Error.NoRange;
            if (mapIteraor.next()) |s| {
                destinationStart = try fmt.parseInt(i64, s, 10);
            }
            if (mapIteraor.next()) |s| {
                sourceStart = try fmt.parseInt(i64, s, 10);
            }
            if (mapIteraor.next()) |s| {
                range = try fmt.parseInt(i64, s, 10);
            }
            try deltas.append(Mapping{
                .start = try sourceStart,
                .end = try sourceStart + try range + 1,
                .delta = try destinationStart - try sourceStart,
            });
        }
    } else |err| {
        switch (err) {
            error.EndOfStream => {},
            else => return err,
        }
    }

    for (sources.items, 0..) |s, i| {
        for (deltas.items) |d| {
            if (d.contains(s)) {
                sources.items[i] = d.map(s);
                break;
            }
        }
    }
    return ParseResult{ .location = mem.min(i64, sources.items) };
}

test "parseMapping" {
    const parsed = try parseMapping(
        "adventofcode_2023_05_test_01.txt",
        .{ .allocator = testing.allocator },
    );
    try expect(35 == parsed.location);
}

pub fn main() !void {
    const heap = std.heap;
    const time = std.time;

    const start = time.microTimestamp();

    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    var stdoutBuffer = io.bufferedWriter(io.getStdOut().writer());
    const stdout = stdoutBuffer.writer();

    const result = try parseMapping(
        "adventofcode_2023_05.txt",
        .{ .allocator = arena.allocator() },
    );
    try stdout.print("location: {d}\n", .{result.location});
    try stdout.print(
        "time usage: {d} μs\n",
        .{time.microTimestamp() - start},
    );

    try stdoutBuffer.flush();
}
