//! 2025年6月14日 简单字符串扩展

const std = @import("std");

/// 字面字符串变为可变的字符串
pub fn mutable(s: []const u8) []u8 {
    return mutableAlloc(std.heap.page_allocator, s);
}

/// 提供内存分配器字面字符串变为可变的字符串
pub fn mutableAlloc(alloc: std.mem.Allocator, s: []const u8) []u8 {
    return std.fmt.allocPrintZ(alloc, "{s}", .{s}) catch unreachable;
}

/// 格式化字符串
pub fn format(alloc: std.mem.Allocator, vFmt: []const u8, args: anytype) []u8 {
    return std.fmt.allocPrintZ(alloc, vFmt, args) catch unreachable;
}

/// 非托管 list 转换为字符串
pub fn unmanagedListStr(comptime T: type, list: std.ArrayListUnmanaged(T), alloc: std.mem.Allocator) []u8 {
    // 将 ArrayListUnmanaged(u8) 转换为 Zig 字符串
    return std.fmt.allocPrint(alloc, "{s}", .{std.mem.sliceTo(list.items, 0)}) catch return "";
}
