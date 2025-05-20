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

    // 不含基数，支持 int 转 int
    const value = std.fmt.parseInt(isize, support1, 10) catch |err| {
        std.debug.print("字符串转数字错误，{any}\n", .{err});
        return 0;
    };

    return value * base;
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
}
