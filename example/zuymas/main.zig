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
    // app.config = uymas.cli.AppConfig{
    //     .strictValid = false,
    // };
    //defer app.free();

    // test
    _ = app.commandWith("test", uymas.cli.RegisterItem{
        .execFn = testCmd,
        .validateAble = false, // 关闭选项验证
    });

    // 命令注册
    var timeOptionList: std.ArrayList(uymas.cli.Option) = .empty;
    defer timeOptionList.deinit(allocator);
    try timeOptionList.append(allocator, .{ .name = "tz" });
    app.commandWith("time", uymas.cli.RegisterItem{
        .execFn = timeCmd,
        .options = timeOptionList,
    });
    _ = app.command("version", versionCmd);
    // 命令注册
    _ = app.commandList(&.{ "demo", "dm" }, demoCmd);

    // 网络命令
    _ = app.command("tell", tellCmd);
    _ = app.command("http", httpCmd);
    _ = app.command("echo", echoCmd);

    // 交互式输入测试
    _ = app.commandList(&.{ "interactive", "inter" }, interactCmd);
    // 文件读写测试
    _ = app.command("cat", catCmd);
    // 并发测试
    //_ = app.command("thread", threadCmd);
    var threadOptionList: std.ArrayList(uymas.cli.Option) = .empty;
    defer threadOptionList.deinit(allocator);

    try threadOptionList.append(allocator, .{ .name = "count" });
    try threadOptionList.append(allocator, .{ .name = "silent" });
    try threadOptionList.append(allocator, .{ .name = "sleep" });
    _ = app.commandWith("thread", uymas.cli.RegisterItem{
        .execFn = threadCmd,
        .options = threadOptionList,
    });

    // 执行命令行
    _ = app.command("exec", execCmd);

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
    std.debug.print("  tell [addr]     网络地址测试\n", .{});
    std.debug.print("  interact,inter  交互式输入参数\n", .{});
    std.debug.print("  cat [path]      文件读取或写入\n", .{});
    std.debug.print("  http [port]     监听http服务器，默认端口 18080\n", .{});
    std.debug.print("  echo [port]     监听tcp服务器，默认端口 18082\n", .{});
    std.debug.print("  exec [command]  执行执行的命令\n", .{});
    std.debug.print("  thread          并发测试\n", .{});
    std.debug.print("       -count [10]    指定并发数\n", .{});
    std.debug.print("       -sleep [1000]  指定睡眠数，毫秒级\n", .{});
    std.debug.print("       -silent        静默执行，不输出调试信息\n", .{});
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
    std.debug.print("subCommand: {s}\n", .{arg.getSubCommand()});

    // 选项
    const optList = arg.getOptList();
    if (std.mem.join(allocator, ", ", optList)) |joinOpt| {
        std.debug.print("option({d}): {s}\n", .{ optList.len, joinOpt });
    } else |err| {
        std.debug.print("option join 错误，{any}", .{err});
    }

    // 数据打印
    if (arg.checkOpt("data")) {
        std.debug.print("\n---- data ---- \n", .{});
        var iter = arg.optionKvEntry.iterator();
        while (iter.next()) |each| {
            // @todo 此处临时写法
            std.debug.print("    {any}: {any}\n", .{ each.key_ptr.*, each.value_ptr.* });
        }
        std.debug.print("\n", .{});
    }

    // 设置命令并执行它
    if (arg.getList("exec")) |toRunCmd| {
        std.debug.print("\n---- exec ---- \n", .{});
        if (std.mem.join(allocator, " ", toRunCmd)) |joinOpt| {
            std.debug.print("执行命令：{s}\n", .{joinOpt});
        } else |err| {
            std.debug.print("join 错误，{any}\n", .{err});
        }

        if (arg.checkOpt("exec-1")) { // 方式1，用于测试
            std.debug.print("使用实验性的方法 1 进行命令执行……\n", .{});
            const result = uymas.cli.execAlloc(toRunCmd, allocator) catch |err| {
                std.log.err("执行命令错误，{any}\n", .{err});
                return;
            };

            std.debug.print("---- exec result ---- \n", .{});
            std.debug.print("输出内容如下：\n{s}", .{result.stdout});
            std.debug.print("\n----- EXIT CODE: {} -----\n", .{result.exit_code});
        } else {
            const result = uymas.cli.execAlloc(toRunCmd, allocator) catch |err| {
                std.log.err("执行命令错误，{any}\n", .{err});
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
        std.debug.print("CWD 获取错误，{any}", .{err});
    }
    std.debug.print("Root: {s}\n", .{uymas.cli.rootPath(allocator)});

    // 系统参数
    std.debug.print("操作系统：{any}, 架构： {any}\n", .{ builtin.os.tag, builtin.cpu.arch });
    std.debug.print("zig 编译版本： {s}\n", .{builtin.zig_version_string});
    std.debug.print("当前的 abi： {any}\n", .{builtin.abi});
    std.debug.print("random: {d}\n", .{get_random().int(u64)});
    std.debug.print("thread ID: {d}\n", .{std.Thread.getCurrentId()});
    const cpuCpunt = std.Thread.getCpuCount() catch 0;
    std.debug.print("CPU数量： {d}\n", .{cpuCpunt});
    if (std.process.totalSystemMemory()) |total_mem| {
        std.debug.print("内存大小： {s} (字节={d})\n", .{ uymas.number.formatSizeAlloc(allocator, total_mem), total_mem });
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
        std.Thread.sleep(std.time.ns_per_s);
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

// 网络测试命令
fn tellCmd(arg: *uymas.cli.Arg) void {
    var addr: []u8 = uymas.string.mutable("127.0.0.1:80");
    if (arg.subCommand.len > 0) {
        addr = uymas.string.mutable(arg.subCommand);
    }

    // 图片分割
    var splitIter = std.mem.splitAny(u8, addr, ":");
    var port: u16 = 80;
    var host: []u8 = uymas.string.mutable("127.0.0.1");
    var index: usize = 0;
    while (splitIter.next()) |next| {
        if (index == 0) {
            host = uymas.string.mutable(next);
        } else if (index == 1) { // 端口号
            port = std.fmt.parseInt(u16, next, 10) catch 80;
        }
        index += 1;
    }

    // 地址解析
    const reqAddrResult = std.net.Address.parseIp4(host, port);
    var reqAddr: std.net.Address = undefined;
    if (reqAddrResult) |reqAddrOpt| {
        std.debug.print("请求地址: {any}\n", .{reqAddrOpt});
        reqAddr = reqAddrOpt;
    } else |err| {
        std.debug.print("地址（{s}:{d}）解析错误，{any}", .{ host, port, err });
        return;
    }
    //std.debug.print("测试地址 reqAddr: {any}\n", .{reqAddrResult});
    const stream = std.net.tcpConnectToHost(std.heap.page_allocator, host, port) catch |err| {
        std.log.err("无法连接到 {s}:{d}，{any}\n", .{ host, port, err });
        return;
    };
    std.debug.print("已连接到 {any}\n", .{stream});
    if (std.net.tcpConnectToAddress(reqAddr)) |conn| {
        defer conn.close();
        std.debug.print("连接成功\n", .{});
        std.debug.print("开始发送数据:{any}\n", .{conn});
    } else |err| {
        std.debug.print("连接错误，{any}\n", .{err});
        return;
    }
}

// 交互命令
fn interactCmd(_: *uymas.cli.Arg) void {
    @panic("待实现命令行交互测试……");
    // 获取标准输入流
    // var stdin_buffer: [1024]u8 = undefined;
    // const stdin = std.fs.File.stdin().reader(&stdin_buffer);
    // // 获取标准输出流（用于打印提示信息）
    // var stdout_buffer: [1024]u8 = undefined;
    // const stdout = std.fs.File.stdout().writer(&stdout_buffer);

    // // 打印提示信息
    // //stdout.print("inter> ", .{}) catch unreachable;
    // while (true) {
    //     // 创建缓冲区存储输入
    //     var buffer: [1024]u8 = undefined;
    //     // 读取输入，直到换行符或缓冲区满
    //     const input = stdin.readUntilDelimiterOrEof(&buffer, '\n') catch |err| {
    //         stdout.print("读取文件错误，{any}\n", .{err}) catch unreachable;
    //         break;
    //     };
    //     if (input) |ipt| {
    //         //const iptValue: []u8 = ipt;
    //         // 去除可能的回车符（Windows 系统）
    //         const iptValue = std.mem.trimRight(u8, ipt, "\r");
    //         if (std.mem.eql(u8, iptValue, "exit") or std.mem.eql(u8, iptValue, "quit")) {
    //             //if (std.mem.eql(u8, ipt, "exit") or std.mem.eql(u8, ipt, "quit")) {
    //             stdout.print("退出程序\n", .{}) catch unreachable;
    //             break;
    //         }
    //         stdout.print("输入数据(input)：{s}\n", .{ipt}) catch unreachable;
    //     }
    //     //stdout.print("输入数据：{any}\n", .{buffer}) catch unreachable;
    //     stdout.print("inter> ", .{}) catch unreachable;
    // }
}

// 文件读写测试
fn catCmd(arg: *uymas.cli.Arg) void {
    const filenamme = arg.getSubCommand();
    if (filenamme.len == 0) {
        std.debug.print("请先指定文件名", .{});
        return;
    }

    // 文件逐行读取
    var file = std.fs.cwd().openFile(filenamme, .{}) catch |err| {
        std.log.err("无法打开文件：{s}\n", .{@errorName(err)});
        return;
    };
    defer file.close();
    @panic("TODO: 逐行读取文件");

    // var buf_reader = std.io.bufferedReader(file.reader());
    //var tmpBuf: [1024]u8 = undefined;
    // var buf_reader = std.io.fixedBufferStream(file.reader(&tmpBuf));
    // var reader = buf_reader.reader();
    // var lineCount: usize = 0;
    // while (file.reader(&tmpBuf).readUntilDelimiterOrEofAlloc(std.heap.page_allocator, '\n', 1024) catch null) |line| {
    //     lineCount += 1;
    //     if (lineCount % 10 == 0) {
    //         _ = uymas.cli.input.optional("Entry to continue: ");
    //     }
    //     std.debug.print("{s}\n", .{line});
    // }

    // 文件一次性读取
    // 文件读取
    // var file = std.fs.cwd().openFile(filenamme, .{}) catch |err| {
    //     std.debug.print("无法打开文件：{s}\n", .{@errorName(err)});
    //     return;
    // };
    // defer file.close();
    // var buf: [1024]u8 = undefined;
    // var lineCount: usize = 0;
    // while (true) {
    //     lineCount += 1;
    //     const size = file.read(&buf) catch |err| {
    //         std.debug.print("无法读取文件：{s}\n", .{@errorName(err)});
    //         return;
    //     };
    //     if (size == 0) {
    //         break;
    //     }
    //     std.io.getStdOut().writeAll(buf[0..size]) catch |err| {
    //         std.debug.print("无法写入标准输出：{s}\n", .{@errorName(err)});
    //     };
    //     if (lineCount % 10 == 0){
    //         _ = uymas.cli.input.optional("Entry to continue: ");
    //     }
    // }
}

fn runEachThread(index: usize, isSilent: bool, sleepMs: usize) void {
    if (!isSilent) {
        std.debug.print("Thread {d} is running\n", .{index});
    }
    std.Thread.sleep(std.time.ns_per_ms * sleepMs);
    if (!isSilent) {
        std.debug.print("Thread {d} is done\n", .{index});
    }
}

// 并发测试命令
fn threadCmd(arg: *uymas.cli.Arg) void {
    const spendFn = uymas.util.spendFn().begin();
    // 匿名函数
    defer (struct {
        fn end(vSdFn: uymas.util.spendFn()) void {
            std.debug.print("\n耗时：{d:.2}ms\n", .{vSdFn.milliEnd()});
        }
    }).end(spendFn);
    const count = arg.getInt("count") orelse 10;
    const isSilent = arg.checkOpt("silent");
    var sleepMs = arg.getInt("sleep") orelse 1000;
    sleepMs = if (sleepMs > 0) sleepMs else 1000;
    const allocator = std.heap.page_allocator;
    const countUzie = @as(usize, @intCast(count));
    var threadGroup = allocator.alloc(std.Thread, countUzie) catch |err| {
        std.log.err("切片分配失败，Error: {s}\n", .{@errorName(err)});
        return;
    };

    // 执行进程
    for (0..countUzie) |i| {
        threadGroup[i] = std.Thread.spawn(.{}, runEachThread, .{ i, isSilent, @as(usize, @intCast(sleepMs)) }) catch |err| {
            std.log.err("创建线程失败，Error: {s}\n", .{@errorName(err)});
            continue;
        };
    }

    for (threadGroup) |thread| {
        thread.join();
    }
}

// 服务器访问
// @todo 服务器访问
fn httpCmd(arg: *uymas.cli.Arg) void {
    const subComd = arg.getSubCommand();
    var port: u16 = 0;
    if (subComd.len > 0) {
        port = std.fmt.parseInt(u16, subComd, 10) catch |err| {
            std.log.err("端口号错误，请输入数字 {s}. {any}\n", .{ subComd, err });
            return;
        };
    }
    port = if (port < 1) 18080 else port;

    std.debug.print("启动 HTTP 服务器，0.0.0.0:{d}\n", .{port});

    echoHttp(port) catch |err| {
        std.log.err("服务器启动失败，Error: {s}\n", .{@errorName(err)});
    };
}

// 启动服务器
fn echoHttp(port: u16) !void {
    const address = try std.net.Address.parseIp("0.0.0.0", port);
    var server = try address.listen(.{});
    defer server.deinit();

    // 服务器连接
    while (true) {
        const conn = server.accept() catch |err| {
            std.log.err("服务器连接失败，Error: {s}\n", .{@errorName(err)});
            continue;
        };

        // 处理http请求
        // handleHttp(conn) catch |err| {
        //     std.debug.print("处理http请求失败，Error: {s}\n", .{@errorName(err)});
        // };
        _ = std.Thread.spawn(.{}, handleHttpThread, .{conn}) catch |err| {
            std.log.err("处理http请求失败，Error: {s}\n", .{@errorName(err)});
            continue;
        };
    }
}

// 处理线程
fn handleHttpThread(conn: std.net.Server.Connection) void {
    std.log.debug("客户端连接成功，连接地址 {any}\n", .{conn.address});
    @panic("TODO: handleHttp");
    // handleHttp(conn) catch |err| {
    //     std.log.err("处理http请求失败，Error: {any}\n", .{@errorName(err)});
    // };
}

// 处理http请求
fn handleHttp(conn: std.net.Server.Connection) !void {
    defer conn.stream.close();

    var buf: [1024]u8 = undefined;
    var httpSv = std.http.Server.init(conn, &buf);

    // 文件读取
    while (httpSv.state == .ready) {
        var request = httpSv.receiveHead() catch |err| switch (err) {
            error.HttpConnectionClosing => return,
            else => return err,
        };
        std.debug.print("{any}: {s}\n", .{ request.head.method, request.head.target });

        // 内容读取
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();
        var reader = try request.reader();
        const contents = try reader.readAllAlloc(allocator, 4096);

        std.debug.print("读取到内容： {s}\n", .{contents});

        // 数据回写
        try request.respond(
            "Hello World，power from Joshua Conero!",
            .{
                .extra_headers = &.{
                    .{ .name = "custom header", .value = "custom value" },
                },
            },
        );
    }
}

fn echoCmd(arg: *uymas.cli.Arg) void {
    const subComd = arg.getSubCommand();
    var port: u16 = 0;
    if (subComd.len > 0) {
        port = std.fmt.parseInt(u16, subComd, 10) catch |err| {
            std.log.err("端口号错误，请输入数字 {s}. {any}\n", .{ subComd, err });
            return;
        };
    }
    port = if (port < 1) 18080 else port;

    std.debug.print("启动 TCP 服务器，0.0.0.0:{d}\n", .{port});

    echoHttp(port) catch |err| {
        std.log.err("服务器启动失败，Error: {s}\n", .{@errorName(err)});
    };
}

fn echoTcp(port: u16) !void {
    const address = try std.net.Address.parseIp("0.0.0.0", port);
    var server = try address.listen(.{});
    defer server.deinit();

    // 服务器连接
    while (true) {
        const conn = try server.accept();
        // defer conn.deinit();
        std.debug.print("服务器连接成功\n", .{});

        // 处理http请求
        try handleTcp(conn);
    }
}

// 处理http请求
fn handleTcp(conn: std.net.Server.Connection) !void {
    var buf: [1024]u8 = undefined;
    while (true) {
        const bytes_read = try conn.stream.read(&buf);
        if (bytes_read == 0) {
            std.debug.print("服务器关闭连接\n", .{});
            break;
        }

        std.debug.print("接收到数据: {s}\n", .{buf[0..bytes_read]});
    }
}

// 命令行执行
fn execCmd(arg: *uymas.cli.Arg) void {
    const subComd = arg.getSubCommand();
    if (subComd.len == 0) {
        std.log.err("请指定命令行", .{});
        return;
    }

    std.log.info("执行命令行: {s}\n", .{subComd});

    const allocator = std.heap.page_allocator;
    // const params: []const []const u8 = [_][]const u8{subComd};
    var child = std.process.Child.init(&.{subComd}, allocator);

    // 执行
    const term = child.spawnAndWait() catch |err| {
        std.log.err("执行命令行失败: {any}\n", .{err});
        return;
    };
    // if (trem != .Exited) {
    //     std.log.err("执行命令行失败: {any}\n", .{trem});
    //     return;
    // }
    switch (term) {
        .Exited => |v| std.log.err("执行命令行失败，{d}\n", .{v}),
        .Signal => |v| std.log.info("zig build was interrupted with signal: {d}", .{v}),
        .Stopped => |v| std.log.info("zig build was stopped with code: {d}", .{v}),
        .Unknown => |v| std.log.info("zig build encountered unknown: {d}", .{v}),
    }
}
