//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const testing = std.testing;

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

// 版本号
pub const Version = "0.0.1";
// 发布日期
pub const Release = "dev"; // dev|20060102

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}
