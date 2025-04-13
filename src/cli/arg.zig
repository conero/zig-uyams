const std = @import("std");

/// 命令解析
pub const Arg = struct {
    /// 命令
    command: []u8 = "",
    /// 选项
    //options: [][:0]u8,
    //allocator: std.mem.Allocator,

    /// 使用命令参数示例化参数
    pub fn new() !*const Arg {
        const args_list = try std.process.argsAlloc(std.heap.c_allocator);
        defer std.process.argsFree(std.heap.c_allocator, args_list);
        return Arg.args(args_list[1..]);
    }

    /// 指定参数列表来解析命令行
    pub fn args(argsList: [][:0]u8) *const Arg {
        var command: []u8 = "";
        for (argsList, 0..) |arg, index| {
            std.debug.print("{d} -> {s}\n", .{ index, arg });
            const dOpt = detectOption(arg, true);
            if (dOpt.@"1") {
                continue;
            }
            if (command.len == 0) {
                command = arg;
            }
        }
        return &Arg{
            .command = command,
        };
    }
};

/// 检测变量是否为选项
pub fn detectOption(vString: []u8, supportLong: bool) struct { []u8, bool } {
    const vLen = vString.len;
    if (vLen == 0) {
        return .{ "", false };
    }

    // 长选项
    if (vLen > 1 and supportLong and std.mem.eql(u8, vString[0..2], "--")) {
        return .{ vString[2..], true };
    }

    if (vString[0] == '-') {
        return .{ vString[1..], true };
    }
    return .{ "", false };
}
