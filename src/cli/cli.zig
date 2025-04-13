//命令行解析
const arg = @import("arg.zig");
const std = @import("std");

/// 命令行处理；
pub const Arg = arg.Arg;

/// cli 应用处理器
pub const App = struct {
    /// 初始化应用
    pub fn new() App {
        return App{};
    }
    // 运行命令程序
    pub fn run(self: *App) void {
        std.debug.print("\n正在启动命令行\n   ...need todo.\n", .{});
        // @todo 待实现
        _ = self;
    }
};
