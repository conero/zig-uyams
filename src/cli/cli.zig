//命令行解析
const arg = @import("arg.zig");
const std = @import("std");
const variable = @import("../variable.zig");

/// 命令行处理；
pub const Arg = arg.Arg;

// 默认入口命令
fn defaultIndexFn(_: *const Arg) void {
    std.debug.print("欢迎使用 zigUymas 库，请你注册 index\n\n", .{});
    std.debug.print("zig-uymas  v{s}/{s}\n", .{ variable.Version, variable.Release });
}

/// cli 应用处理器
pub const App = struct {
    // 入口函数
    indexFn: *const fn (*const Arg) void = defaultIndexFn,
    args: ?*Arg = null,

    /// 初始化应用
    pub fn new() App {
        return App{
            //.args = null,
        };
    }

    /// 命令注册
    pub fn command(self: *App, name: []8, runFn: fn (*Arg) void) void {
        _ = self;
        _ = name;
        _ = runFn;
        // @todo 待实现
    }

    /// 定义入口函数
    pub fn index(self: *App, runFn: fn (*const Arg) void) void {
        self.indexFn = runFn;
    }

    // 运行命令程序
    pub fn run(self: *App) !void {
        var args = try Arg.new();
        const vCommand = args.getCommand();

        self.args = args;
        // std.debug.print("vCommand: {s}, vlen: {d}\n", .{ vCommand, vCommand.len });
        if (vCommand.len == 0) {
            self.indexFn(args);
            return;
        }

        std.debug.print("\n正在启动命令行\n   ...need todo.\n", .{});

        // @todo 待实现
        // ...
    }

    /// 内容释放
    pub fn free(self: *App) void {
        if (self.args) |vArgs| {
            vArgs.free();
        }
    }
};
