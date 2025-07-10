const std = @import("std");

/// 字符串转数字，支持如"100_000"、"100,000"这种带下划线的数字
///
/// 支持 123.10K（K/千，W/万，M/百万，B/亿） 等英文标识
///
/// 支持 123.10万（百、千、万、亿） 等英文标识
/// @todo 中文字符串支持
pub fn strToInt(alloc: std.mem.Allocator, vNumber: []const u8) isize {
    if (vNumber.len == 0) {
        return 0;
    }
    const rplStr = alloc.alloc(u8, 2048) catch unreachable;
    defer alloc.free(rplStr);

    // ,
    var rplSize = std.mem.replacementSize(u8, vNumber, ",", "");
    _ = std.mem.replace(u8, vNumber, ",", "", rplStr);
    var support1 = rplStr[0..rplSize];

    // _
    rplSize = std.mem.replacementSize(u8, support1, "_", "");
    _ = std.mem.replace(u8, support1, "_", "", rplStr);
    support1 = rplStr[0..rplSize];

    // 基数
    var base: isize = 1;
    switch (support1[support1.len - 1]) {
        'K', 'k' => base = 1000,
        'W', 'w' => base = 10_000,
        'M', 'm' => base = 1_000_000,
        'B', 'b' => base = 1_000_000_000,
        else => base = 1,
    }

    // 含基数，支持 float 转 int
    if (base > 1) {
        const vFloat = std.fmt.parseFloat(f64, support1[0 .. support1.len - 1]) catch |err| {
            std.debug.print("字符串转数字错误，{any}\n", .{err});
            return 0;
        };

        const baseFloat: f64 = @floatFromInt(base);
        const floatToInt: isize = @intFromFloat(vFloat * baseFloat);
        return floatToInt;
    }

    // 含 . 则转 float
    if (std.mem.indexOfScalar(u8, support1, '.')) |_| {
        const vF64 = std.fmt.parseFloat(f64, support1) catch |err| {
            std.debug.print("字符串转数字错误，{any}\n", .{err});
            return 0;
        };
        return @intFromFloat(vF64);
    }

    // 不含基数，支持 string 转 int
    const value = std.fmt.parseInt(isize, support1, 10) catch |err| {
        std.debug.print("字符串转数字错误，{any}\n", .{err});
        return 0;
    };

    return value * base;
}

/// 字符串转数字，支持如"100_000"、"100,000"这种带下划线的数字
///
/// 支持 123.10K（K/千，W/万，M/百万，B/亿） 等英文标识
///
/// 支持 123.10万（百、千、万、亿） 等英文标识
/// @todo 中文字符串支持
pub fn strToF64(alloc: std.mem.Allocator, vNumber: []const u8) ?f64 {
    if (vNumber.len == 0) {
        return 0;
    }
    const rplStr = alloc.alloc(u8, 2048) catch unreachable;
    defer alloc.free(rplStr);

    // ,
    var rplSize = std.mem.replacementSize(u8, vNumber, ",", "");
    _ = std.mem.replace(u8, vNumber, ",", "", rplStr);
    var support1 = rplStr[0..rplSize];

    // _
    rplSize = std.mem.replacementSize(u8, support1, "_", "");
    _ = std.mem.replace(u8, support1, "_", "", rplStr);
    support1 = rplStr[0..rplSize];

    // 基数
    var base: isize = 1;
    switch (support1[support1.len - 1]) {
        'K', 'k' => base = 1000,
        'W', 'w' => base = 10_000,
        'M', 'm' => base = 1_000_000,
        'B', 'b' => base = 1_000_000_000,
        else => base = 1,
    }

    // 含基数，支持 float 转 int
    if (base > 1) {
        const vFloat = std.fmt.parseFloat(f64, support1[0 .. support1.len - 1]) catch |err| {
            std.debug.print("字符串转数字错误，{any}\n", .{err});
            return 0;
        };

        const baseFloat: f64 = @floatFromInt(base);
        return vFloat * baseFloat;
    }

    // 含 . 则转 float
    if (std.mem.indexOfScalar(u8, support1, '.')) |_| {
        const vF64 = std.fmt.parseFloat(f64, support1) catch |err| {
            std.debug.print("字符串转数字错误，{any}\n", .{err});
            return null;
        };
        return vF64;
    }

    // 不含基数，支持 string 转 int
    const value = std.fmt.parseInt(isize, support1, 10) catch |err| {
        std.debug.print("字符串转数字错误，{any}\n", .{err});
        return 0;
    };

    return @floatFromInt(value * base);
}

/// 数字压缩或简化，如 1000 转为 1K，10000 转为 10W
pub fn simplify(alloc: std.mem.Allocator, vNumber: isize) []u8 {
    var simStr: []u8 = undefined;
    if (std.fmt.allocPrint(alloc, "{d}", .{vNumber})) |baseStr| {
        simStr = baseStr;
    } else |err| {
        std.debug.print("字符串转数字错误，{any}\n", .{err});
        simStr = "";
    }
    const asF64: f64 = @floatFromInt(vNumber);
    if (vNumber >= 1_000_000_000) {
        const value: f64 = asF64 / 1_000_000_000;
        if (std.fmt.allocPrint(alloc, "{d}B", .{value})) |baseStr| {
            simStr = baseStr;
        } else |err| {
            std.debug.print("字符串转数字错误，{any}\n", .{err});
            return simStr;
        }
    } else if (vNumber >= 1_000_000) {
        const value: f64 = asF64 / 1_000_000;
        if (std.fmt.allocPrint(alloc, "{d}M", .{value})) |baseStr| {
            simStr = baseStr;
        } else |err| {
            std.debug.print("字符串转数字错误，{any}\n", .{err});
            return simStr;
        }
    } else if (vNumber >= 1_000) {
        const value: f64 = asF64 / 1_000;
        if (std.fmt.allocPrint(alloc, "{d}K", .{value})) |baseStr| {
            simStr = baseStr;
        } else |err| {
            std.debug.print("字符串转数字错误，{any}\n", .{err});
            return simStr;
        }
    }

    return simStr;
}

/// 字节大小转换
pub fn formatSize(bytes: u64) []u8 {
    const units = [_][]const u8{ "B", "KiB", "MiB", "GiB", "TiB", "PiB", "EiB", "ZiB", "YiB" };
    var size: f64 = @floatFromInt(bytes);
    var unit_index: usize = 0;

    while (size >= 1024.0 and unit_index < units.len - 1) {
        unit_index += 1;
        size /= 1024.0;
    }

    var buffer: [20]u8 = undefined;
    const formatted = std.fmt.bufPrint(buffer[0..], "{any} {s}", .{ size, units[unit_index] }) catch |err| {
        std.debug.print("字符串转数字错误，{any}\n", .{err});
        return "";
    };
    return formatted;
}

test "strToInt base test" {
    // case 1
    var vNum = strToInt(std.heap.smp_allocator, "100_000");
    try std.testing.expectEqual(vNum, 100000);

    // case 2
    vNum = strToInt(std.heap.smp_allocator, "100,189");
    try std.testing.expectEqual(vNum, 100189);

    // case 3
    vNum = strToInt(std.heap.smp_allocator, "");
    try std.testing.expectEqual(vNum, 0);

    // case 4
    vNum = strToInt(std.heap.smp_allocator, "3.14K");
    try std.testing.expectEqual(vNum, 3140);

    // case 5
    vNum = strToInt(std.heap.smp_allocator, "68.762391");
    try std.testing.expectEqual(vNum, 68);
}

test "strToF64 base test" {
    // case 1
    var vNum = strToF64(std.heap.smp_allocator, "100_000") catch 0;
    try std.testing.expectEqual(vNum, 100000);

    // case 2
    vNum = strToF64(std.heap.smp_allocator, "100,189") catch 0;
    try std.testing.expectEqual(vNum, 100189);

    // case 3
    vNum = strToF64(std.heap.smp_allocator, "");
    try std.testing.expectEqual(vNum, 0);

    // case 4
    vNum = strToF64(std.heap.smp_allocator, "3.14K");
    try std.testing.expectEqual(vNum, 3140);

    // case 5
    vNum = strToF64(std.heap.smp_allocator, "68.762391");
    try std.testing.expectEqual(vNum, 68);
}

test "simplify base test" {
    var vNum = simplify(std.heap.smp_allocator, 100000);
    try std.testing.expectEqualSlices(u8, vNum, "100K");

    vNum = simplify(std.heap.smp_allocator, 1992);
    try std.testing.expectEqualSlices(u8, vNum, "1.992K");
}
