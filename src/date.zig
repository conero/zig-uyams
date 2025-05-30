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

///  公历日期获取
pub const Date = struct {
    nano: i128 = 0,
    dayTotal: f128 = 0,
    year: usize = 0,
    month: usize = 0,
    day: usize = 0,
    leapType: time.epoch.YearLeapKind = time.epoch.YearLeapKind.not_leap,
    pub fn now() Date {
        const nano = time.nanoTimestamp();
        const dayTotal: f128 = @as(f128, @floatFromInt(nano)) / @as(f128, @floatFromInt(time.ns_per_day));
        const esYear = estimateYear(dayTotal);
        const leapType = if (time.epoch.isLeapYear(@as(time.epoch.Year, @intCast(esYear.year)))) time.epoch.YearLeapKind.leap else time.epoch.YearLeapKind.not_leap;
        const esMonth = estimateMonth(leapType, esYear.residualDay);
        const esDay = estimateDay(esMonth.residualDay);

        return Date{
            .nano = nano,
            .dayTotal = dayTotal,
            .year = esYear.year,
            .month = esMonth.month,
            .day = esDay.day,
            .leapType = leapType,
        };
    }
};

/// 根据总天数评估年份
const EstimateDate = struct {
    year: usize = 0, // 计算所得年份
    month: usize = 0, // 计算所得年份
    day: usize = 0, // 计算所得年份
    residualDay: f128 = 0, // 计算年份后剩余的天数
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
    std.debug.print("\nresidualDay: {d:.9}, year: {d}\n", .{ residualDay, year });
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
    for (1..13) |mth| {
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
        .day = if (dayInt > 0) dayInt else 1,
        .residualDay = residualDay,
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

test "Date.now base test" {
    const now = Date.now();
    std.debug.print("now: {d:.10}\n", .{now.dayTotal});
}
