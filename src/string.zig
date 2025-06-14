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
