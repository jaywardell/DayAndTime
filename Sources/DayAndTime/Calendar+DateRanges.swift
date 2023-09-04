//
//  Calendar+DateRanges.swift
//  DailyWeatherGraphs
//
//  Created by Joseph Wardell on 8/22/23.
//

import Foundation

extension Calendar {

    /// returns a range of Dates to indicate the day associated with the date passed in from the beginning of the day to the end of the day
    /// - Parameter time: the day and time being queried, as a Date
    /// - Returns: a ClosedRange of Date going from the beginning of the day to the begining of the next day
    func day(for time: Date) -> ClosedRange<Date> {
        let startOfDay = startOfDay(for: time)
        let oneDay = DateComponents(day: 1)
        let endOfDay = date(byAdding: oneDay, to: startOfDay)!

        return startOfDay ... endOfDay
    }
}
