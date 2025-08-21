//命令行解析
const arg = @import("arg.zig");
const std = @import("std");
const variable = @import("../variable.zig");
const string = @import("../string.zig");

/// 命令行处理，以及导出库
pub const Arg = arg.Arg;
pub const input = @import("./input.zig");

// 默认入口命令
fn defaultIndexFn(_: *Arg) void {
    std.debug.print("欢迎使用 zigUymas 库，请你注册 index\n\n", .{});
    std.debug.print("zig-uymas  v{s}/{s}\n", .{ variable.Version, variable.Release });
}

// 命令行选项
pub const Option = struct {
    name: []const u8, // 选项名称
    alias: ?[]const []const u8 = null, // 选项别名
    help: ?[]const u8 = null, // 项目信息
    required: bool = false, // 是否必须
    rule: ?[]const u8 = null, // 验证规则，支持如："must,email,number,switch" 等。 @todo 待实现
    default: ?[]const u8 = null, // 默认值，
    isdata: bool = false, // 是否数据项（输入子命令）
    group: ?[]const u8 = null, // 后期用作分组文档生成

    // 获取选项值
    pub fn getValue(self: *const Option, args: *Arg) []const u8 {
        // 为数据值时，将子命令返回给命令行
        if (self.isdata) {
            const subCommnd = args.getSubCommand();
            if (subCommnd.len > 0) {
                return subCommnd;
            }
        }

        var value_option = args.get(self.name);
        if (value_option) |value| {
            return value;
        }

        // 获取别名
        if (self.alias) |alias| {
            for (alias) |aliasKey| {
                value_option = args.get(aliasKey);
                if (value_option) |value| {
                    return value;
                }
            }
        }

        // 获取默认值
        return self.default orelse "";
    }

    /// 选项是否设置
    pub fn exist(self: *const Option, args: *Arg) bool {
        if (args.checkOpt(self.name)) {
            return true;
        }

        // 别名
        if (self.alias) |alias| {
            for (alias) |aliasKey| {
                if (args.checkOpt(aliasKey)) {
                    return true;
                }
            }
        }

        // 默认值
        if (self.default) |default| {
            //std.mem.lowerString(u8, default);//
            //return std.mem.eql(u8, std.mem.lowerString(u8, default), "true"); // 字符串转小写实现
            return std.mem.eql(u8, default, "true");
        }

        return false;
    }

    /// 是否通过验证
    pub fn validate(self: *const Option, args: *Arg) bool {
        const value = self.getValue(args);
        if (self.required and value.len == 0 and !self.exist(args)) {
            std.debug.print("{s}: 必填项，请输入\n", .{self.name});
            return false;
        }

        // @todo 待实现更多类型

        return true;
    }
};

// 命令注册字典项
pub const RegisterItem = struct {
    execFn: *const fn (*Arg) void, // 执行方法
    validateAble: bool = true, // 是否进行选项验证
    options: ?std.ArrayList(Option) = null,
    commandName: []u8 = "", // 命令行名称
    commandAlias: ?[]const []const u8 = null, // 选项别名
    help: ?[]const u8 = null, // 命令行帮助信息

    //  选项验证
    pub fn validate(self: *const RegisterItem, args: *Arg, alloc: ?std.mem.Allocator) bool {
        if (!self.validateAble) {
            return true;
        }

        // 将设置信息装载到map中，用于存在判别
        const allocator = alloc orelse std.heap.c_allocator;

        // 内存处理
        var checkMap = std.StringHashMap(bool).init(allocator);
        // if (alloc == null) {
        //     defer allocator.free(checkMap);
        // }
        if (self.options) |allowOptList| {
            for (allowOptList.items) |option| {
                checkMap.put(option.name, true) catch |err| {
                    std.debug.print("checkMap 注册异常，{?}\n", .{err});
                };
                if (option.alias) |alias| {
                    for (alias) |a| {
                        checkMap.put(a, true) catch |err| {
                            std.debug.print("checkMap 注册异常，{?}\n", .{err});
                        };
                    }
                }

                // 选项验证是否通过
                if (!option.validate(args)) {
                    return false;
                }
            }
        }
        // 验证选项「是否支持」
        for (args.getOptList()) |option| {
            if (!checkMap.contains(option)) {
                std.debug.print("{s}: 选项不支持，请查看帮助命令/选项\n\n", .{option});
                return false;
            }
        }
        return true;
    }

    /// 根据配置生帮助文档
    pub fn genHelp(self: *const RegisterItem) void {
        var helpMsg = self.commandName;
        if (self.help) |help| {
            helpMsg += "       " + help;
        } else {
            helpMsg += "       示例命令，可在注册中定义";
        }
        helpMsg += "\n";

        // 获取帮助信息
        if (self.options) |allowOptList| {
            for (allowOptList.items) |option| {
                const help = option.help orelse "这是选项";
                var alias = "";
                if (option.alias and option.alias.len > 0) {
                    alias = std.mem.join(std.heap.smp_allocator, "-", option.alias);
                }
                helpMsg += "-" + option.name + "   " + help + alias + "\n";
            }
        }

        if (helpMsg.len == 0) {
            return;
        }

        std.debug.print("{s}\n", .{helpMsg});
    }
};

/// 命令行选项
pub const AppConfig = struct {
    // 命令行名称
    name: ?[]const u8 = null,
    // 命令行描述
    description: ?[]const u8 = null,
    // 命令行作者
    author: ?[]const u8 = null,
    // 严格验证，即未设置的选项，则提示
    strictValid: bool = true,
};

/// cli 应用处理器
pub const App = struct {
    // 内存分配其
    allocator: std.mem.Allocator,
    // 入口函数
    indexFn: *const fn (*Arg) void = defaultIndexFn,
    helpFn: ?*const fn (*Arg) void = null,
    args: ?*Arg = null,
    // 最后执行函数
    endHook: ?*const fn (*Arg) void = null,
    // 方法是否匹配
    isMatch: bool = false,
    // 配置信息
    config: AppConfig = AppConfig{},

    // 注册字典
    registersMap: std.StringHashMap(RegisterItem),

    /// 初始化应用
    pub fn new(allocator: std.mem.Allocator) App {
        //报错：Segmentation fault at address 0xf5a8c00b70
        //var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        //const allocator = gpa.allocator();
        return App{
            .allocator = allocator,
            //.args = null,
            .registersMap = std.StringHashMap(RegisterItem).init(allocator),
        };
    }

    /// 命令注册
    pub fn command(self: *App, name: []const u8, runFn: fn (*Arg) void) *App {
        const item = RegisterItem{
            .execFn = runFn,
            .commandName = string.mutableAlloc(self.allocator, name),
        };
        self.registersMap.put(name, item) catch |err| {
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

    /// 命令注册名单属性参数
    pub fn commandWith(self: *App, name: []const u8, item: RegisterItem) void {
        var regItem = item;
        if (regItem.commandName.len == 0) {
            regItem.commandName = string.mutableAlloc(self.allocator, name);
        }
        self.registersMap.put(name, regItem) catch |err| {
            std.debug.print("registersMap 注册异常，{any}\n", .{err});
        };
    }

    /// 命令列表注册名单属性参数
    pub fn commandListWith(self: *App, nameList: []const []const u8, item: RegisterItem) void {
        var regItem = item;
        if (regItem.commandName == null) {
            regItem.commandName = nameList[0];
        }
        var cmdList = std.ArrayList([]const u8).init(self.allocator);
        for (nameList[1..]) |name| {
            cmdList.append(name) catch unreachable;
        }
        regItem.commandList = cmdList.toOwnedSlice();
        for (nameList) |name| {
            _ = self.commandWith(name, item);
        }
    }

    /// 定义入口函数
    pub fn index(self: *App, runFn: fn (*Arg) void) void {
        self.indexFn = runFn;
    }

    /// 帮助命令
    pub fn help(self: *App, runFn: fn (*Arg) void) void {
        self.helpFn = runFn;
    }

    /// 选项是否有效，用于验证
    fn optionIsValid(self: *App, args: *Arg) bool {
        // 命令注册未设置选项，且严格模式时进行验证
        if (!self.config.strictValid) {
            return true;
        }
        for (args.getOptList()) |opt| {
            std.debug.print("{s}: 选项不支持，请查看帮助命令/选项\n", .{opt});
            return false;
        }
        return true;
    }

    // 运行命令程序
    pub fn run(self: *App) !void {
        // var args = try Arg.new(std.heap.c_allocator);
        //const args = try Arg.new(self.allocator);
        const args_list = try std.process.argsAlloc(self.allocator);
        defer std.process.argsFree(self.allocator, args_list);
        defer {
            // 执行结束函数hook
            if (self.isMatch) {
                if (self.endHook) |endHook| {
                    endHook(self.args.?);
                }
            }
        }
        const args = Arg.args(args_list[1..], self.allocator);

        //defer args.free();
        const vCommand = args.getCommand();

        self.args = @constCast(&args);
        if (vCommand.len == 0) {
            if (self.args.?.checkOpt("help")) {
                if (self.helpFn) |helpFn| {
                    self.isMatch = true;
                    helpFn(self.args.?);
                    return;
                }
            }
            self.isMatch = true;
            // 命令注册未设置选项，且严格模式时进行验证
            if (!self.optionIsValid(self.args.?)) {
                return;
            }
            self.indexFn(self.args.?);
            return;
        }

        // 执行注册的命令
        if (self.registersMap.get(vCommand)) |rItem| {
            if (!rItem.validate(self.args.?, self.allocator)) {
                return;
            }
            self.isMatch = true;
            rItem.execFn(self.args.?);
            return;
        }

        // 命令注册未设置选项，且严格模式时进行验证
        if (!self.optionIsValid(self.args.?)) {
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

// 获取当前应用所在根目录
pub fn rootPath(alloc: std.mem.Allocator) []u8 {
    const args_list = std.process.argsAlloc(alloc) catch |err| {
        std.debug.print("字符串转换错误，{any}", .{err});
        return "";
    };
    // const args_list = std.process.argsAlloc(alloc) catch @panic("命令初始化异常");
    defer std.process.argsFree(alloc, args_list);
    const binPathOr = std.fs.path.dirname(args_list[0]);
    if (binPathOr == null) {
        return "";
    }

    return std.fmt.allocPrintZ(alloc, "{s}", .{binPathOr.?}) catch |err| {
        std.debug.print("字符串转换错误，{any}", .{err});
        return "";
    };
}

/// 使用子进程执行命令（ChildProcess），并返回结果
pub fn execAlloc(cmd: [][]const u8, allocator: std.mem.Allocator) !struct {
    stdout: []u8,
    stderr: []u8,
    exit_code: i32,
} {
    var child = std.process.Child.init(cmd, allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    var stdout: std.ArrayListUnmanaged(u8) = .empty;
    defer stdout.deinit(allocator);
    var stderr: std.ArrayListUnmanaged(u8) = .empty;
    defer stderr.deinit(allocator);

    try child.spawn();
    try child.collectOutput(allocator, &stdout, &stderr, 1024 * 1024);
    const term = try child.wait();
    const exit_code = switch (term) {
        .Exited => |code| code,
        else => 0,
    };

    return .{
        .stdout = string.unmanagedListStr(u8, stdout, allocator),
        .stderr = string.unmanagedListStr(u8, stderr, allocator),
        .exit_code = exit_code,
    };
}
