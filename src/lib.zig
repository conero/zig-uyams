//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const variable = @import("variable.zig");
const testing = std.testing;

// 命令行解析
pub const cli = @import("cli/cli.zig");
// 版本号
pub const Version = variable.Version;
// 发布日期
pub const Release = variable.Release;
// 工具辅助处理库
pub const util = @import("util.zig");

// 原示例代码
pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}
