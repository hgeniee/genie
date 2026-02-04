//
//  RoutineSuccess.swift
//  genie
//
//  Feedback tracking model for adaptive learning
//

import Foundation
import SwiftData

@Model
final class RoutineSuccess {
    var id: UUID
    var eventType: EventType
    var timestamp: Date
    var wasSuccessful: Bool
    var targetEventType: EventType? // e.g., boardingBus when evaluating leavingHome
    var adjustmentApplied: Int // Minutes adjusted (negative = earlier)
    var notes: String?
    
    init(
        eventType: EventType,
        timestamp: Date = Date(),
        wasSuccessful: Bool,
        targetEventType: EventType? = nil,
        adjustmentApplied: Int = 0,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.eventType = eventType
        self.timestamp = timestamp
        self.wasSuccessful = wasSuccessful
        self.targetEventType = targetEventType
        self.adjustmentApplied = adjustmentApplied
        self.notes = notes
    }
    
    var formattedTime: String {
        timestamp.formatted(date: .omitted, time: .shortened)
    }
    
    var formattedDate: String {
        timestamp.formatted(date: .abbreviated, time: .omitted)
    }
}

// MARK: - Feedback Helper

struct FeedbackSummary {
    let eventType: EventType
    let totalAttempts: Int
    let successCount: Int
    let failureCount: Int
    let successRate: Double // 0.0 to 1.0
    let averageAdjustment: Int // Average minutes adjusted
    let lastFeedback: RoutineSuccess?
    
    var successPercentage: Int {
        Int(successRate * 100)
    }
    
    var emoji: String {
        switch successRate {
        case 0.9...: return "🎯"
        case 0.7..<0.9: return "👍"
        case 0.5..<0.7: return "🤔"
        default: return "⚠️"
        }
    }
    
    var statusMessage: String {
        switch successRate {
        case 0.9...: return "Excellent timing!"
        case 0.7..<0.9: return "Good consistency"
        case 0.5..<0.7: return "Room for improvement"
        default: return "Needs adjustment"
        }
    }
}

// MARK: - Adaptive Adjustment

struct AdaptiveAdjustment {
    let eventType: EventType
    let originalTime: Date
    let adjustedTime: Date
    let adjustmentMinutes: Int // Negative = earlier
    let reason: String
    let confidence: Double // 0.0 to 1.0
    
    var adjustmentDescription: String {
        let absMinutes = abs(adjustmentMinutes)
        if adjustmentMinutes < 0 {
            return "\(absMinutes) min earlier"
        } else if adjustmentMinutes > 0 {
            return "\(absMinutes) min later"
        } else {
            return "No change"
        }
    }
}
