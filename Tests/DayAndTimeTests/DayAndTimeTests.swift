//
//  DayAndTimeTests.swift
//  DailyWeatherModelTests
//
//  Created by Joseph Wardell on 8/20/23.
//

import XCTest
import XCTestCombine

@testable import DayAndTime

final class DayAndTimeTests: XCTestCase {

    func test_init_sets_time_to_now() {
        let sut = DayAndTime()

        XCTAssertEqual(sut.time.timeIntervalSince1970, Date.now.timeIntervalSince1970, accuracy: 0.001)
    }

    func test_day_is_today_on_init() {
        let sut = DayAndTime()

        let startOfDay = Calendar.current.startOfDay(for: .now)
        let oneDay = DateComponents(day: 1)
        let endOfDay = Calendar.current.date(byAdding: oneDay, to: startOfDay)

        XCTAssertEqual(sut.day.lowerBound, startOfDay)
        XCTAssertEqual(sut.day.upperBound, endOfDay)

        // NOTE: this may fail on daylight savings days,
        // or other nonstandard days
        XCTAssertEqual(sut.day.upperBound.timeIntervalSince1970 - sut.day.lowerBound.timeIntervalSince1970, 86400)
    }

    func test_date_and_time_are_same_on_init() {
        let sut = DayAndTime()

        // date should just be a synonym for time
        XCTAssertEqual(sut.date, sut.time)
    }

    func test_term_is_all_time_on_init() {
        let sut = DayAndTime()

        XCTAssertEqual(sut.term, .allTime)
    }

    func test_day_respects_calendar_passed_in() {
        var calendar = Calendar.current
        calendar.timeZone = .gmt
        let sut = DayAndTime(calendar: calendar)

        let startOfDay = calendar.startOfDay(for: sut.time)
        let localStartOfDay = Calendar.current.startOfDay(for: sut.time)

        XCTAssertEqual(sut.day.lowerBound, startOfDay)
        XCTAssertNotEqual(sut.day.lowerBound, localStartOfDay)
    }

    func test_setting_term_triggers_objectWillChange() {
        let sut = DayAndTime()

        expectChanges(for: sut.objectWillChange.eraseToAnyPublisher()) {
            sut.term = .now ... .now.addingTimeInterval(1)
        }
    }

    func test_setting_showingTime_triggers_objectWillChange() {
        let sut = DayAndTime()

        expectChanges(for: sut.objectWillChange.eraseToAnyPublisher()) {
            sut.showingTime.toggle()
        }
    }

    func test_startOfDay_returns_start_of_day() {
        let date = Date.now
        let sut = DayAndTime(time: date)

        let expected = sut.calendar.startOfDay(for: date)
        XCTAssertEqual(sut.startOfDay, expected)

        let randomDateInFuture = date.addingTimeInterval(.random(in: 1 ... 10_000_000))
        let expected2 = sut.calendar.startOfDay(for: randomDateInFuture)

        sut.setDayAndTime(to: randomDateInFuture)
        XCTAssertEqual(sut.startOfDay, expected2)
    }

    // MARK: - setDayAndTime
    func test_setDayAndTime_sets_time_to_date_passed_in() {
        let sut = DayAndTime()

        let startOfDay = Date.now.advanceBySmallRandomNumberOfDays()
        sut.setDayAndTime(to: startOfDay)

        XCTAssertEqual(startOfDay, sut.time)
    }

    func test_setDayAndTime_sets_date_to_date_passed_in() {
        let sut = DayAndTime()

        let startOfDay = Date.now.advanceBySmallRandomNumberOfDays()
        sut.setDayAndTime(to: startOfDay)

        // date and time are just synonyms
        XCTAssertEqual(startOfDay, sut.date)
    }

    func test_setDayAndTime_sets_time_to_now_if_no_date_passed_in() {
        let sut = DayAndTime()
        let startOfDay = Date.now.advanceBySmallRandomNumberOfDays()
        sut.setDayAndTime(to: startOfDay)

        sut.setDayAndTime()

        XCTAssertEqual(sut.time.timeIntervalSince1970, Date.now.timeIntervalSince1970, accuracy: 0.001)
    }

    func test_setDayAndTime_sets_day_to_day_of_date_passed_in() {
        let sut = DayAndTime()

        let newDate = sut.time.advanceBySmallRandomNumberOfDays()
        let startOfDay = Calendar.current.startOfDay(for: newDate)
        let oneDay = DateComponents(day: 1)
        let endOfDay = Calendar.current.date(byAdding: oneDay, to: startOfDay)

        sut.setDayAndTime(to: newDate)

        XCTAssertEqual(sut.day.lowerBound, startOfDay)
        XCTAssertEqual(sut.day.upperBound, endOfDay)
    }

    func test_setDayAndTime_sets_time_to_end_of_term_if_time_passed_in_is_after_term() {
        let sut = DayAndTime()

        let endOfTerm = Date(timeIntervalSince1970: 86400)
        sut.term = Date(timeIntervalSince1970: 0) ... endOfTerm

        sut.setDayAndTime()

        XCTAssertEqual(sut.time, endOfTerm)
    }

    func test_setDayAndTime_sets_time_to_beginning_of_term_if_time_passed_in_is_before_term() {
        let sut = DayAndTime()

        let startOfTerm = Date.now.addingTimeInterval(3600)
        sut.term = startOfTerm ... .distantFuture

        sut.setDayAndTime()

        XCTAssertEqual(sut.time, startOfTerm)
    }

    func test_setDayAndTime_triggers_objectWillChage() {
        let sut = DayAndTime()

        expectChanges(for: sut.objectWillChange.eraseToAnyPublisher()) {
            sut.setDayAndTime()
        }
    }

    // MARK: - setDay
    func test_setDay_sets_day_to_date_passed_in() {
        let sut = DayAndTime()

        let newTime = Date.now.advanceBySmallRandomNumberOfDays()
        sut.setDay(to: newTime)

        let expected = Calendar.current.startOfDay(for: newTime)
        XCTAssertEqual(expected, sut.startOfDay)
    }

    func test_setDay_preserves_time_after_startOfDay() {
        let sut = DayAndTime()

        let startingTimeOfDay = sut.time.timeIntervalSince(sut.startOfDay)

        let newTime = Date.now.advanceBySmallRandomNumberOfDays()
        sut.setDay(to: newTime)
        let newTimeOfDay = newTime.timeIntervalSince(sut.calendar.startOfDay(for: newTime))

        // date and time are just synonyms
        XCTAssertEqual(startingTimeOfDay, newTimeOfDay, accuracy: 0.001)
    }

    func test_setDay_sets_time_to_now_if_no_date_passed_in() {
        let sut = DayAndTime()
        let oneSecondAhead = sut.time.addingTimeInterval(1)
        // move the time up 1 second
        sut.setDayAndTime(to: oneSecondAhead)
        // now move it up several days
        sut.setDay(to: sut.time.advanceBySmallRandomNumberOfDays())

        // now set the day to today again
        sut.setDay()

        // now the sut's time should be one second ahead of where it was when it was first created
        XCTAssertEqual(sut.time.timeIntervalSince1970, oneSecondAhead.timeIntervalSince1970, accuracy: 0.001)
    }

    func test_setDay_sets_time_to_end_of_term_if_time_passed_in_is_after_term() {
        let sut = DayAndTime()

        let endOfTerm = Date(timeIntervalSince1970: 86400)
        sut.term = Date(timeIntervalSince1970: 0) ... endOfTerm

        sut.setDay()

        XCTAssertEqual(sut.time, endOfTerm)
    }

    func test_setDay_sets_time_to_beginning_of_term_if_time_passed_in_is_before_term() {
        let sut = DayAndTime()

        let startOfTerm = Date.now.addingTimeInterval(3600)
        sut.term = startOfTerm ... .distantFuture

        sut.setDay()

        XCTAssertEqual(sut.time, startOfTerm)
    }

    func test_setDay_triggers_objectWillChage() {
        let sut = DayAndTime()

        expectChanges(for: sut.objectWillChange.eraseToAnyPublisher()) {
            sut.setDay()
        }
    }

    // MARK: - stepForwardOneHour()

    func test_stepForwardOneHour_does_nothing_if_time_is_end_of_day() {
        let sut = DayAndTime()

        sut.setDayAndTime(to: sut.day.upperBound.addingTimeInterval(.random(in: -3599 ... -1)))
        let expected = sut.time

        XCTAssertEqual(sut.time, expected)
    }

    // another way of testing the same thing: if the time is within an hour of the end of the day, then do noithing
    func test_stepForwardOneHour_does_nothing_if_time_is_less_than_one_hour_before_end_of_day() throws {
        let sut = DayAndTime()
        let newtime = Calendar.current.date(byAdding: DateComponents(minute: .random(in: -59 ... -1)), to: sut.day.upperBound)!
        sut.setDayAndTime(to: newtime)
        let expected = sut.time

        XCTAssertEqual(sut.time, expected)
    }

    func test_stepForwardOneHour_does_nothing_if_time_is_after_term() {
        let sut = DayAndTime()

        let expected = sut.time

        let endOfTerm = Date.now.addingTimeInterval(1)
        sut.term = .distantPast ... endOfTerm

        sut.stepForwardOneHour()

        XCTAssertEqual(sut.time, expected)
    }

    func test_stepForwardOneHour_advances_time_one_hour_if_time_is_on_the_hour() throws {
        let sut = DayAndTime()
        let newtime = Calendar.current.date(byAdding: DateComponents(hour: .random(in: 1 ... 23)), to: sut.day.lowerBound)!
        let expected = Calendar.current.date(byAdding: DateComponents(hour: 1), to: newtime)
        sut.setDayAndTime(to: newtime) // TODO: set to midday


        sut.stepForwardOneHour()

        XCTAssertEqual(sut.time, expected)
    }

    func test_stepForwardOneHour_advances_time_to_the_next_hour_if_time_is_not_on_the_hour() throws {
        let sut = DayAndTime()

        let hours = Int.random(in: 0 ... 22)
        let newtime = Calendar.current.date(byAdding: DateComponents(hour: hours, minute: .random(in: 1 ... 59), second: .random(in: 0 ... 59)), to: sut.day.lowerBound)!
        let expected = Calendar.current.date(byAdding: DateComponents(hour: hours + 1), to: sut.day.lowerBound)
        sut.setDayAndTime(to: newtime) // TODO: set to midday

        sut.stepForwardOneHour()

        XCTAssertEqual(sut.time, expected)
    }

    func test_stepForwardOneHour_triggers_objectWillChage() {
        let sut = DayAndTime()

        expectChanges(for: sut.objectWillChange.eraseToAnyPublisher()) {
            sut.stepForwardOneHour()
        }
    }

    // MARK: - canStepForwardOneHour()

    func test_canStepForwardOneHour_returns_false_if_time_is_end_of_day() {
        let sut = DayAndTime()

        sut.setDayAndTime(to: sut.day.upperBound.addingTimeInterval(.random(in: -3599 ... -1)))

        XCTAssertFalse(sut.canStepForwardOneHour())
    }

    // another way of testing the same thing: if the time is within an hour of the end of the day, then throw an error
    func test_canStepForwardOneHour_returns_false_if_time_is_less_than_one_hour_before_end_of_day() throws {
        let sut = DayAndTime()
        let newtime = Calendar.current.date(byAdding: DateComponents(minute: .random(in: -59 ... -1)), to: sut.day.upperBound)!
        sut.setDayAndTime(to: newtime)

        XCTAssertFalse(sut.canStepForwardOneHour())
    }

    // TODO: this fails occasionally
    func test_canStepForwardOneHour_returns_true_if_not_at_end_of_day() {
        let sut = DayAndTime()

        let newtime = Calendar.current.date(byAdding: DateComponents(hour: .random(in: 0 ... 23), minute: .random(in: 0 ... 60)), to: sut.day.lowerBound)!

        sut.setDayAndTime(to: newtime)

        XCTAssert(sut.canStepForwardOneHour())
    }

    func test_canStepForwardOneHour_returns_false_if_time_is_after_term() {
        let sut = DayAndTime()

        let endOfTerm = Date.now.addingTimeInterval(1)
        sut.term = .distantPast ... endOfTerm

        XCTAssertFalse(sut.canStepForwardOneHour())
    }

    // MARK: - stepBackOneHour()

    func test_stepBackOneHour_does_nothing_if_time_is_beginning_of_day() {
        let sut = DayAndTime()

        sut.setDayAndTime(to: sut.day.lowerBound)
        let expected = sut.time

        sut.stepBackOneHour()

        XCTAssertEqual(sut.time, expected)
    }

    func test_stepBackOneHour_does_nothing_if_time_is_before_term() {
        let sut = DayAndTime()

        let expected = sut.time

        let beginningOfTerm = Date.now.addingTimeInterval(-1)
        sut.term = beginningOfTerm ... .distantFuture

        sut.stepBackOneHour()

        XCTAssertEqual(sut.time, expected)
    }

    func test_stepBackOneHour_steps_time_back_one_hour_if_time_is_on_the_hour() throws {
        let sut = DayAndTime()
        let newtime = Calendar.current.date(byAdding: DateComponents(hour: .random(in: 1 ... 23)), to: sut.day.lowerBound)!
        let expected = Calendar.current.date(byAdding: DateComponents(hour: -1), to: newtime)
        sut.setDayAndTime(to: newtime)


        sut.stepBackOneHour()

        XCTAssertEqual(sut.time, expected)
    }

    func test_stepBackOneHour_steps_time_back_to_the_previous_hour_if_time_is_not_on_the_hour() throws {
        let sut = DayAndTime()

        let hours = Int.random(in: 0 ... 22)
        let newtime = Calendar.current.date(byAdding: DateComponents(hour: hours, minute: .random(in: 1 ... 59), second: .random(in: 0 ... 59)), to: sut.day.lowerBound)!
        let expected = Calendar.current.date(byAdding: DateComponents(hour: hours), to: sut.day.lowerBound)
        sut.setDayAndTime(to: newtime)

        sut.stepBackOneHour()

        XCTAssertEqual(sut.time, expected)
    }

    func test_stepBackOneHour_triggers_objectWillChage() {
        let sut = DayAndTime()

        expectChanges(for: sut.objectWillChange.eraseToAnyPublisher()) {
            sut.stepBackOneHour()
        }
    }

    // MARK: - canStepBackOneHour()

    func test_canStepBackOneHour_returns_false_if_time_is_beginning_of_day() {
        let sut = DayAndTime()

        sut.setDayAndTime(to: sut.day.lowerBound)

        XCTAssertFalse(sut.canStepBackOneHour())
    }

    func test_canStepBackOneHour_returns_false_if_time_is_before_term() {
        let sut = DayAndTime()

        let beginningOfTerm = Date.now.addingTimeInterval(-1)
        sut.term = beginningOfTerm ... .distantFuture

        XCTAssertFalse(sut.canStepBackOneHour())
    }

    func test_canStepBackOneHour_returns_true_if_not_at_beginning_of_day() {
        let sut = DayAndTime()

        let newtime = Calendar.current.date(byAdding: DateComponents(hour: .random(in: 0 ... 23), minute: .random(in: 1 ... 60)), to: sut.day.lowerBound)!

        sut.setDayAndTime(to: newtime)

        XCTAssert(sut.canStepBackOneHour())
    }

    // MARK: - stepForwardOneDay()

    func test_stepForwardOneDay_does_nothing_if_step_would_go_outside_term() throws {
        let sut = DayAndTime()
        let expected = sut.time

        sut.term = .distantPast ... sut.time.addingTimeInterval(1)

        sut.stepForwardOneDay()

        XCTAssertEqual(sut.time, expected)
    }

    func test_stepForwardOneDay_steps_time_forward_one_day() throws {
        let sut = DayAndTime()
        let expected = Calendar.current.date(byAdding: DateComponents(day: 1), to: sut.time)

        sut.stepForwardOneDay()

        XCTAssertEqual(sut.time, expected)
    }

    func test_stepForwardOneDay_triggers_objectWillChage() {
        let sut = DayAndTime()

        expectChanges(for: sut.objectWillChange.eraseToAnyPublisher()) {
            sut.stepForwardOneDay()
        }
    }

    // MARK: - canStepForwardOneDay()

    func test_canStepForwardOneDay_returns_false_if_step_would_take_time_outside_of_term() {

        let sut = DayAndTime()

        sut.term = .distantPast ... sut.time.addingTimeInterval(1)

        XCTAssertFalse(sut.canStepForwardOneDay())
    }

    func test_canStepForwardOneDay_returns_true_if_step_would_leave_time_within_term() {

        let sut = DayAndTime()

        XCTAssert(sut.canStepForwardOneDay())
    }

    // MARK: - stepBackwardOneDay()

    func test_stepBackwardOneDay_does_nothing_if_step_would_go_outside_term() throws {
        let sut = DayAndTime()
        let expected = sut.time

        sut.term = sut.time.addingTimeInterval(-1) ... .distantFuture

        sut.stepBackwardOneDay()

        XCTAssertEqual(sut.time, expected)
    }

    func test_stepBackwardOneDay_steps_time_backward_one_day() throws {
        let sut = DayAndTime()
        let expected = Calendar.current.date(byAdding: DateComponents(day: -1), to: sut.time)

        sut.stepBackwardOneDay()

        XCTAssertEqual(sut.time, expected)
    }

    func test_stepBackwardOneDay_triggers_objectWillChage() {
        let sut = DayAndTime()

        expectChanges(for: sut.objectWillChange.eraseToAnyPublisher()) {
            sut.stepBackwardOneDay()
        }
    }

    // MARK: - canStepBackwardOneDay()

    func test_canStepBackwardOneDay_returns_false_if_step_would_take_time_outside_of_term() {

        let sut = DayAndTime()

        sut.term = sut.time.addingTimeInterval(1) ... .distantFuture

        XCTAssertFalse(sut.canStepBackwardOneDay())
    }

    func test_canStepBackwardOneDay_returns_true_if_step_would_leave_time_within_term() {

        let sut = DayAndTime()

        XCTAssert(sut.canStepBackwardOneDay())
    }

    // MARK: - matchesDay(for:)

    func test_matchesDay_returns_false_if_date_passed_in_is_not_on_the_same_day_as_the_time() {
        let sut = DayAndTime()

        let oneDayBefore = Calendar.current.date(byAdding: DateComponents(day: 1), to: sut.time)!

        XCTAssertFalse(sut.matchesDay(of: oneDayBefore))
    }

    func test_matchesDay_returns_true_if_date_passed_in_is_on_the_same_day_as_the_time() {
        let sut = DayAndTime()

        let oneDayBefore = Calendar.current.date(byAdding: DateComponents(minute: 1), to: sut.time)!

        XCTAssert(sut.matchesDay(of: oneDayBefore))
    }

    // MARK: - isToday

    func test_isToday_returns_false_if_day_is_not_the_same_as_the_current_day() {
        let sut = DayAndTime()

        let oneDayBefore = Calendar.current.date(byAdding: DateComponents(day: 1), to: sut.time)!
        sut.setDayAndTime(to: oneDayBefore)

        XCTAssertFalse(sut.isToday)
    }

    func test_isToday_returns_true_if_day_is_the_same_as_the_current_day() {
        let sut = DayAndTime()

        let oneDayBefore = Calendar.current.date(byAdding: DateComponents(minute: 1), to: sut.time)!
        sut.setDayAndTime(to: oneDayBefore)

        XCTAssert(sut.isToday)
    }

    // MARK: - isNow

    func test_isNow_returns_false_if_time_is_not_very_close_to_the_current_time() {
        let sut = DayAndTime()

        let oneDayBefore = Calendar.current.date(byAdding: DateComponents(minute: 1), to: sut.time)!
        sut.setDayAndTime(to: oneDayBefore)

        XCTAssertFalse(sut.isNow)
    }

    func test_isNow_returns_true_if_day_is_the_same_as_the_current_day() {
        let sut = DayAndTime()

        let oneDayBefore = Calendar.current.date(byAdding: DateComponents(second: 1), to: sut.time)!
        sut.setDayAndTime(to: oneDayBefore)

        XCTAssert(sut.isNow)
    }

}

// MARK: - Helpers

fileprivate extension Date {
    func advanceBySmallRandomNumberOfDays() -> Date {
        let offset = DateComponents(day: .random(in: 10...1000))
        return Calendar.current.date(byAdding: offset, to: .now)!
    }
}
