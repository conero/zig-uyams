//! 命令行输出工具
const std = @import("std");

// 可选输入
pub fn optional(title: []const u8) []const u8 {
    // 获取标准输入流
    const stdin = std.io.getStdIn().reader();
    // 获取标准输出流（用于打印提示信息）
    const stdout = std.io.getStdOut().writer();

    // 打印提示信息
    stdout.print("{s}", .{title}) catch unreachable;
    while (true) {
        // 创建缓冲区存储输入
        var buffer: [1024]u8 = undefined;
        // 读取输入，直到换行符或缓冲区满
        const input = stdin.readUntilDelimiterOrEof(&buffer, '\n') catch |err| {
            stdout.print("读取文件错误，{any}\n", .{err}) catch unreachable;
            break;
        };
        if (input) |ipt| {
            return ipt;
        }
        return "";
    }
    return "";
}
