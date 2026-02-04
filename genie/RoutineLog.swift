//
//  RoutineLog.swift
//  genie
//
//  A SwiftData model for storing daily routine timestamps
//

import Foundation
import SwiftData

@Model
final class RoutineLog {
    var id: UUID
    var eventType: EventType
    var timestamp: Date
    
    init(eventType: EventType, timestamp: Date = Date()) {
        self.id = UUID()
        self.eventType = eventType
        self.timestamp = timestamp
    }
    
    // Computed property for display formatting
    var formattedTime: String {
        timestamp.formatted(date: .omitted, time: .shortened)
    }
    
    var formattedDate: String {
        timestamp.formatted(date: .abbreviated, time: .omitted)
    }
}

// MARK: - Event Type Enum
enum EventType: String, Codable, CaseIterable {
    case wakeUp = "Wake Up"
    case leavingHome = "Leaving Home"
    case boardingSubway = "Boarding Subway"
    case boardingBus = "Boarding Bus"
    case arrivingAtWork = "Arriving at Work"
    case lunchTime = "Lunch Time"
    case leavingWork = "Leaving Work"
    case boardingReturnBus = "Boarding Return Bus"
    case boardingReturnSubway = "Boarding Return Subway"
    case arrivingHome = "Arriving Home"
    case dinnerTime = "Dinner Time"
    case hobbyTime = "Hobby/Study Time"
    case bedTime = "Bed Time"
    
    // SF Symbol for each event type
    var icon: String {
        switch self {
        case .wakeUp: return "sunrise.fill"
        case .leavingHome: return "door.left.hand.open"
        case .boardingBus: return "bus.fill"
        case .boardingSubway: return "tram.fill"
        case .arrivingAtWork: return "building.2.fill"
        case .lunchTime: return "fork.knife"
        case .leavingWork: return "briefcase.fill"
        case .boardingReturnBus: return "bus.fill"
        case .boardingReturnSubway: return "tram.fill"
        case .arrivingHome: return "house.fill"
        case .dinnerTime: return "takeoutbag.and.cup.and.straw.fill"
        case .hobbyTime: return "book.fill"
        case .bedTime: return "moon.stars.fill"
        }
    }
    
    // Accent color for visual differentiation
    var accentColor: String {
        switch self {
        case .wakeUp: return "orange"
        case .leavingHome, .arrivingHome: return "blue"
        case .boardingBus, .boardingReturnBus: return "green"
        case .boardingSubway, .boardingReturnSubway: return "purple"
        case .arrivingAtWork, .leavingWork: return "indigo"
        case .lunchTime, .dinnerTime: return "pink"
        case .hobbyTime: return "teal"
        case .bedTime: return "indigo"
        }
    }
}
