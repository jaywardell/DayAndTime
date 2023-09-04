//
//  DayAndTime.swift
//  DailyWeatherModel
//
//  Created by Joseph Wardell on 8/20/23.
//

import Foundation

extension ClosedRange where Bound == Date {
    static var allTime: Self {
        .distantPast ... .distantFuture
    }
}

/// A type that encapsulates a Date instance and offers methods to adjust the Date in various ways
public final class DayAndTime: ObservableObject {
    @Published private(set) public var time = Date.now

    let calendar: Calendar

    /// a date range within which the time value is allowed to range
    @Published public var term: ClosedRange<Date> = .allTime

    @Published public var showingTime: Bool

    public init(time: Date = Date.now,
         calendar: Calendar = .current,
         showingTime: Bool = false) {
        self.time = time
        self.calendar = calendar
        self.showingTime = showingTime
    }

    public var day: ClosedRange<Date> {
        calendar.day(for: time)
    }

    public func matchesDay(of time: Date) -> Bool {
        day == calendar.day(for: time)
    }

    public var isToday: Bool {
        matchesDay(of: .now)
    }

    /// The farthest that the time can be from the current time
    /// and still be considered "now" for the purposes of `isNow`
    private var nowMargin: TimeInterval { 5 }

    /// returns true if the time and day are close enough to the current time
    /// to be considered "now" for the purposes of a typical user's estimation
    public var isNow: Bool {
        abs(Date.now.timeIntervalSince1970 - time.timeIntervalSince1970) < nowMargin
    }

    public func setTime(to newDate: Date = .now) {
        self.time = min(max(newDate, term.lowerBound), term.upperBound)
    }

    private var oneHourForward: Date? {
        guard time < day.upperBound.addingTimeInterval(-3599) else { return nil }

        let hour = calendar.component(.hour, from: time)
        guard let oneHourForward = calendar.date(byAdding: DateComponents(hour: hour + 1), to: day.lowerBound) else { return nil }

        let out = min(oneHourForward, day.upperBound)
        guard term.contains(out) else { return nil }
        return out
    }

    public func canStepForwardOneHour() -> Bool {
        nil != oneHourForward
    }

    /// move the time forward to the next hour on the same day
    public func stepForwardOneHour() {
        time = oneHourForward ?? time
    }

    private var oneHourBackward: Date? {
        guard time > day.lowerBound else { return nil }

        var hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        let second = calendar.component(.second, from: time)

        if minute == 0 && second == 0 {
            hour -= 1
        }

        guard let oneHourBackward = calendar.date(byAdding: DateComponents(hour: hour ), to: day.lowerBound) else {
            return nil
        }

        let out = min(oneHourBackward, day.upperBound)
        guard term.contains(out) else { return nil }
        return out
    }

    public func canStepBackOneHour() -> Bool {
        nil != oneHourBackward
    }

    /// move the time back to the previous hour on the same day
    public func stepBackOneHour() {
        time = oneHourBackward ?? time
    }

    private var oneDayForward: Date? {
        guard let oneDayForward = calendar.date(byAdding: DateComponents(day: 1), to: time) else {
            return nil
        }

        guard term.contains(oneDayForward) else { return nil }

        return oneDayForward
    }

    public func canStepForwardOneDay() -> Bool {
        nil != oneDayForward
    }

    public func stepForwardOneDay() {
        time = oneDayForward ?? time
    }

    public func canStepBackwardOneDay() -> Bool {
        nil != oneDayBackward
    }

    private var oneDayBackward: Date? {
        guard let oneDayBackward = calendar.date(byAdding: DateComponents(day: -1), to: time) else {
            return nil
        }

        guard term.contains(oneDayBackward) else { return nil }

        return oneDayBackward
    }

    public func stepBackwardOneDay() {
        time = oneDayBackward ?? time
    }
}
