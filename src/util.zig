//! 时间等处理函数

const std = @import("std");

/// 计算程序运行时间
/// 1s=10^3ms(毫秒)=10^6μs(微秒)=10^9ns(纳秒)=10^12ps(皮秒)=10^15fs(飞秒)=10^18as(阿秒)=10^21zs(仄秒)=10^24ys(幺秒)
pub fn spendFn() type {
    return struct {
        const Self = @This();
        start: i128,

        /// 计算结束统计时间-纳秒, ns
        pub fn nanoEnd(self: Self) i128 {
            return std.time.nanoTimestamp() - self.start;
        }

        /// 计算微妙, μs
        pub fn microEnd(self: Self) f64 {
            return @floatFromInt(@divTrunc(self.nanoEnd(), 1000));
        }

        /// 计算milliseconds-毫秒, ms
        pub fn milliEnd(self: Self) f64 {
            return @floatFromInt(@divTrunc(self.nanoEnd(), 1000_000));
        }

        /// 秒, s
        pub fn secondEnd(self: Self) f64 {
            return @floatFromInt(@divTrunc(self.nanoEnd(), 1000_000_000));
        }

        /// 及时其开始运行
        pub fn begin() Self {
            return .{
                .start = std.time.nanoTimestamp(),
            };
        }
    };
}
