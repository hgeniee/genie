//
//  InsightsView.swift
//  genie
//
//  Analytics and insights display for routine patterns
//

import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RoutineLog.timestamp, order: .reverse) private var logs: [RoutineLog]
    
    @State private var analyticsManager = AnalyticsManager()
    @State private var selectedDays: Int = 5
    
    private let dayOptions = [3, 5, 7, 14]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Day Range Picker
                    dayRangePicker
                    
                    // Overall Consistency Score
                    consistencyScoreCard
                    
                    // Event Insights Section
                    eventInsightsSection
                    
                    // Commute Insights
                    if !analyticsManager.getCommuteInsights(days: selectedDays).isEmpty {
                        commuteInsightsSection
                    }
                    
                    // Routine Suggestions
                    if !analyticsManager.getRoutineSuggestions(days: selectedDays).isEmpty {
                        routineSuggestionsSection
                    }
                    
                    // Daily Completion Chart
                    dailyCompletionChart
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                analyticsManager.updateLogs(logs)
            }
            .onChange(of: logs) { _, newLogs in
                analyticsManager.updateLogs(newLogs)
            }
        }
    }
    
    // MARK: - Day Range Picker
    
    private var dayRangePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Analysis Period")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Picker("Days", selection: $selectedDays) {
                ForEach(dayOptions, id: \.self) { days in
                    Text("\(days) Days").tag(days)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Consistency Score Card
    
    private var consistencyScoreCard: some View {
        let score = analyticsManager.getOverallConsistencyScore(days: selectedDays)
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Routine Consistency")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(Int(score * 100))%")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(consistencyColor(for: score))
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 8)
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .trim(from: 0, to: score)
                        .stroke(
                            consistencyColor(for: score),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: score)
                    
                    Image(systemName: consistencyIcon(for: score))
                        .font(.title2)
                        .foregroundStyle(consistencyColor(for: score))
                }
            }
            
            Text(consistencyMessage(for: score))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Event Insights Section
    
    private var eventInsightsSection: some View {
        let insights = analyticsManager.getAllEventInsights(days: selectedDays)
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Event Patterns")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(insights.prefix(5), id: \.eventType) { insight in
                    EventInsightCard(insight: insight)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Commute Insights Section
    
    private var commuteInsightsSection: some View {
        let commuteInsights = analyticsManager.getCommuteInsights(days: selectedDays)
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Commute Analysis")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(commuteInsights, id: \.fromEvent) { insight in
                    DurationInsightCard(insight: insight)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Routine Suggestions Section
    
    private var routineSuggestionsSection: some View {
        let suggestions = analyticsManager.getRoutineSuggestions(days: selectedDays)
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("Suggested Schedule")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(suggestions, id: \.eventType) { suggestion in
                    SuggestionCard(suggestion: suggestion)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Daily Completion Chart
    
    private var dailyCompletionChart: some View {
        let summaries = analyticsManager.getDailySummaries(days: selectedDays)
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Daily Activity")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(summaries, id: \.date) { summary in
                    DailyCompletionRow(summary: summary)
                }
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
    
    // MARK: - Helper Functions
    
    private func consistencyColor(for score: Double) -> Color {
        switch score {
        case 0.8...: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }
    
    private func consistencyIcon(for score: Double) -> String {
        switch score {
        case 0.8...: return "checkmark"
        case 0.5..<0.8: return "minus"
        default: return "exclamationmark"
        }
    }
    
    private func consistencyMessage(for score: Double) -> String {
        switch score {
        case 0.8...: return "Excellent! Your routine is very consistent. Keep up the great work!"
        case 0.5..<0.8: return "Good progress! Try to maintain similar times each day for better consistency."
        default: return "Your routine varies significantly. Consider setting more regular times."
        }
    }
}

// MARK: - Event Insight Card

struct EventInsightCard: View {
    let insight: EventInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: insight.eventType.icon)
                    .font(.title3)
                    .foregroundStyle(Color(insight.eventType.accentColor))
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.eventType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if let avgTime = insight.averageTime {
                        Text("Avg: \(avgTime.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(insight.consistency * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(consistencyColor(for: insight.consistency))
                    
                    Text("\(insight.occurrenceCount) days")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Consistency bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 4)
                    
                    Capsule()
                        .fill(consistencyColor(for: insight.consistency))
                        .frame(width: geometry.size.width * insight.consistency, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
        )
    }
    
    private func consistencyColor(for score: Double) -> Color {
        switch score {
        case 0.8...: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }
}

// MARK: - Duration Insight Card

struct DurationInsightCard: View {
    let insight: DurationInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // From event
                VStack {
                    Image(systemName: insight.fromEvent.icon)
                        .font(.caption)
                        .foregroundStyle(Color(insight.fromEvent.accentColor))
                    Text(insight.fromEvent.rawValue)
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                
                // Arrow with duration
                VStack(spacing: 4) {
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(insight.averageDuration.hoursMinutesFormatted)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text("avg")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                // To event
                VStack {
                    Image(systemName: insight.toEvent.icon)
                        .font(.caption)
                        .foregroundStyle(Color(insight.toEvent.accentColor))
                    Text(insight.toEvent.rawValue)
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Range info
            HStack {
                Text("Range: \(insight.minDuration.minutesFormatted) - \(insight.maxDuration.minutesFormatted)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(insight.samples) samples")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
        )
    }
}

// MARK: - Suggestion Card

struct SuggestionCard: View {
    let suggestion: RoutineSuggestion
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: suggestion.eventType.icon)
                .font(.title3)
                .foregroundStyle(Color(suggestion.eventType.accentColor))
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(suggestion.eventType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(suggestion.reasoning)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                    Text("Confidence: \(Int(suggestion.confidence * 100))%")
                        .font(.caption2)
                }
                .foregroundStyle(.orange)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
        )
    }
}

// MARK: - Daily Completion Row

struct DailyCompletionRow: View {
    let summary: DailySummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(summary.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(summary.logs.count) / \(EventType.allCases.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geometry.size.width * summary.completionRate, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

#Preview {
    InsightsView()
        .modelContainer(for: RoutineLog.self, inMemory: true)
}
