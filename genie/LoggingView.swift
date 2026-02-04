//
//  LoggingView.swift
//  genie
//
//  The main logging interface for Phase 1
//

import SwiftUI
import SwiftData

struct LoggingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RoutineLog.timestamp, order: .reverse) private var logs: [RoutineLog]
    
    @State private var showingSuccessAnimation = false
    @State private var lastLoggedEvent: EventType?
    @State private var isManualMode = false
    @State private var manualSelectedEvent: EventType = .wakeUp
    @State private var manualSelectedDate: Date = Date()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Mode Picker
                    modePicker
                    
                    // Today's Summary Card
                    todaySummaryCard
                    
                    if isManualMode {
                        manualEntrySection
                    } else {
                        // Event Logging Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Log Your Day")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                ForEach(EventType.allCases, id: \.self) { eventType in
                                    EventLogButton(
                                        eventType: eventType,
                                        isLogged: hasLoggedToday(eventType),
                                        lastLogTime: getLastLogTime(for: eventType),
                                        onTap: {
                                            logEvent(eventType)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Recent Logs Section
                    if !todayLogs.isEmpty {
                        recentLogsSection
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("genie")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive, action: clearAllLogs) {
                            Label("Clear All Logs", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .overlay {
                if showingSuccessAnimation {
                    successAnimationOverlay
                }
            }
        }
    }
    
    // MARK: - Mode Picker
    private var modePicker: some View {
        Picker("Mode", selection: $isManualMode) {
            Text("Quick Log").tag(false)
            Text("Manual Entry").tag(true)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
    
    // MARK: - Today's Summary Card
    private var todaySummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Progress")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(todayLogs.count) / \(EventType.allCases.count)")
                        .font(.system(.title2, design: .rounded, weight: .semibold))
                }
                
                Spacer()
                
                CircularProgressView(
                    progress: Double(todayLogs.count) / Double(EventType.allCases.count)
                )
                .frame(width: 60, height: 60)
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(
                            width: geometry.size.width * (Double(todayLogs.count) / Double(EventType.allCases.count)),
                            height: 8
                        )
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Manual Entry Section
    private var manualEntrySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Manual Entry")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 16) {
                // Event picker
                Picker("Event", selection: $manualSelectedEvent) {
                    ForEach(EventType.allCases, id: \.self) { eventType in
                        Text(eventType.rawValue).tag(eventType)
                    }
                }
                .pickerStyle(.navigationLink)
                
                // Date & time picker
                DatePicker(
                    "Date & Time",
                    selection: $manualSelectedDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                
                // Save button
                Button {
                    logManualEvent(eventType: manualSelectedEvent, timestamp: manualSelectedDate)
                } label: {
                    HStack {
                        Spacer()
                        Label("Save Entry", systemImage: "tray.and.arrow.down.fill")
                            .font(.headline)
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
            )
            .padding(.horizontal)
        }
    }
    
    // MARK: - Recent Logs Section
    private var recentLogsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Timeline")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                ForEach(todayLogs) { log in
                    TimelineRow(log: log)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
            .padding(.horizontal)
        }
    }
    
    // MARK: - Success Animation Overlay
    private var successAnimationOverlay: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
                
                if let event = lastLoggedEvent {
                    Text("Logged: \(event.rawValue)")
                        .font(.headline)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            .scaleEffect(showingSuccessAnimation ? 1 : 0.5)
            .opacity(showingSuccessAnimation ? 1 : 0)
        }
    }
    
    // MARK: - Helper Functions
    private var todayLogs: [RoutineLog] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return logs.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
            .sorted { $0.timestamp < $1.timestamp } // Oldest first for timeline
    }
    
    private func hasLoggedToday(_ eventType: EventType) -> Bool {
        todayLogs.contains { $0.eventType == eventType }
    }
    
    private func getLastLogTime(for eventType: EventType) -> Date? {
        todayLogs.first { $0.eventType == eventType }?.timestamp
    }
    
    private func logEvent(_ eventType: EventType) {
        let newLog = RoutineLog(eventType: eventType)
        modelContext.insert(newLog)
        handleLogCompletion(for: eventType)
    }
    
    private func logManualEvent(eventType: EventType, timestamp: Date) {
        let newLog = RoutineLog(eventType: eventType, timestamp: timestamp)
        modelContext.insert(newLog)
        handleLogCompletion(for: eventType)
    }
    
    private func handleLogCompletion(for eventType: EventType) {
        // Trigger success animation
        lastLoggedEvent = eventType
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showingSuccessAnimation = true
        }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Hide animation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.2)) {
                showingSuccessAnimation = false
            }
        }
    }
    
    private func clearAllLogs() {
        for log in logs {
            modelContext.delete(log)
        }
    }
}

// MARK: - Event Log Button
struct EventLogButton: View {
    let eventType: EventType
    let isLogged: Bool
    let lastLogTime: Date?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: eventType.icon)
                    .font(.title3)
                    .foregroundStyle(isLogged ? Color(eventType.accentColor) : .secondary)
                    .frame(width: 32)
                
                // Event Name
                VStack(alignment: .leading, spacing: 2) {
                    Text(eventType.rawValue)
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    if let time = lastLogTime {
                        Text(time.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Status Indicator
                if isLogged {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isLogged ? Color(eventType.accentColor).opacity(0.1) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isLogged ? Color(eventType.accentColor).opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Timeline Row
struct TimelineRow: View {
    let log: RoutineLog
    
    var body: some View {
        HStack(spacing: 16) {
            // Timeline dot and line
            VStack(spacing: 0) {
                Circle()
                    .fill(Color(log.eventType.accentColor))
                    .frame(width: 12, height: 12)
                
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(width: 2, height: 40)
            }
            .padding(.leading, 8)
            
            // Event info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: log.eventType.icon)
                        .font(.caption)
                        .foregroundStyle(Color(log.eventType.accentColor))
                    
                    Text(log.eventType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Text(log.formattedTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
            
            Spacer()
        }
    }
}

// MARK: - Circular Progress View
struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 6)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    LoggingView()
        .modelContainer(for: RoutineLog.self, inMemory: true)
}
