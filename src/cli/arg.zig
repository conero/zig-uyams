const std = @import("std");

/// 命令解析
pub const Arg = struct {
    /// 命令
    command: []const u8 = "",
    osArgsList: ?[][:0]u8 = null, // 操作系统命令列表
    /// 选项
    //options: [][:0]u8,
    allocator: ?std.mem.Allocator = null,

    /// 使用命令参数示例化参数
    pub fn new(allocator: std.mem.Allocator) !*Arg {
        const args_list = try std.process.argsAlloc(allocator);
        //defer std.process.argsFree(std.heap.c_allocator, args_list);
        var mySelf = Arg.args(args_list[1..]);
        //mySelf.osArgsList = args_list;
        mySelf.osArgsList = args_list;
        mySelf.allocator = allocator;
        return mySelf;
    }

    /// 指定参数列表来解析命令行
    pub fn args(argsList: [][:0]u8) *Arg {
        var command: []u8 = "";
        for (argsList, 0..) |arg, index| {
            //std.debug.print(" => {d} -> {s}\n", .{ index, arg });
            const dOpt = detectOption(arg, true);
            if (dOpt.@"1") {
                continue;
            }
            // 认定第一个参数为命令行
            if (command.len == 0 and index == 0) {
                //std.debug.print("arg: {s}\n", .{arg});
                command = arg;
            }
        }

        var initArg = Arg{
            .command = command,
        };
        return &initArg;
    }

    /// 获取命令
    pub fn getCommand(self: *Arg) []const u8 {
        //std.debug.print("self.command: {s}, len: {d}\n", .{ self.command, self.command.len });
        return self.command;
    }

    /// 内存释放
    pub fn free(self: *Arg) void {
        if (self.osArgsList) |osArgs| {
            if (self.allocator) |allocator| {
                std.process.argsFree(allocator, osArgs);
            }
        }
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
