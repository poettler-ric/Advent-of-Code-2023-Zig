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

const Range = struct {
    start: i64,
    end: i64,

    fn contains(self: Range, i: i64) bool {
        return self.start <= i and i < self.end;
    }
};

test "Range.contains" {
    const r = Range{
        .start = 2,
        .end = 5,
    };
    try expect(!r.contains(1));
    try expect(r.contains(2));
    try expect(r.contains(3));
    try expect(r.contains(4));
    try expect(!r.contains(5));
}

fn rangeLtContext(ctx: void, lhs: Range, rhs: Range) bool {
    _ = ctx;
    return lhs.start < rhs.start;
}

const Mapping = struct {
    range: Range,
    delta: i64,

    fn map(self: Mapping, i: i64) i64 {
        return i + self.delta;
    }
};

fn mappingLtContext(ctx: void, lhs: Mapping, rhs: Mapping) bool {
    _ = ctx;
    return lhs.range.start < rhs.range.start;
}

fn mapList(mappings: []Mapping, list: []i64) void {
    for (list, 0..) |s, i| {
        for (mappings) |d| {
            if (d.range.contains(s)) {
                list[i] = d.map(s);
                break;
            }
        }
    }
}

fn mapRanges(mappings: []Mapping, sources: []Range, destinations: *std.ArrayList(Range)) void {
    _ = destinations;
    _ = sources;
    _ = mappings;
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

    var buffer1 = std.ArrayList(Range).init(opt.allocator);
    defer buffer1.deinit();
    var buffer2 = std.ArrayList(Range).init(opt.allocator);
    defer buffer2.deinit();

    var sourceRanges = &buffer1;
    var destinationRanges = &buffer1;
    _ = destinationRanges;

    for (0..sources.items.len / 2) |i| {
        const start = sources.items[i * 2];
        const range = sources.items[i * 2 + 1];
        try sourceRanges.append(Range{
            .start = start,
            .end = start + range + 1,
        });
    }

    // ignore empty line
    try reader.streamUntilDelimiter(lineBuffer.writer(), '\n', null);
    lineBuffer.clearRetainingCapacity();

    // parse mappings
    var mappings = std.ArrayList(Mapping).init(opt.allocator);
    defer mappings.deinit();

    while (reader.streamUntilDelimiter(
        lineBuffer.writer(),
        '\n',
        null,
    )) : (lineBuffer.clearRetainingCapacity()) {
        const line = lineBuffer.items;
        if (line.len == 0) {
            mem.sortUnstable(Mapping, mappings.items, {}, mappingLtContext);
            mapList(mappings.items, sources.items);
            mappings.clearRetainingCapacity();
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
            try mappings.append(Mapping{
                .range = Range{
                    .start = try sourceStart,
                    .end = try sourceStart + try range + 1,
                },
                .delta = try destinationStart - try sourceStart,
            });
        }
    } else |err| {
        switch (err) {
            error.EndOfStream => {},
            else => return err,
        }
    }

    mapList(mappings.items, sources.items);

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
