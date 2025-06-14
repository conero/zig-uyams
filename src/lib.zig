//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const variable = @import("variable.zig");
const testing = std.testing;

/// 命令行解析
pub const cli = @import("cli/cli.zig");
/// 版本号
pub const Version = variable.Version;
/// 发布日期
pub const Release = variable.Release;
/// 工具辅助处理库
pub const util = @import("util.zig");
/// 数字处理库
pub const number = @import("number.zig");
/// 日期处理库
pub const date = @import("date.zig");
/// 字符串处理库
pub const string = @import("string.zig");
