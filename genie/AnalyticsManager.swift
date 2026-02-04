//
//  AnalyticsManager.swift
//  genie
//
//  Analytics engine for processing routine logs and generating insights
//

import Foundation
import SwiftData

// MARK: - Insight Models

struct EventInsight {
    let eventType: EventType
    let averageTime: Date?
    let earliestTime: Date?
    let latestTime: Date?
    let consistency: Double // 0.0 to 1.0
    let occurrenceCount: Int
}

struct DurationInsight {
    let fromEvent: EventType
    let toEvent: EventType
    let averageDuration: TimeInterval
    let minDuration: TimeInterval
    let maxDuration: TimeInterval
    let samples: Int
}

struct DailySummary {
    let date: Date
    let logs: [RoutineLog]
    let completionRate: Double // Percentage of events logged
}

struct RoutineSuggestion {
    let eventType: EventType
    let suggestedTime: Date
    let confidence: Double // 0.0 to 1.0
    let reasoning: String
}

struct OutlierInfo {
    let isOutlier: Bool
    let deviationMinutes: Int
    let averageTime: Date?
    let thresholdMinutes: Int
}

// MARK: - Analytics Manager

@Observable
class AnalyticsManager {
    private var logs: [RoutineLog] = []
    private var feedbacks: [RoutineSuccess] = []
    
    init(logs: [RoutineLog] = [], feedbacks: [RoutineSuccess] = []) {
        self.logs = logs
        self.feedbacks = feedbacks
    }
    
    func updateLogs(_ logs: [RoutineLog]) {
        self.logs = logs
    }
    
    func updateFeedbacks(_ feedbacks: [RoutineSuccess]) {
        self.feedbacks = feedbacks
    }
    
    // MARK: - Daily Grouping
    
    func getDailySummaries(days: Int = 5) -> [DailySummary] {
        let calendar = Calendar.current
        let now = Date()
        var summaries: [DailySummary] = []
        
        for dayOffset in 0..<days {
            guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: targetDate)
            
            let dayLogs = logs.filter { log in
                calendar.isDate(log.timestamp, inSameDayAs: startOfDay)
            }.sorted { $0.timestamp < $1.timestamp }
            
            let completionRate = Double(dayLogs.count) / Double(EventType.allCases.count)
            
            summaries.append(DailySummary(
                date: startOfDay,
                logs: dayLogs,
                completionRate: completionRate
            ))
        }
        
        return summaries.sorted { $0.date > $1.date }
    }
    
    // MARK: - Event Time Analysis
    
    func getEventInsight(for eventType: EventType, days: Int = 5) -> EventInsight? {
        let calendar = Calendar.current
        let now = Date()
        
        // Get logs for the past N days
        var eventLogs: [RoutineLog] = []
        for dayOffset in 0..<days {
            guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: targetDate)
            
            let dayLog = logs.filter { log in
                calendar.isDate(log.timestamp, inSameDayAs: startOfDay) && log.eventType == eventType
            }.first
            
            if let dayLog = dayLog {
                eventLogs.append(dayLog)
            }
        }
        
        guard !eventLogs.isEmpty else { return nil }
        
        // Extract time components (hour and minute) for averaging
        let timeComponents = eventLogs.map { log in
            calendar.dateComponents([.hour, .minute], from: log.timestamp)
        }
        
        // Calculate average time in minutes from midnight
        let minutesFromMidnight = timeComponents.compactMap { component -> Int? in
            guard let hour = component.hour, let minute = component.minute else { return nil }
            return hour * 60 + minute
        }
        
        guard !minutesFromMidnight.isEmpty else { return nil }
        
        let avgMinutes = minutesFromMidnight.reduce(0, +) / minutesFromMidnight.count
        let avgHour = avgMinutes / 60
        let avgMinute = avgMinutes % 60
        
        var avgComponents = DateComponents()
        avgComponents.hour = avgHour
        avgComponents.minute = avgMinute
        let averageTime = calendar.date(from: avgComponents)
        
        // Find earliest and latest
        let sortedLogs = eventLogs.sorted { $0.timestamp < $1.timestamp }
        let earliestTime = sortedLogs.first?.timestamp
        let latestTime = sortedLogs.last?.timestamp
        
        // Calculate consistency (based on standard deviation of minutes)
        let mean = Double(minutesFromMidnight.reduce(0, +)) / Double(minutesFromMidnight.count)
        let variance = minutesFromMidnight.map { pow(Double($0) - mean, 2) }.reduce(0, +) / Double(minutesFromMidnight.count)
        let standardDeviation = sqrt(variance)
        
        // Consistency score: higher when std dev is lower (within 60 min window = perfect)
        let consistency = max(0, 1.0 - (standardDeviation / 60.0))
        
        return EventInsight(
            eventType: eventType,
            averageTime: averageTime,
            earliestTime: earliestTime,
            latestTime: latestTime,
            consistency: consistency,
            occurrenceCount: eventLogs.count
        )
    }
    
    func getAllEventInsights(days: Int = 5) -> [EventInsight] {
        return EventType.allCases.compactMap { getEventInsight(for: $0, days: days) }
    }
    
    // MARK: - Duration Analysis
    
    func getDurationInsight(from: EventType, to: EventType, days: Int = 5) -> DurationInsight? {
        let calendar = Calendar.current
        let now = Date()
        
        var durations: [TimeInterval] = []
        
        for dayOffset in 0..<days {
            guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: targetDate)
            
            let dayLogs = logs.filter { log in
                calendar.isDate(log.timestamp, inSameDayAs: startOfDay)
            }.sorted { $0.timestamp < $1.timestamp }
            
            // Find consecutive events
            if let fromLog = dayLogs.first(where: { $0.eventType == from }),
               let toLog = dayLogs.first(where: { $0.eventType == to }),
               toLog.timestamp > fromLog.timestamp {
                let duration = toLog.timestamp.timeIntervalSince(fromLog.timestamp)
                durations.append(duration)
            }
        }
        
        guard !durations.isEmpty else { return nil }
        
        let avgDuration = durations.reduce(0, +) / Double(durations.count)
        let minDuration = durations.min() ?? 0
        let maxDuration = durations.max() ?? 0
        
        return DurationInsight(
            fromEvent: from,
            toEvent: to,
            averageDuration: avgDuration,
            minDuration: minDuration,
            maxDuration: maxDuration,
            samples: durations.count
        )
    }
    
    // MARK: - Common Duration Insights
    
    func getCommuteInsights(days: Int = 5) -> [DurationInsight] {
        return [
            getDurationInsight(from: .leavingHome, to: .boardingBus, days: days),
            getDurationInsight(from: .leavingHome, to: .boardingSubway, days: days),
            getDurationInsight(from: .boardingBus, to: .arrivingAtWork, days: days),
            getDurationInsight(from: .boardingSubway, to: .arrivingAtWork, days: days),
            getDurationInsight(from: .leavingWork, to: .arrivingHome, days: days)
        ].compactMap { $0 }
    }
    
    func getSleepInsights(days: Int = 5) -> DurationInsight? {
        return getDurationInsight(from: .bedTime, to: .wakeUp, days: days)
    }
    
    // MARK: - Routine Suggestions
    
    func getRoutineSuggestions(days: Int = 5) -> [RoutineSuggestion] {
        var suggestions: [RoutineSuggestion] = []
        
        // Suggest wake-up time based on work arrival time
        if let wakeUpInsight = getEventInsight(for: .wakeUp, days: days),
           let avgWakeUpTime = wakeUpInsight.averageTime,
           wakeUpInsight.consistency > 0.6 {
            
            let calendar = Calendar.current
            let timeString = calendar.component(.hour, from: avgWakeUpTime).formatted() + ":" +
                           String(format: "%02d", calendar.component(.minute, from: avgWakeUpTime))
            
            suggestions.append(RoutineSuggestion(
                eventType: .wakeUp,
                suggestedTime: avgWakeUpTime,
                confidence: wakeUpInsight.consistency,
                reasoning: "Based on your routine, waking up at \(timeString) keeps you on schedule."
            ))
        }
        
        // Suggest leaving time based on commute duration
        if let leavingHomeInsight = getEventInsight(for: .leavingHome, days: days),
           let avgLeaveTime = leavingHomeInsight.averageTime,
           let commuteDuration = getDurationInsight(from: .leavingHome, to: .arrivingAtWork, days: days),
           commuteDuration.samples >= 2 {
            
            let avgMinutes = Int(commuteDuration.averageDuration / 60)
            suggestions.append(RoutineSuggestion(
                eventType: .leavingHome,
                suggestedTime: avgLeaveTime,
                confidence: leavingHomeInsight.consistency,
                reasoning: "Your commute typically takes \(avgMinutes) minutes. Leaving at your usual time ensures you arrive on schedule."
            ))
        }
        
        // Suggest bedtime based on sleep duration and wake time
        if let bedTimeInsight = getEventInsight(for: .bedTime, days: days),
           let avgBedTime = bedTimeInsight.averageTime,
           bedTimeInsight.consistency > 0.5 {
            
            let calendar = Calendar.current
            let timeString = calendar.component(.hour, from: avgBedTime).formatted() + ":" +
                           String(format: "%02d", calendar.component(.minute, from: avgBedTime))
            
            suggestions.append(RoutineSuggestion(
                eventType: .bedTime,
                suggestedTime: avgBedTime,
                confidence: bedTimeInsight.consistency,
                reasoning: "You typically sleep at \(timeString). Maintaining this schedule supports healthy sleep habits."
            ))
        }
        
        return suggestions
    }
    
    // MARK: - Consistency Score
    
    func getOverallConsistencyScore(days: Int = 5) -> Double {
        let insights = getAllEventInsights(days: days)
        guard !insights.isEmpty else { return 0.0 }
        
        let totalConsistency = insights.map { $0.consistency }.reduce(0, +)
        return totalConsistency / Double(insights.count)
    }
    
    // MARK: - Outlier Detection
    
    func checkIfOutlier(
        eventType: EventType,
        timestamp: Date,
        thresholdMinutes: Int = 30,
        days: Int = 7
    ) -> OutlierInfo {
        guard let insight = getEventInsight(for: eventType, days: days),
              let averageTime = insight.averageTime,
              insight.occurrenceCount >= 3 else {
            // Not enough data to determine outlier status
            return OutlierInfo(
                isOutlier: false,
                deviationMinutes: 0,
                averageTime: nil,
                thresholdMinutes: thresholdMinutes
            )
        }
        
        let calendar = Calendar.current
        
        // Extract time components (hour and minute) from both dates
        let avgComponents = calendar.dateComponents([.hour, .minute], from: averageTime)
        let timestampComponents = calendar.dateComponents([.hour, .minute], from: timestamp)
        
        guard let avgHour = avgComponents.hour,
              let avgMinute = avgComponents.minute,
              let tsHour = timestampComponents.hour,
              let tsMinute = timestampComponents.minute else {
            return OutlierInfo(
                isOutlier: false,
                deviationMinutes: 0,
                averageTime: averageTime,
                thresholdMinutes: thresholdMinutes
            )
        }
        
        // Convert to minutes from midnight
        let avgMinutesFromMidnight = avgHour * 60 + avgMinute
        let tsMinutesFromMidnight = tsHour * 60 + tsMinute
        
        // Calculate deviation
        var deviation = tsMinutesFromMidnight - avgMinutesFromMidnight
        
        // Handle day wrap-around (e.g., bedtime near midnight)
        if abs(deviation) > 720 { // 12 hours
            if deviation > 0 {
                deviation = deviation - 1440 // Subtract 24 hours
            } else {
                deviation = deviation + 1440 // Add 24 hours
            }
        }
        
        let deviationMinutes = abs(deviation)
        let isOutlier = deviationMinutes >= thresholdMinutes
        
        return OutlierInfo(
            isOutlier: isOutlier,
            deviationMinutes: deviationMinutes,
            averageTime: averageTime,
            thresholdMinutes: thresholdMinutes
        )
    }
    
    func getOutlierLogs(days: Int = 5, thresholdMinutes: Int = 30) -> [RoutineLog] {
        let calendar = Calendar.current
        let now = Date()
        
        var outlierLogs: [RoutineLog] = []
        
        for dayOffset in 0..<days {
            guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: targetDate)
            
            let dayLogs = logs.filter { log in
                calendar.isDate(log.timestamp, inSameDayAs: startOfDay)
            }
            
            for log in dayLogs {
                let outlierInfo = checkIfOutlier(
                    eventType: log.eventType,
                    timestamp: log.timestamp,
                    thresholdMinutes: thresholdMinutes,
                    days: days
                )
                
                if outlierInfo.isOutlier {
                    outlierLogs.append(log)
                }
            }
        }
        
        return outlierLogs
    }
    
    // MARK: - Adaptive Learning & Feedback
    
    func getFeedbackSummary(for eventType: EventType, days: Int = 30) -> FeedbackSummary? {
        let calendar = Calendar.current
        let now = Date()
        
        // Get feedbacks for the past N days
        var relevantFeedbacks: [RoutineSuccess] = []
        for dayOffset in 0..<days {
            guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: targetDate)
            
            let dayFeedbacks = feedbacks.filter { feedback in
                calendar.isDate(feedback.timestamp, inSameDayAs: startOfDay) && feedback.eventType == eventType
            }
            
            relevantFeedbacks.append(contentsOf: dayFeedbacks)
        }
        
        guard !relevantFeedbacks.isEmpty else { return nil }
        
        let successCount = relevantFeedbacks.filter { $0.wasSuccessful }.count
        let failureCount = relevantFeedbacks.count - successCount
        let successRate = Double(successCount) / Double(relevantFeedbacks.count)
        
        let totalAdjustment = relevantFeedbacks.map { $0.adjustmentApplied }.reduce(0, +)
        let averageAdjustment = relevantFeedbacks.isEmpty ? 0 : totalAdjustment / relevantFeedbacks.count
        
        let lastFeedback = relevantFeedbacks.sorted { $0.timestamp > $1.timestamp }.first
        
        return FeedbackSummary(
            eventType: eventType,
            totalAttempts: relevantFeedbacks.count,
            successCount: successCount,
            failureCount: failureCount,
            successRate: successRate,
            averageAdjustment: averageAdjustment,
            lastFeedback: lastFeedback
        )
    }
    
    func getAdaptiveAdjustment(
        for eventType: EventType,
        baseTime: Date,
        days: Int = 7
    ) -> AdaptiveAdjustment? {
        guard let feedbackSummary = getFeedbackSummary(for: eventType, days: days) else {
            return nil
        }
        
        // Calculate adjustment based on success rate
        var adjustmentMinutes = 0
        var reason = ""
        var confidence = 0.0
        
        if feedbackSummary.totalAttempts < 3 {
            // Not enough data
            return nil
        }
        
        if feedbackSummary.successRate < 0.5 {
            // Less than 50% success - need significant adjustment
            adjustmentMinutes = -10 // 10 minutes earlier
            reason = "Adjusting earlier due to low success rate (\(feedbackSummary.successPercentage)%)"
            confidence = 0.8
        } else if feedbackSummary.successRate < 0.7 {
            // 50-70% success - moderate adjustment
            adjustmentMinutes = -5 // 5 minutes earlier
            reason = "Fine-tuning based on recent misses"
            confidence = 0.6
        } else if feedbackSummary.successRate >= 0.9 {
            // >90% success - might be able to leave later
            if feedbackSummary.totalAttempts >= 10 {
                adjustmentMinutes = 2 // 2 minutes later (cautious)
                reason = "High success rate allows slight optimization"
                confidence = 0.5
            } else {
                adjustmentMinutes = 0
                reason = "Maintaining current schedule (working well)"
                confidence = 0.9
            }
        } else {
            // 70-90% success - no change needed
            adjustmentMinutes = 0
            reason = "Current schedule is working well"
            confidence = 0.8
        }
        
        let calendar = Calendar.current
        guard let adjustedTime = calendar.date(
            byAdding: .minute,
            value: adjustmentMinutes,
            to: baseTime
        ) else {
            return nil
        }
        
        return AdaptiveAdjustment(
            eventType: eventType,
            originalTime: baseTime,
            adjustedTime: adjustedTime,
            adjustmentMinutes: adjustmentMinutes,
            reason: reason,
            confidence: confidence
        )
    }
    
    func getRecentAdjustment(for eventType: EventType) -> AdaptiveAdjustment? {
        // Get the most recent feedback
        let recentFeedbacks = feedbacks
            .filter { $0.eventType == eventType }
            .sorted { $0.timestamp > $1.timestamp }
        
        guard let lastFeedback = recentFeedbacks.first else { return nil }
        
        // Check if it was within the last 24 hours
        let hoursAgo = Date().timeIntervalSince(lastFeedback.timestamp) / 3600
        guard hoursAgo <= 24 else { return nil }
        
        // If it was a miss, return adjustment info
        if !lastFeedback.wasSuccessful {
            let adjustmentMinutes = -5 // Default 5 min earlier
            let calendar = Calendar.current
            let now = Date()
            
            guard let adjustedTime = calendar.date(
                byAdding: .minute,
                value: adjustmentMinutes,
                to: now
            ) else {
                return nil
            }
            
            return AdaptiveAdjustment(
                eventType: eventType,
                originalTime: now,
                adjustedTime: adjustedTime,
                adjustmentMinutes: adjustmentMinutes,
                reason: "Based on yesterday's feedback",
                confidence: 0.7
            )
        }
        
        return nil
    }
    
    func getAllFeedbackSummaries(days: Int = 30) -> [FeedbackSummary] {
        // Get feedback summaries for commute-related events
        let commuteEvents: [EventType] = [
            .leavingHome,
            .boardingBus,
            .boardingSubway,
            .boardingReturnBus,
            .boardingReturnSubway
        ]
        
        return commuteEvents.compactMap { getFeedbackSummary(for: $0, days: days) }
    }
}

// MARK: - Helper Extensions

extension TimeInterval {
    var minutesFormatted: String {
        let minutes = Int(self / 60)
        return "\(minutes) min"
    }
    
    var hoursMinutesFormatted: String {
        let hours = Int(self / 3600)
        let minutes = Int((self.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
