const std = @import("std");
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;
const testing = std.testing;
const expect = testing.expect;

const Day06Error = error{
    NoColonFound,
};

fn extractNumbers(comptime T: type, str: []const u8, list: *std.ArrayList(T)) !void {
    var iterator = mem.splitScalar(u8, str, ' ');
    while (iterator.next()) |part| {
        if (part.len == 0) {
            continue;
        }
        try list.append(try fmt.parseInt(T, part, 10));
    }
}

fn canBeat(pressDuration: u32, time: u32, distance: u32) bool {
    return (time - pressDuration) * pressDuration > distance;
}

const ParseOptions = struct {
    allocator: std.mem.Allocator = std.heap.page_allocator,
};
const ParseResult = struct {
    possiblitiesProduct: u32,
};
fn parseRecords(fileName: []const u8, opt: ParseOptions) !ParseResult {
    const file = try std.fs.cwd().openFile(fileName, .{});
    defer file.close();
    var bufReader = io.bufferedReader(file.reader());
    const reader = bufReader.reader();

    var lineBuffer = std.ArrayList(u8).init(opt.allocator);
    defer lineBuffer.deinit();

    var times = std.ArrayList(u32).init(opt.allocator);
    defer times.deinit();
    var distances = std.ArrayList(u32).init(opt.allocator);
    defer distances.deinit();

    try reader.streamUntilDelimiter(lineBuffer.writer(), '\n', null);
    if (mem.indexOfScalar(u8, lineBuffer.items, ':')) |pos| {
        try extractNumbers(u32, lineBuffer.items[pos + 1 ..], &times);
    } else {
        return Day06Error.NoColonFound;
    }
    lineBuffer.clearRetainingCapacity();
    try reader.streamUntilDelimiter(lineBuffer.writer(), '\n', null);
    if (mem.indexOfScalar(u8, lineBuffer.items, ':')) |pos| {
        try extractNumbers(u32, lineBuffer.items[pos + 1 ..], &distances);
    } else {
        return Day06Error.NoColonFound;
    }
    lineBuffer.clearRetainingCapacity();

    var result = ParseResult{ .possiblitiesProduct = 0 };
    for (times.items, distances.items) |time, distance| {
        var possiblities: u32 = 0;
        var pressDuration: u32 = 1;
        while (pressDuration < time) : (pressDuration += 1) {
            if (canBeat(pressDuration, time, distance)) {
                possiblities += 1;
            }
        }
        if (result.possiblitiesProduct == 0) {
            result.possiblitiesProduct = possiblities;
        } else {
            result.possiblitiesProduct *= possiblities;
        }
    }

    return result;
}

test "parseRecords" {
    const parsed = try parseRecords(
        "adventofcode_2023_06_test_01.txt",
        .{ .allocator = testing.allocator },
    );
    try expect(288 == parsed.possiblitiesProduct);
}

pub fn main() !void {
    const heap = std.heap;
    const time = std.time;

    const start = time.microTimestamp();

    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    var stdoutBuffer = io.bufferedWriter(io.getStdOut().writer());
    const stdout = stdoutBuffer.writer();

    const result = try parseRecords(
        "adventofcode_2023_06.txt",
        .{ .allocator = arena.allocator() },
    );
    try stdout.print("possiblities: {d}\n", .{result.possiblitiesProduct});
    try stdout.print(
        "time usage: {d} μs\n",
        .{time.microTimestamp() - start},
    );

    try stdoutBuffer.flush();
}
