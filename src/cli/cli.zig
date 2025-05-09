//命令行解析
const arg = @import("arg.zig");
const std = @import("std");
const variable = @import("../variable.zig");

/// 命令行处理；
pub const Arg = arg.Arg;

// 默认入口命令
fn defaultIndexFn(_: *Arg) void {
    std.debug.print("欢迎使用 zigUymas 库，请你注册 index\n\n", .{});
    std.debug.print("zig-uymas  v{s}/{s}\n", .{ variable.Version, variable.Release });
}

/// cli 应用处理器
pub const App = struct {
    // 内存分配其
    allocator: std.mem.Allocator,
    // 入口函数
    indexFn: *const fn (*Arg) void = defaultIndexFn,
    helpFn: ?*const fn (*Arg) void = null,
    args: ?*Arg = null,

    // 注册字典
    registersMap: std.StringHashMap(*const fn (*Arg) void),

    /// 初始化应用
    pub fn new(allocator: std.mem.Allocator) App {
        //报错：Segmentation fault at address 0xf5a8c00b70
        //var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        //const allocator = gpa.allocator();
        return App{
            .allocator = allocator,
            //.args = null,
            .registersMap = std.StringHashMap(*const fn (*Arg) void).init(allocator),
        };
    }

    /// 命令注册
    pub fn command(self: *App, name: []const u8, runFn: fn (*Arg) void) *App {
        self.registersMap.put(name, runFn) catch |err| {
            std.debug.print("registersMap 注册异常，{?}\n", .{err});
        };
        return self;
    }

    /// 命令注册多应用
    pub fn commandList(self: *App, nameList: []const []const u8, runFn: fn (*Arg) void) *App {
        for (nameList) |name| {
            _ = self.command(name, runFn);
        }
        return self;
    }

    /// 定义入口函数
    pub fn index(self: *App, runFn: fn (*Arg) void) void {
        self.indexFn = runFn;
    }

    /// 帮助命令
    pub fn help(self: *App, runFn: fn (*Arg) void) void {
        self.helpFn = runFn;
    }

    // 运行命令程序
    pub fn run(self: *App) !void {
        // var args = try Arg.new(std.heap.c_allocator);
        //const args = try Arg.new(self.allocator);
        const args_list = try std.process.argsAlloc(self.allocator);
        defer std.process.argsFree(self.allocator, args_list);
        const args = Arg.args(args_list[1..], self.allocator);

        //defer args.free();
        const vCommand = args.getCommand();

        self.args = @constCast(&args);
        if (vCommand.len == 0) {
            self.indexFn(self.args.?);
            return;
        }

        // 注册命令
        if (self.registersMap.get(vCommand)) |callFn| {
            callFn(self.args.?);
            return;
        }

        // 帮助命令
        if (std.mem.eql(u8, vCommand, "help") or std.mem.eql(u8, vCommand, "?")) {
            if (self.helpFn) |helpFn| {
                helpFn(self.args.?);
                return;
            }
        }

        // 命令不存在
        std.debug.print("{s}: 命令不存在，请查看文帮助后重试\n", .{vCommand});
    }

    /// 内容释放
    pub fn free(self: *App) void {
        // 参数内容释放
        // if (self.args) |vArgs| {
        //     vArgs.free();
        // }
        // 字典内存释放
        self.registersMap.deinit();
    }
};
