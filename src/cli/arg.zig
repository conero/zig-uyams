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
        for (argsList, 0..) |arg, index| {
            std.debug.print("{d} -> {s}\n", .{ index, arg });
        }
        return &Arg{
            //.options = &[_][:0]u8{0},
        };
    }
};
