const std = @import("std");

/// 字符串转数字，支持如"100_000"、"100,000"这种带下划线的数字
///
/// 支持 123.10K（K/千，W/万，M/百万，B/亿，T/Tensor） 等英文标识
///
/// 支持 123.10万（百、千、万、亿） 等英文标识
pub fn strToInt(alloc: std.mem.Allocator, vNumber: []const u8) isize {
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

    std.debug.print("str: {s}\n", .{support1});
    return std.fmt.parseInt(isize, support1, 10) catch |err| {
        std.debug.print("字符串转数字错误，{any}\n", .{err});
        return 0;
    };
}

test "strToInt base test" {
    // case 1
    var vNum = strToInt(std.heap.smp_allocator, "100_000");
    try std.testing.expectEqual(vNum, 100000);

    // case 2
    vNum = strToInt(std.heap.smp_allocator, "100,189");
    try std.testing.expectEqual(vNum, 100189);
}
