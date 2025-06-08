//! 实现日期格式化
//! 2025年5月30日，Power by Joshua Conero.
//! [实验性的]
//! 公历规定有平年和闰年。平年有365天，闰年有366天。
//! 由于地球绕太阳一周叫一回归年，一回归年长365日5时48分46秒，因此平年有365天，比回归年短0.2422日，
//! 四年共短0.9688日，故四个平年增加一日也就是闰年366天。
//!
//! 闰年一年有366天。闰年的判定方法：
//! ①、普通年能被4整除且不能被100整除的为闰年。（如2004年就是闰年，1900年不是闰年）
//! ②、世纪年能被400整除的是闰年。（如2000年是闰年，1900年不是闰年）
//! ③、对于数值很大的年份，这年如果能整除3200，并且能整除172800则是闰年。如172800年是闰年，86400年不是闰年（因为虽然能整除3200，但不能整除172800）。
//!
//! 公历闰月：公历每四年置一闰，闰年比平年多一天，平年的二月为28天，闰年的二月为29天。
//!
//! 月份：一月大，二月平，三月大，四月小，五月大，六月小，七月大，八月大，九月小，十月大，十一月小，十二月大。
//! 1/3/5/7/8/10/12月大=31，2=28/29, 4/6/9/11月小=30。

const std = @import("std");
const time = std.time;

/// 公历日期获取，获取 Unix 时间
///
/// 时间分区：将世界分区24个时区（每隔15°划分一个），最大分别为东十二区和西十二区。
///
/// @todo:
///     - 更加自定的日期生成时间戳
pub const Date = struct {
    nano: i128 = 0,
    dayTotal: f128 = 0,
    year: usize = 0,
    month: usize = 0,
    day: usize = 0,
    hour: usize = 0,
    minute: usize = 0,
    second: usize = 0,
    leapType: time.epoch.YearLeapKind = time.epoch.YearLeapKind.not_leap,
    utcTz: isize = 0, // 时间分区(time zone)
    residualSec: f128 = 0, // 计算日期后剩余的秒数（用于获取精确的时间戳）

    /// 获取当前时间
    pub fn now() Date {
        return fromNano(time.nanoTimestamp());
    }

    /// 获取时间基于 Unix 的nano时间
    pub fn fromNano(nano: i128) Date {
        const dayTotal: f128 = @as(f128, @floatFromInt(nano)) / @as(f128, @floatFromInt(time.ns_per_day));
        const esYear = estimateYear(dayTotal);
        const leapType = if (time.epoch.isLeapYear(@as(time.epoch.Year, @intCast(esYear.year)))) time.epoch.YearLeapKind.leap else time.epoch.YearLeapKind.not_leap;
        const esMonth = estimateMonth(leapType, esYear.residualDay);
        const esDay = estimateDay(esMonth.residualDay);
        const esHour = estimateTime(esDay.residualDay);

        return Date{
            .nano = nano,
            .dayTotal = dayTotal,
            .year = esYear.year,
            .month = esMonth.month,
            .day = esDay.day,
            .hour = esHour.hour,
            .minute = esHour.minute,
            .second = esHour.second,
            .leapType = leapType,
        };
    }

    /// 获取时间基于 Unix 的秒时间
    pub fn fromStamp(stamp: i128) Date {
        return Date.fromNano(stamp * 1000_000_000);
    }

    /// 获取时间基于 Unix 的微秒时间
    pub fn fromMicro(stamp: i128) Date {
        return Date.fromNano(stamp * 1000_000);
    }

    /// 提供年月日构造一个日期
    pub fn init(year: usize, month: usize, day: usize, hour: usize, minute: usize, second: f32) Date {
        const secondInt = @as(usize, @intFromFloat(second));
        const residualSec = second - @as(f32, @floatFromInt(secondInt));
        return Date{
            .year = year,
            .month = month,
            .day = day,
            .hour = hour,
            .minute = minute,
            .second = secondInt,
            .residualSec = @floatCast(residualSec),
        };
    }

    /// 根据当前的日期计算时间戳
    pub fn nanoStamp(self: *Date) i128 {
        var nano: i128 = 0;
        // 年份值计算
        for (time.epoch.epoch_year + 1..self.year) |year| {
            const day = time.epoch.getDaysInYear(@intCast(year));
            nano += @as(i128, @intCast(day)) * time.ns_per_day;
        }

        //  月份值计算
        const yearLearKindKind = yearLearKind(usize, self.year);
        for (1..self.month) |mth| {
            const mthDay = getDaysInMonth(yearLearKindKind, mth);
            nano += @as(i128, @intCast(mthDay)) * time.ns_per_day;
        }

        // 天
        nano += self.day * time.ns_per_day;
        nano += self.hour * time.ns_per_hour;
        nano += self.minute * time.ns_per_min;
        nano += self.second * time.ns_per_s;
        nano += @as(i128, @intFromFloat(self.residualSec)) * 1000_000;
        return nano;
    }

    /// 获取时间戳（微秒）
    pub fn microStamp(self: *Date) i64 {
        return @as(i64, @intCast(@divFloor(self.nanoStamp(), time.ns_per_us)));
    }

    /// 获取时间戳（微秒）
    pub fn milliStamp(self: *Date) i64 {
        return @as(i64, @intCast(@divFloor(self.nanoTimestamp(), time.ns_per_ms)));
    }

    /// 获取时间戳（秒）
    pub fn timestamp(self: *Date) i64 {
        return @divFloor(self.milliTimestamp(), time.ms_per_s);
    }

    /// 设置日期周期
    pub fn timeZone(self: *Date, tz: usize) *Date {
        self.utcTz = tz;
        return self;
    }

    /// 设置中国时区（东八区）
    pub fn cnTime(self: *Date) *Date {
        self.utcTz = 8;
        return self;
    }

    /// 返回日期字符串
    pub fn toString(self: *Date, alloc: std.mem.Allocator) []u8 {
        return self.toStringTz(alloc, self.utcTz);
    }

    /// 返回日期字符串
    pub fn toStringTz(self: *Date, alloc: std.mem.Allocator, tzIndex: isize) []u8 {
        var day: usize = @intCast(self.day);
        var hour: isize = @intCast(self.hour);

        // 区间小一天
        if (tzIndex < 0) {
            day -= 1;
            hour += tzIndex;
        } else {
            hour += tzIndex;
            if (hour >= 24) {
                day += 1;
                hour -= 24;
            }
        }

        return std.fmt.allocPrintZ(alloc, "{d}-{:0>2}-{:0>2} {:0>2}:{:0>2}:{:0>2}", .{
            self.year,
            self.month,
            day,
            @as(usize, @intCast(hour)),
            self.minute,
            self.second,
        }) catch unreachable;
    }

    /// 返回时间字符串
    pub fn timeStringTz(self: *Date, alloc: std.mem.Allocator, tzIndex: isize) []u8 {
        var hour: isize = @intCast(self.hour);

        // 区间小一天
        if (tzIndex < 0) {
            hour += tzIndex;
        } else {
            hour += tzIndex;
            if (hour >= 24) {
                hour -= 24;
            }
        }

        return std.fmt.allocPrintZ(alloc, "{:0>2}:{:0>2}:{:0>2}", .{
            @as(usize, @intCast(hour)),
            self.minute,
            self.second,
        }) catch unreachable;
    }

    /// 返回日期字符串
    pub fn timeString(self: *Date, alloc: std.mem.Allocator) []u8 {
        return self.timeStringTz(alloc, self.utcTz);
    }

    // 日期+
    fn incDayAdd(self: *Date, inc: f32) Date {
        var date = self.*;
        const dayInt: usize = @intFromFloat(inc);
        const dayLest = (inc - @as(f32, @floatFromInt(dayInt))) * 24 * 60 * 60;
        const residualSecBig = dayLest + date.residualSec;
        const residualSecInt: i64 = @intFromFloat(residualSecBig);
        date.residualSec = residualSecBig - @as(f128, @floatFromInt(residualSecInt));

        // 秒
        const mintueFloat = @as(f64, @floatFromInt(@as(i64, @intCast(date.second)) + residualSecInt)) / 60;
        const mintueInt: usize = @intFromFloat(mintueFloat);
        date.second = @intFromFloat((mintueFloat - @as(f64, @floatFromInt(mintueInt))) * 60);

        // 分
        const hourFloat = @as(f64, @floatFromInt(@as(i64, @intCast(date.mintue)) + mintueInt)) / 60;
        const houtInt: usize = @intFromFloat(hourFloat);
        date.minute = @intFromFloat((hourFloat - @as(f64, @floatFromInt(houtInt))) * 60);

        // 时
        const dateFloat = @as(f64, @floatFromInt(@as(i64, @intCast(date.hour)) + houtInt)) / 24;
        const dateInt: usize = @intFromFloat(dateFloat);
        date.hour = @intFromFloat((dateFloat - @as(f64, @floatFromInt(dateInt))) * 24);

        // 天
        var dayCtt = self.day + dateInt;
        var month = self.month;
        var year = self.year;

        // 遍历处理
        while (true) {
            const leapKind = time.epoch.getLeapYearKind(year);
            const curMonthAll = getDaysInMonth(leapKind, self.month);
            if (curMonthAll < dayCtt) {
                month += 1;
                dayCtt = dayCtt - curMonthAll;

                // 翻滚到下一年
                if (month > 12) {
                    month = 1;
                    year += 1;
                }
            } else {
                break;
            }
        }
        date.day = dayCtt;
        date.month = month;
        date.year = year;

        return date;
    }

    // 日期-
    fn incDaySub(self: *Date, inc: f32) Date {
        var date = self.*;
        const second: f32 = @as(f32, @floatFromInt(date.second)) + date.residualSec;
        var curDay = timeToDay(usize, date.hour, date.minute, second);
        curDay += date.day;
        curDay -= @as(f32, @abs(inc));

        var month = date.month;
        var year = date.year;
        var realDay: f32 = @floatFromInt(date.day);
        while (true) {
            if (curDay > 0) {
                break;
            }

            if (realDay > curDay) {
                realDay += curDay;
                break;
            }
            month -= 1;
            if (month < 1) {
                month = 12;
                year -= 1;
            }
            const leapKind = time.epoch.getLeapYearKind(year);
            const lastMonthDay = getDaysInMonth(leapKind, month);
            realDay += @as(f32, @floatFromInt(lastMonthDay));
        }

        date.year = year;
        date.month = month;

        const curTime = dayToTime(f32, realDay);

        date.day = curTime.day;
        date.hour = curTime.hour;
        date.minute = curTime.minute;
        date.second = curTime.second;
        date.residualSec = curTime.residualSec;
        return date;
    }

    /// 当前的日期加/减天数
    pub fn incDay(self: *Date, inc: f32) Date {
        if (inc == 0) {
            return self.*;
        }
        if (inc < 0) {
            return self.incDaySub(inc);
        }
        return self.incDayAdd(inc);
    }

    /// 当前的日期加/减天数
    pub fn subDate(self: *Date, sub: Date) f64 {
        var vSub = sub;
        const subDiff = self.nanoStamp() - vSub.nanoStamp();
        return @floatFromInt(subDiff);
    }
};

/// 根据总天数评估年份
const EstimateDate = struct {
    year: usize = 0, // 计算所得年份
    month: usize = 0, // 计算所得年份
    day: usize = 0, // 计算所得年份
    hour: usize = 0, // 计算所得小时
    minute: usize = 0, // 计算所得分钟
    second: usize = 0, // 计算所得秒
    residualDay: f128 = 0, // 计算年份后剩余的天数
    residualSec: f128 = 0, // 计算年份后剩余的秒
};

/// 根据总的天数评估年份
fn estimateYear(dayTotal: f128) EstimateDate {
    // 1平均年=（365 + 1 / 4-1 / 100 + 1/400）天= 365.2425天
    const maxYear = @as(usize, @intFromFloat(dayTotal / 365.2425)) + time.epoch.epoch_year;
    var countLeapYear: usize = 0;
    var countNoneLeapYear: usize = 0;
    for (time.epoch.epoch_year + 1..maxYear + 1) |year| {
        const isLeapYear = time.epoch.isLeapYear(@as(time.epoch.Year, @intCast(year)));
        countLeapYear += if (isLeapYear) 1 else 0;
        countNoneLeapYear += if (isLeapYear) 0 else 1;
    }

    var relYearDay: usize = countNoneLeapYear * 365 + countLeapYear * 366;
    const dayTotalInt: usize = @intFromFloat(dayTotal);
    const year: usize = if (dayTotalInt >= relYearDay) maxYear else maxYear - 1;
    relYearDay = if (relYearDay <= dayTotalInt) relYearDay else dayTotalInt;
    const residualDay = dayTotal - @as(f128, @floatFromInt(relYearDay));
    return EstimateDate{
        .year = year,
        .residualDay = residualDay,
    };
}

/// 根据总的天数评估年份
fn estimateMonth(leapType: time.epoch.YearLeapKind, dayTotal: f128) EstimateDate {
    const dayInt = @as(usize, @intFromFloat(dayTotal));

    // 统计日期
    var dayCount: usize = if (leapType == time.epoch.YearLeapKind.leap) 366 else 365;
    var relMonth: usize = 1;
    var residualDay: f128 = 0;
    // 月份遍历
    var mth: usize = 12;
    while (mth > 0) : (mth -= 1) {
        const vDay = getDaysInMonth(leapType, mth);
        dayCount -= @intCast(vDay);
        if (dayInt >= dayCount) {
            relMonth = mth;
            residualDay = dayTotal - @as(f128, @floatFromInt(dayCount));
            break;
        }
    }

    return EstimateDate{ .month = relMonth, .residualDay = residualDay };
}

/// 根据总的天数评估天数
fn estimateDay(dayTotal: f128) EstimateDate {
    const dayInt = @as(usize, @intFromFloat(dayTotal));
    const residualDay = dayTotal - @as(f128, @floatFromInt(dayInt));
    return EstimateDate{
        .day = if (dayInt > 0) dayInt + 1 else 1,
        .residualDay = residualDay,
    };
}

/// 根据总的天数评估时分秒
fn estimateTime(dayTotal: f128) EstimateDate {
    // 小时
    const hourTotal: f128 = dayTotal * 24;
    const hour = @as(usize, @intFromFloat(hourTotal));
    // 分钟
    const minuteTotal: f128 = (hourTotal - @as(f128, @floatFromInt(hour))) * 60;
    const minute = @as(usize, @intFromFloat(minuteTotal));
    // 秒
    const secondTotal: f128 = (minuteTotal - @as(f128, @floatFromInt(minute))) * 60;
    const second = @as(usize, @intFromFloat(secondTotal));
    // 秒
    const residualSec = secondTotal - @as(f128, @floatFromInt(second));
    return EstimateDate{
        .hour = hour,
        .minute = minute,
        .second = second,
        .residualSec = residualSec,
    };
}

/// 根据月份获取对应的天数：一月大，二月平，三月大，四月小，五月大，六月小，七月大，八月大，九月小，十月大，十一月小，十二月大。
/// 1/3/5/7/8/10/12月大=31，2=28/29, 4/6/9/11月小=30。
pub fn getDaysInMonth(leap_year: time.epoch.YearLeapKind, month: usize) u5 {
    return switch (month) {
        1, 3, 5, 7, 8, 10, 12 => 31,
        2 => @as(u5, switch (leap_year) {
            .leap => 29,
            .not_leap => 28,
        }),
        4, 6, 9, 11 => 30,
        else => 0,
    };
}

/// 指定时分秒转为日期 `1233:222:3333.33` 等装为日期格式
pub fn timeToDay(comptime T: type, hour: T, mintue: T, second: f32) f32 {
    const hourF32 = @as(f32, @floatFromInt(hour)) + @as(f32, @floatFromInt(mintue)) / 60 + second / 3600;
    return hourF32 / 24;
}

/// 日期转时分秒，日期为数值类型
pub fn dayToTime(comptime T: type, day: T) struct { day: usize, hour: usize, minute: usize, second: usize, residualSec: f128 } {
    const dayInt: usize = @intFromFloat(day);
    var hour: f128 = @floatCast(day - @as(T, @floatFromInt(dayInt)));
    hour *= 24;
    const hourInt: usize = @intFromFloat(hour);
    const minute: f128 = (hour - @as(f128, @floatFromInt(hourInt))) * 60;
    const minuteInt: usize = @intFromFloat(minute);
    const second = (minute - @as(f128, @floatFromInt(minuteInt))) * 60;
    const secondInt: usize = @intFromFloat(second);
    const residualSec = second - @as(f128, @floatFromInt(secondInt));

    return .{
        .day = dayInt,
        .hour = hourInt,
        .minute = minuteInt,
        .second = secondInt,
        .residualSec = residualSec,
    };
}

pub fn yearLearKind(comptime T: type, year: T) time.epoch.YearLeapKind {
    return if (time.epoch.isLeapYear(@as(time.epoch.Year, @intCast(year)))) .leap else .not_leap;
}

test "Date.now base test" {
    var now = Date.now();
    const testing = std.testing;
    std.debug.print("\n", .{});
    std.debug.print("中国时间: {s}\n", .{now.cnTime().toString(std.heap.smp_allocator)});
    std.debug.print("UTC 时间: {s}\n", .{now.cnTime().toStringTz(std.heap.smp_allocator, 0)});
    std.debug.print("时间: {s}\n", .{now.cnTime().timeString(std.heap.smp_allocator)});
    std.debug.print("nano: {d}\n", .{now.nano});

    // 指定日期计算
    var date = Date.fromNano(867768559000_000_000);
    std.debug.print("unix 时间戳中国时间: {s}\n", .{date.cnTime().toString(std.heap.smp_allocator)});
    try testing.expect(date.year == 1997);
}

test "Date.subDate case" {
    var date = Date.init(2025, 6, 8, 21, 48, 23.093934);
    const subDate = Date.init(2025, 3, 30, 14, 20, 3.893899093);
    const diff = date.subDate(subDate);
    std.debug.print("\n时间差: {d:.4}\n", .{diff});
}
