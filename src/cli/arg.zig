const std = @import("std");

/// 命令解析
pub const Arg = struct {
    /// 命令
    command: []const u8 = "",
    /// 操作系统命令列表
    osArgsList: ?[][:0]u8 = null,
    /// 选项列表
    optionList: std.ArrayList([]const u8),
    /// 内存分配器
    allocator: ?std.mem.Allocator = null,
    /// 属性字典存储字典，用于保存多值
    optionKvEntry: std.StringHashMap([][]const u8),

    /// 使用命令参数示例化参数
    pub fn new(allocator: std.mem.Allocator) !Arg {
        const args_list = try std.process.argsAlloc(allocator);
        //defer std.process.argsFree(std.heap.c_allocator, args_list);
        var mySelf = Arg.args(args_list[1..], allocator);
        mySelf.osArgsList = args_list;
        return mySelf;
    }

    /// 指定参数列表来解析命令行
    pub fn args(argsList: [][:0]u8, allocator: std.mem.Allocator) Arg {
        var command: []u8 = "";
        var optionList = std.ArrayList([]const u8).init(allocator);
        var optionKvEntry = std.StringHashMap([][]const u8).init(allocator);
        for (argsList, 0..) |arg, index| {
            //std.debug.print(" => {d} -> {s}\n", .{ index, arg });
            const dOpt = detectOption(arg, true);
            if (dOpt.@"1") {
                const rawOptName = dOpt.@"0";
                // 选项表写入
                if (allocator.dupe(u8, rawOptName)) |optName| {
                    if (optionList.append(optName)) {} else |err| {
                        std.debug.print("选中之入库错误，{?}\n", .{err});
                    }
                } else |err| {
                    std.debug.print("选项之入库时值复制错误，{?}\n", .{err});
                }
                // 选项键值对写入
                if (dOpt.@"2") |optValue| {
                    if (optionKvEntry.contains(rawOptName)) {
                        var entryValue = std.ArrayList([]const u8).init(allocator);
                        for (optionKvEntry.get(rawOptName).?) |childValue| {
                            entryValue.append(childValue) catch |err| {
                                std.debug.print("选项键值对入库时值错误，{?}\n", .{err});
                            };
                        }
                        entryValue.append(optValue) catch |err| {
                            std.debug.print("optionKv 值写追加错误，更新，{?}\n", .{err});
                        };
                        optionKvEntry.put(rawOptName, entryValue.items) catch |err| {
                            std.debug.print("选项键值对入库时键错误，{?}\n", .{err});
                        };
                    } else {
                        var entryValue = std.ArrayList([]const u8).init(allocator);
                        entryValue.append(optValue) catch |err| {
                            std.debug.print("optionKv 值写追加错误，新建，{?}\n", .{err});
                        };
                        optionKvEntry.put(rawOptName, entryValue.items) catch |err| {
                            std.debug.print("选项键值对入库时键错误，{?}\n", .{err});
                        };
                    }
                }

                continue;
            }
            // 认定第一个参数为命令行
            if (command.len == 0 and index == 0) {
                //std.debug.print("arg: {s}\n", .{arg});
                command = arg;
            }
        }

        // [实验性] 复制值到内存中，加不加与后再类似
        if (allocator.dupe(u8, command)) |cpName| {
            return Arg{
                .command = cpName,
                .allocator = allocator,
                .optionList = optionList,
                .optionKvEntry = optionKvEntry,
            };
        } else |err| {
            std.debug.print("command 值处理异常，{?}\n", .{err});
        }

        // 此语句与前面一样
        return Arg{
            .command = command,
            .allocator = allocator,
            .optionList = optionList,
            .optionKvEntry = optionKvEntry,
        };
    }

    /// 获取命令
    pub fn getCommand(self: *const Arg) []const u8 {
        return self.command;
    }

    /// 获取选项列表
    pub fn getOptList(self: *const Arg) [][]const u8 {
        return self.optionList.items;
    }

    /// 检测选是否存在
    pub fn checkOpt(self: *const Arg, opt: []const u8) bool {
        // 此处报错
        // if (std.mem.indexOf([]const u8, self.optionList.items, opt)) {
        //     return true;
        // }

        for (self.optionList.items) |refOpt| {
            if (std.mem.eql(u8, refOpt, opt)) {
                return true;
            }
        }

        return false;
    }

    /// 检测选是否存在
    pub fn checkOptList(self: *const Arg, opts: [][]const u8) bool {
        for (opts) |opt| {
            if (std.mem.indexOf([]const u8, self.optionList.items, opt)) {
                return true;
            }
        }

        return false;
    }

    // 选项数据获取
    pub fn get(self: *const Arg, opt: []const u8) ?[]u8 {
        if (self.optionKvEntry.get(opt)) |value| {
            return std.mem.join(self.allocator, " ", value) catch |err| {
                std.debug.print("选项键值对入库时键错误，{?}\n", .{err});
            };
        }
        return null;
    }

    // 获取选项数据（整形）
    pub fn getInt(self: *const Arg, opt: []const u8) !isize {
        if (self.get(opt)) |value| {
            return try std.fmt.parseInt([]u8, value, 10);
        }
        return 0;
    }

    /// 内存释放
    pub fn free(self: *Arg) void {
        if (self.allocator) |allocator| {
            // 命令行参数释放
            if (self.osArgsList) |osArgs| {
                std.process.argsFree(allocator, osArgs);
            }
            // 选项列表释放
            self.optionList.deinit();
            // 键值对释放
            self.optionKvEntry.deinit();
        }
    }
};

/// 检测变量是否为选项，返回 => {option, isOption, value}
pub fn detectOption(vString: []u8, supportLong: bool) struct { []u8, bool, ?[]u8 } {
    const vLen = vString.len;
    if (vLen == 0) {
        return .{ "", false, null };
    }

    // 长选项
    if (vLen > 1 and supportLong and std.mem.eql(u8, vString[0..2], "--")) {
        // 含等于
        if (std.mem.indexOf(u8, vString, "=")) |index| {
            return .{ vString[2..index], true, vString[index + 1 ..] };
        }
        return .{ vString[2..], true, null };
    }

    if (vString[0] == '-') {
        // 含等于
        if (std.mem.indexOf(u8, vString, "=")) |index| {
            return .{ vString[1..index], true, vString[index + 1 ..] };
        }
        return .{ vString[1..], true, null };
    }
    return .{ "", false, null };
}
