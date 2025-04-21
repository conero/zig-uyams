// 2025年4月12日
// 新增用例
const uymas = @import("uymas");
const std = @import("std");

// 内容示例
pub fn main() !void {
    // 命令行运行
    var app = uymas.cli.App.new();
    defer app.free();

    // 命令注册
    //    app.commandList([_]*const [:0]u8{ @as(u8, "help"), @as(u8, "?") }, helpCmd);
    // 入口函数
    app.index(indexCmd);
    try app.run();
    //_ = try uymas.cli.Arg.new();
}

fn indexCmd(_: *const uymas.cli.Arg) void {
    std.debug.print("uymas 命令行程序\n", .{});
    std.debug.print("巧巧，你好呀\n", .{});
    std.debug.print("数据类型：{}\n", .{@TypeOf(uymas.Version)});
}

// 帮助文件信息
fn helpCmd(param: *const uymas.cli.Arg) void {
    std.debug.print("commond: {s}", .{param.command});
}
