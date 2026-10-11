import Foundation
import Combine

final class TimerModel: ObservableObject {
    static let sessionMinutes = 90
    static let totalSeconds = sessionMinutes * 60

    @Published var remainingSeconds: Int = TimerModel.totalSeconds
    @Published var isRunning: Bool = false
    @Published var completedToday: Bool = false

    private var timer: Timer?
    private let defaultsKey = "focusTimer.completedDates"

    init() {
        completedToday = completedDates().contains(todayKey())
    }

    var progress: Double {
        1.0 - Double(remainingSeconds) / Double(Self.totalSeconds)
    }

    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func start() {
        guard !isRunning, remainingSeconds > 0 else { return }
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        pause()
        remainingSeconds = Self.totalSeconds
    }

    private func tick() {
        guard remainingSeconds > 0 else {
            finish()
            return
        }
        remainingSeconds -= 1
        if remainingSeconds == 0 {
            finish()
        }
    }

    private func finish() {
        pause()
        markTodayCompleted()
    }

    private func todayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func completedDates() -> Set<String> {
        let stored = UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []
        return Set(stored)
    }

    private func markTodayCompleted() {
        var dates = completedDates()
        dates.insert(todayKey())
        UserDefaults.standard.set(Array(dates), forKey: defaultsKey)
        completedToday = true
    }

    func streakCount() -> Int {
        let dates = completedDates()
        var count = 0
        var cursor = Date()
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        while dates.contains(formatter.string(from: cursor)) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }
}
