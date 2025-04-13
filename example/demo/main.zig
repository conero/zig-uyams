// 2025年4月12日
// 新增用例
const uymas = @import("uymas");
const std = @import("std");

// 内容示例
pub fn main() !void {
    std.debug.print("uymas 命令行程序\n", .{});
    std.debug.print("巧巧，你好呀\n", .{});
    std.debug.print("数据类型：{}\n", .{@TypeOf(uymas.Version)});

    // 命令行运行
    var app = uymas.cli.App.new();
    app.run();

    _ = try uymas.cli.Arg.new();
}
