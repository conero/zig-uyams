// 2025年4月12日
// 新增用例
const uymas = @import("uymas");
const std = @import("std");
const builtin = @import("builtin");

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
    _ = app.commandWith("test", uymas.cli.RegisterItem{
        .execFn = testCmd,
        .validateAble = false, // 关闭选项验证
    });

    // 命令注册
    var timeOptionList = std.ArrayList(uymas.cli.Option).init(allocator);
    try timeOptionList.append(uymas.cli.Option{ .name = "tz" });
    app.commandWith("time", uymas.cli.RegisterItem{
        .execFn = timeCmd,
        .options = timeOptionList,
    });
    _ = app.command("version", versionCmd);
    // 命令注册
    // app.commandList([_]*const [:0]u8{ @as(u8, "help"), @as(u8, "?") }, helpCmd);
    const vDemoCmd = [_][]const u8{ "demo", "dm" };
    _ = app.commandList(&vDemoCmd, demoCmd);
    // 入口函数
    app.index(indexCmd);
    app.help(helpCmd);
    app.endHook = endHook;
    try app.run();
}

// 默认入口
fn indexCmd(arg: *uymas.cli.Arg) void {
    // -test
    if (arg.checkOpt("test")) {
        testCmd(arg);
        return;
    }
    // -version
    if (arg.checkOpt("version")) {
        versionCmd(arg);
        return;
    }
    std.debug.print("这是 zig uymas 命令行基础程序\n\n", .{});
    std.debug.print("巧巧，你好呀\n", .{});
    std.debug.print("数据类型：{}\n", .{@TypeOf(uymas.Version)});
    std.debug.print("\n\n版本信息： v{s}/{s}\n", .{ uymas.Version, uymas.Release });

    // Windows 系统
    if (builtin.target.os.tag == .windows) {
        std.debug.print("Use the following command for garbled Chinese characters in Windows PowerShell environment：\n", .{});
        std.debug.print("    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8\n", .{});
    }
}

// 帮助命令
fn helpCmd(_: *uymas.cli.Arg) void {
    std.debug.print("欢迎使用 uymas 框架实现 cli 的命令解析\n", .{});
    std.debug.print("  test            测试命令\n", .{});
    std.debug.print("       -for       用于测试循环多次花费的时间\n", .{});
    std.debug.print("       -sum       for进行累加，用于程序执行用时统计\n", .{});
    std.debug.print("       -inline,-I for进行累加，且单行输出\n", .{});
    std.debug.print("       -print,-P  是否输出结果\n", .{});
    std.debug.print("       -data      设置选项时将输出全部的数据\n", .{});
    std.debug.print("       -exec ..   设置命令并执行它\n", .{});
    std.debug.print("       -exec-1    使用命令行执行方式1，用于测试\n", .{});
    std.debug.print("  demo            示例多命令注册（dm）\n", .{});
    std.debug.print("  time            实时显示当前时间\n", .{});
    std.debug.print("       -tz [UTC]  指定时区\n", .{});
    std.debug.print("  version         版本信息输出\n", .{});
    std.debug.print("\n  全局选项        \n", .{});
    std.debug.print("       -version   数据版本信息\n", .{});
    std.debug.print("       -test      测试命令\n", .{});
    std.debug.print("\n", .{});
}

// 测试命令
//
// pwsh: for ($i = 0; $i -lt 20; $i++){$get = .\zig-out\bin\zuymas.exe -test -for 0.034597401B -sum -inline;echo "「$($i+1)」-> $get";}
fn testCmd(arg: *uymas.cli.Arg) void {
    const spendFn = uymas.util.spendFn().begin();
    const isPrint = arg.checkOpt("print") or arg.checkOpt("P");
    const isInline = arg.checkOpt("inline") or arg.checkOpt("I");
    defer {
        if (!isInline) {
            std.debug.print("耗时：{d:.3}ms\n", .{spendFn.milliEnd()});
        }
    }

    const setSum = arg.checkOpt("sum");
    var sumValue: u64 = 0;
    // for 循环
    if (arg.getInt("for")) |forNum| {
        const forNumPos = @as(usize, @intCast(forNum)); // 正整数
        for (0..forNumPos) |vN| {
            if (setSum) {
                sumValue += @as(u64, @intCast(vN)) + 1;
            }
            if (!isPrint or isInline) {
                continue;
            }
            // 「\r」  回车(CR) ，将当前位置移到本行开头
            std.debug.print("\rIndex: {d} ", .{vN + 1});
        }
        if (isInline) {
            const spendMill = spendFn.milliEnd();
            if (setSum) {
                std.debug.print("本次耗时：{d:.3}ms， 累加值：{d}，循环数 {d}", .{ spendMill, sumValue, forNum });
                return;
            }
            std.debug.print("本次耗时：{d:.3}ms，循环数 {d}", .{ spendMill, forNum });
            return;
        }
        std.debug.print("\n\n", .{});
        std.debug.print("本次已完成 {d} 次循环\n", .{forNum});
        if (setSum) {
            std.debug.print("本次累加值结果为 {d}\n", .{sumValue});
        }
        return;
    }

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // 业务执行
    std.debug.print("---- test ---- \n", .{});
    // 异常：error.Unexpected: GetLastError(998): 内存位置访问无效。
    std.debug.print("commond: {s}\n", .{arg.getCommand()});

    // 选项
    const optList = arg.getOptList();
    if (std.mem.join(allocator, ", ", optList)) |joinOpt| {
        std.debug.print("option({d}): {s}\n", .{ optList.len, joinOpt });
    } else |err| {
        std.debug.print("option join 错误，{?}", .{err});
    }

    // 数据打印
    if (arg.checkOpt("data")) {
        std.debug.print("\n---- data ---- \n", .{});
        var iter = arg.optionKvEntry.iterator();
        while (iter.next()) |each| {
            std.debug.print("    {s}: {s}\n", .{ each.key_ptr.*, each.value_ptr.* });
        }
        std.debug.print("\n", .{});
    }

    // 设置命令并执行它
    if (arg.getList("exec")) |toRunCmd| {
        std.debug.print("\n---- exec ---- \n", .{});
        if (std.mem.join(allocator, " ", toRunCmd)) |joinOpt| {
            std.debug.print("执行命令：{s}\n", .{joinOpt});
        } else |err| {
            std.debug.print("join 错误，{?}\n", .{err});
        }

        if (arg.checkOpt("exec-1")) { // 方式1，用于测试
            std.debug.print("使用实验性的方法 1 进行命令执行……\n", .{});
            const result = uymas.cli.execAlloc(toRunCmd, allocator) catch |err| {
                std.debug.print("执行命令错误，{?}\n", .{err});
                return;
            };

            std.debug.print("---- exec result ---- \n", .{});
            std.debug.print("输出内容如下：\n{s}", .{result.stdout});
            std.debug.print("\n----- EXIT CODE: {} -----\n", .{result.exit_code});
        } else {
            const result = uymas.cli.execAlloc(toRunCmd, allocator) catch |err| {
                std.debug.print("执行命令错误，{?}\n", .{err});
                return;
            };

            std.debug.print("---- exec result ---- \n", .{});
            std.debug.print("输出内容如下：\n{s}", .{result.stdout});
            std.debug.print("\n----- EXIT CODE: {} -----\n", .{result.exit_code});
        }
    }

    // cwd
    std.debug.print("\n---- info ---- \n", .{});
    if (std.process.getCwdAlloc(allocator)) |cwdPath| {
        std.debug.print("CWD: {s}\n", .{cwdPath});
    } else |err| {
        std.debug.print("CWD 获取错误，{?}", .{err});
    }
    std.debug.print("Root: {s}\n", .{uymas.cli.rootPath(allocator)});

    // 系统参数
    std.debug.print("操作系统：{any}, 架构： {any}\n", .{ builtin.os.tag, builtin.cpu.arch });
    std.debug.print("zig 编译版本： {s}\n", .{builtin.zig_version_string});
    std.debug.print("当前的 abi： {any}\n", .{builtin.abi});
    std.debug.print("random: {d}\n", .{get_random().int(u64)});
    if (std.process.totalSystemMemory()) |total_mem| {
        std.debug.print("内存大小： {d}B\n", .{total_mem});
    } else |err| {
        std.debug.print("获取内存失败： {s}\n", .{@errorName(err)});
    }
    std.debug.print("\n", .{});
}

// demo 命令
fn demoCmd(_: *uymas.cli.Arg) void {
    std.debug.print("---- demo(dm) ---- \n\n", .{});
    std.debug.print("这是一个示例命令……", .{});
}

// 时间测试
fn timeCmd(arg: *uymas.cli.Arg) void {
    const tzIndex = arg.getInt("tz") orelse 8;
    std.debug.print("基于当前本地系统时间（UTC-{d}）\n\n", .{tzIndex});
    while (true) {
        std.time.sleep(std.time.ns_per_s);
        var now = uymas.date.Date.now();
        std.debug.print("\r👉 {s}", .{now.cnTime().timeStringTz(std.heap.smp_allocator, tzIndex)});
    }
}

// 版本信息
fn versionCmd(_: *uymas.cli.Arg) void {
    std.debug.print("v{s}/{s}", .{ uymas.Version, uymas.Release });
}

// 结束
fn endHook(_: *uymas.cli.Arg) void {
    std.debug.print("\n", .{});
}

// 执行并捕获输出
fn runAndCaptureOutput(allocator: std.mem.Allocator, cmd: [][]const u8) !struct {
    stdout: []u8,
    stderr: []u8,
    exit_code: i32,
} {
    var child = std.process.Child.init(cmd, allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    try child.spawn();

    const stdout = try child.stdout.?.reader().readAllAlloc(allocator, 1024 * 1024);
    const stderr = try child.stderr.?.reader().readAllAlloc(allocator, 1024 * 1024);

    const term = try child.wait();
    const exit_code = switch (term) {
        .Exited => |code| code,
        else => 0,
    };

    return .{
        .stdout = stdout,
        .stderr = stderr,
        .exit_code = exit_code,
    };
}

// 获取数据数字
fn get_random() std.Random {
    var rng_inner = std.Random.DefaultPrng.init(@intCast(std.time.milliTimestamp()));
    return std.Random.init(&rng_inner, std.Random.DefaultPrng.fill);
}
