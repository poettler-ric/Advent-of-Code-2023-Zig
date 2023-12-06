const std = @import("std");
const fmt = std.fmt;
const io = std.io;
const mem = std.mem;
const testing = std.testing;
const expect = testing.expect;

const Day06Error = error{
    NoColonFound,
    NoNumberFound,
};

fn concatDigits(comptime T: type, comptime bufSize: usize, str: []const u8) ?T {
    var buffer: [bufSize]u8 = undefined;
    var pos: usize = 0;

    for (str) |c| {
        if (std.ascii.isDigit(c)) {
            buffer[pos] = c;
            pos += 1;
        }
    }

    if (pos > 0) {
        return fmt.parseInt(T, buffer[0..pos], 10) catch unreachable;
    } else {
        return null;
    }
}

test "concatDigits" {
    try expect(3245 == concatDigits(u64, 1024, " 3 $ 24. 5").?);
}

fn extractNumbers(comptime T: type, str: []const u8, list: *std.ArrayList(T)) !void {
    var iterator = mem.splitScalar(u8, str, ' ');
    while (iterator.next()) |part| {
        if (part.len == 0) {
            continue;
        }
        try list.append(try fmt.parseInt(T, part, 10));
    }
}

fn solveQuadraticFormula(comptime T: type, p: T, q: T) [2]T {
    const math = std.math;
    return [2]T{
        -(p / 2) + math.sqrt(math.pow(T, p / 2, 2) - q),
        -(p / 2) - math.sqrt(math.pow(T, p / 2, 2) - q),
    };
}

fn getPossiblities(time: u64, distance: u64) u64 {
    const fTime: f64 = @floatFromInt(time);
    const fDistance: f64 = @floatFromInt(distance);
    const solutions = solveQuadraticFormula(f64, -fTime, fDistance);
    const lower = @min(solutions[0], solutions[1]);
    const upper = @max(solutions[0], solutions[1]);
    const ceil: u64 = if (@mod(lower, 1) == 0.0) @as(u64, @intFromFloat(lower)) + 1 else @intFromFloat(@ceil(lower));
    const floor: u64 = if (@mod(upper, 1) == 0.0) @as(u64, @intFromFloat(upper)) - 1 else @intFromFloat(@floor(upper));
    return floor - ceil + 1;
}

const ParseOptions = struct {
    allocator: std.mem.Allocator = std.heap.page_allocator,
};
const ParseResult = struct {
    possiblitiesProduct: u64,
    singlePossiblities: u64,
};
fn parseRecords(fileName: []const u8, opt: ParseOptions) !ParseResult {
    const file = try std.fs.cwd().openFile(fileName, .{});
    defer file.close();
    var bufReader = io.bufferedReader(file.reader());
    const reader = bufReader.reader();

    var lineBuffer = std.ArrayList(u8).init(opt.allocator);
    defer lineBuffer.deinit();

    var times = std.ArrayList(u64).init(opt.allocator);
    defer times.deinit();
    var singleTime: u64 = 0;
    var distances = std.ArrayList(u64).init(opt.allocator);
    defer distances.deinit();
    var singleDistance: u64 = 0;

    try reader.streamUntilDelimiter(lineBuffer.writer(), '\n', null);
    if (mem.indexOfScalar(u8, lineBuffer.items, ':')) |pos| {
        try extractNumbers(u64, lineBuffer.items[pos + 1 ..], &times);
        if (concatDigits(u64, 1024, lineBuffer.items[pos + 1 ..])) |number| {
            singleTime = number;
        } else {
            return Day06Error.NoNumberFound;
        }
    } else {
        return Day06Error.NoColonFound;
    }
    if (times.items.len == 0) {
        return Day06Error.NoNumberFound;
    }
    lineBuffer.clearRetainingCapacity();

    try reader.streamUntilDelimiter(lineBuffer.writer(), '\n', null);
    if (mem.indexOfScalar(u8, lineBuffer.items, ':')) |pos| {
        try extractNumbers(u64, lineBuffer.items[pos + 1 ..], &distances);
        if (concatDigits(u64, 1024, lineBuffer.items[pos + 1 ..])) |number| {
            singleDistance = number;
        } else {
            return Day06Error.NoNumberFound;
        }
    } else {
        return Day06Error.NoColonFound;
    }
    if (distances.items.len == 0) {
        return Day06Error.NoNumberFound;
    }
    lineBuffer.clearRetainingCapacity();

    var result = ParseResult{
        .possiblitiesProduct = 0,
        .singlePossiblities = 0,
    };

    for (times.items, distances.items) |time, distance| {
        const possiblities = getPossiblities(time, distance);
        if (result.possiblitiesProduct == 0) {
            result.possiblitiesProduct = possiblities;
        } else {
            result.possiblitiesProduct *= possiblities;
        }
    }
    result.singlePossiblities = getPossiblities(singleTime, singleDistance);

    return result;
}

test "parseRecords" {
    const parsed = try parseRecords(
        "adventofcode_2023_06_test_01.txt",
        .{ .allocator = testing.allocator },
    );
    try expect(288 == parsed.possiblitiesProduct);
    try expect(71503 == parsed.singlePossiblities);
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
    try stdout.print("possiblities single: {d}\n", .{result.singlePossiblities});
    try stdout.print(
        "time usage: {d} μs\n",
        .{time.microTimestamp() - start},
    );

    try stdoutBuffer.flush();
}
