// 2025年4月12日
// 新增用例
const uymas = @import("uymas");
const std = @import("std");

// 内容示例
pub fn main() !void {
    // 使用 arena allocator 简化内存管理
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    // 命令行运行
    var app = uymas.cli.App.new(allocator);
    //defer app.free();

    // test
    _ = app.command("test", testCmd);
    // 命令注册
    // app.commandList([_]*const [:0]u8{ @as(u8, "help"), @as(u8, "?") }, helpCmd);
    const vDemoCmd = [_][]const u8{ "demo", "dm" };
    _ = app.commandList(&vDemoCmd, demoCmd);
    // 入口函数
    app.index(indexCmd);
    app.help(helpCmd);
    try app.run();
}

// 默认入口
fn indexCmd(_: *uymas.cli.Arg) void {
    std.debug.print("这是 zig uymas 命令行基础程序\n\n", .{});
    std.debug.print("巧巧，你好呀\n", .{});
    std.debug.print("数据类型：{}\n", .{@TypeOf(uymas.Version)});
    std.debug.print("\n\n版本信息： v{s}/{s}\n", .{ uymas.Version, uymas.Release });
}

// 帮助命令
fn helpCmd(_: *uymas.cli.Arg) void {
    std.debug.print("欢迎使用 uymas 框架实现 cli 的命令解析\n", .{});
    std.debug.print("  test    测试命令\n", .{});
    std.debug.print("  demo    示例多命令注册（dm）\n", .{});
    std.debug.print("\n", .{});
}

// 测试命令
fn testCmd(param: *uymas.cli.Arg) void {
    // 内存分配
    // @todo 内存泄露
    // 使用模型，一定要是变量，不能是常量
    //var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // 拿到一个allocator
    // const allocator = gpa.allocator();
    // defer 用于执行general_purpose_allocator善后工作
    // defer {
    //    const deinit_status = gpa.deinit();
    //    if (deinit_status == .leak) @panic("TEST FAIL");
    //}

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // 业务执行
    std.debug.print("---- test ---- \n", .{});
    // 异常：error.Unexpected: GetLastError(998): 内存位置访问无效。
    std.debug.print("commond: {s}\n", .{param.getCommand()});

    // 选项
    const optList = param.getOptList();
    if (std.mem.join(allocator, ", ", optList)) |joinOpt| {
        std.debug.print("option({d}): {s}\n", .{ optList.len, joinOpt });
    } else |err| {
        std.debug.print("option join 错误，{?}", .{err});
    }
    std.debug.print("\n", .{});
}

// demo 命令
fn demoCmd(_: *uymas.cli.Arg) void {
    std.debug.print("---- demo(dm) ---- \n\n", .{});
    std.debug.print("这是一个示例命令……", .{});
}
