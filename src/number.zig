const std = @import("std");

/// 字符串转数字，支持如"100_000"、"100,000"这种带下划线的数字
///
/// 支持 123.10K（K/千，W/万，M/百万，B/亿，T/Tensor） 等英文标识
///
/// 支持 123.10万（百、千、万、亿） 等英文标识
pub fn strToInt(alloc: std.mem.Allocator, vNumber: []const u8) i128 {
    // 操作代码（实际编译错误）： https://github.com/capy-ui/capy/blob/4d41d962e6d0404a7beb9c37c1a5ba68556f9efb/src/assets.zig#L51
    const rplSize = std.mem.replacementSize(u8, vNumber, ",", "");
    const rplStr = alloc.alloc(u8, rplSize) catch unreachable;
    _ = std.mem.replace(u8, vNumber, ",", "", rplStr);
    //_ = std.mem.replace(u8, rplStr, ",", "", rplStr);
    std.debug.print("strToInt: {s}\n", .{rplStr});
    return 0;
}

test "strToInt base test" {
    strToInt(std.testing.allocator, "100_000");
    try std.testing.expectEqual(strToInt("100_000"), 100000);
}
