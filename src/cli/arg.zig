const std = @import("std");
const number = @import("../number.zig");

/// 命令解析
pub const Arg = struct {
    /// 命令
    command: []const u8 = "",
    /// 子命令
    subCommand: []const u8 = "",
    /// 连续子命令列表（开头命令不含子命令）
    contCmdList: std.ArrayList([]const u8),
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
        var subCommand: []u8 = "";
        var optionList = std.ArrayList([]const u8).init(allocator);
        var contCmdList = std.ArrayList([]const u8).init(allocator);
        var optionKvEntry = std.StringHashMap([][]const u8).init(allocator);
        var lastOpt: []u8 = ""; // 最终的选项
        for (argsList, 0..) |arg, index| {
            if (arg.len == 0) { // 空字符串不处理
                continue;
            }
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
                    var entryValue = std.ArrayList([]const u8).init(allocator);
                    if (optionKvEntry.contains(rawOptName)) {
                        for (optionKvEntry.get(rawOptName).?) |childValue| {
                            entryValue.append(childValue) catch |err| {
                                std.debug.print("选项键值对入库时值错误，{?}\n", .{err});
                            };
                        }
                    }
                    entryValue.append(optValue) catch |err| {
                        std.debug.print("optionKv 值写追加错误，更新，{?}\n", .{err});
                    };
                    optionKvEntry.put(rawOptName, entryValue.items) catch |err| {
                        std.debug.print("选项键值对入库时键错误，{?}\n", .{err});
                    };
                    std.debug.print("[tmpMark] optionKv 值写追加成功kb:\nkey={s}, value={s}\n", .{ optValue, optValue });
                }

                lastOpt = rawOptName;
                continue;
            }
            // 还没选项时的非输入参数
            if (optionList.items.len == 0) {
                contCmdList.append(arg) catch |err| {
                    std.debug.print("contCmdList 值写追加错误，更新，{?}\n", .{err});
                };
            }
            // 认定第一个参数为命令行
            if (command.len == 0 and index == 0) {
                //std.debug.print("arg: {s}\n", .{arg});
                command = arg;
                continue;
            } else if (index == 1 and command.len > 0) {
                subCommand = arg;
                continue;
            }

            // 选项值记录
            if (lastOpt.len > 0) {
                var entryValue = std.ArrayList([]const u8).init(allocator);
                if (optionKvEntry.contains(lastOpt)) {
                    for (optionKvEntry.get(lastOpt).?) |childValue| {
                        entryValue.append(childValue) catch |err| {
                            std.debug.print("选项键值对入库时值错误，{?}\n", .{err});
                        };
                    }
                }
                entryValue.append(arg) catch |err| {
                    std.debug.print("optionKv 值写追加错误，更新，{?}\n", .{err});
                };
                optionKvEntry.put(lastOpt, entryValue.items) catch |err| {
                    std.debug.print("选项键值对入库时键错误，{?}\n", .{err});
                };
            }
        }

        // [实验性] 复制值到内存中，加不加与后再类似
        if (allocator.dupe(u8, command)) |cpName| {
            return Arg{
                .command = cpName,
                .allocator = allocator,
                .optionList = optionList,
                .optionKvEntry = optionKvEntry,
                .contCmdList = contCmdList,
            };
        } else |err| {
            std.debug.print("command 值处理异常，{?}\n", .{err});
        }

        // 此语句与前面一样
        return Arg{
            .command = command,
            .subCommand = subCommand,
            .allocator = allocator,
            .optionList = optionList,
            .optionKvEntry = optionKvEntry,
            .contCmdList = contCmdList,
        };
    }

    /// 获取命令
    pub fn getCommand(self: *const Arg) []const u8 {
        return self.command;
    }

    /// 获取子命令
    pub fn getSubCommand(self: *const Arg) []const u8 {
        return self.subCommand;
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
        const allocator = self.allocator.?;
        if (self.optionKvEntry.get(opt)) |value| {
            return std.mem.join(allocator, " ", value) catch |err| {
                std.debug.print("选项键值对入库时键错误，{?}\n", .{err});
                return null;
            };
        }
        return null;
    }

    // 获取对应选项数据列表
    pub fn getList(self: *const Arg, opt: []const u8) ?[][]const u8 {
        if (self.optionKvEntry.get(opt)) |value| {
            return value;
        }
        return null;
    }

    // 获取选项数据（整形）
    pub fn getInt(self: *const Arg, opt: []const u8) ?isize {
        if (self.get(opt)) |value| {
            if (self.allocator) |alloc| {
                const vNumber = number.strToInt(alloc, value);
                if (vNumber != 0) {
                    return vNumber;
                }
            } else {
                return std.fmt.parseInt(isize, value, 10) catch |err| {
                    std.debug.print("选项键值对入库时键错误，{?}\n", .{err});
                    return null;
                };
            }
        }
        return null;
    }

    // 获取选项数据（整形）
    pub fn getF64(self: *const Arg, opt: []const u8) ?f64 {
        if (self.get(opt)) |value| {
            if (self.allocator) |alloc| {
                if (number.strToF64(alloc, value)) |vNumber| {
                    return vNumber;
                }
            }
            return std.fmt.parseFloat(f64, value) catch |err| {
                std.debug.print("选项键值对入库时键错误，{?}\n", .{err});
                return null;
            };
        }
        return null;
    }

    /// 获取命令行列表
    pub fn cmdNext(self: *Arg, markKey: ?[]const u8) ?[]u8 {
        if (markKey) |mark| {
            var index: i8 = -1;
            const cmdLen = self.contCmdList.items.len;
            for (self.contCmdList.items, 0) |cmd, orderIdx| {
                if (std.mem.eql(u8, cmd, mark)) {
                    index = orderIdx + 1;
                    if (index < cmdLen) {
                        return self.contCmdList.items[index];
                    }
                }
            }
            return null;
        }
        if (self.contCmdList.items.len > 0) {
            return self.contCmdList.items[0];
        }
        return null;
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
