import Foundation
import Combine

struct Habit: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var completedDates: Set<String>

    init(id: UUID = UUID(), name: String, completedDates: Set<String> = []) {
        self.id = id
        self.name = name
        self.completedDates = completedDates
    }
}

final class HabitStore: ObservableObject {
    @Published var habits: [Habit] = []

    private let defaultsKey = "habitTracker.habits"
    private let calendar = Calendar.current
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    init() {
        load()
        if habits.isEmpty {
            habits = [
                Habit(name: "朝の情報発信チェック"),
                Habit(name: "AI時短ツールを1つ試す"),
                Habit(name: "寝る前のスマホ断ち")
            ]
            save()
        }
    }

    func addHabit(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        habits.append(Habit(name: trimmed))
        save()
    }

    func delete(at offsets: IndexSet) {
        habits.remove(atOffsets: offsets)
        save()
    }

    func toggleToday(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        let key = todayKey()
        if habits[index].completedDates.contains(key) {
            habits[index].completedDates.remove(key)
        } else {
            habits[index].completedDates.insert(key)
        }
        save()
    }

    func isCompletedToday(_ habit: Habit) -> Bool {
        habit.completedDates.contains(todayKey())
    }

    func streak(for habit: Habit) -> Int {
        var count = 0
        var cursor = Date()
        if !habit.completedDates.contains(dayFormatter.string(from: cursor)) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
            if !habit.completedDates.contains(dayFormatter.string(from: cursor)) {
                return 0
            }
        }
        while habit.completedDates.contains(dayFormatter.string(from: cursor)) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    func last7Days(for habit: Habit) -> [Bool] {
        var result: [Bool] = []
        for offset in stride(from: 6, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            result.append(habit.completedDates.contains(dayFormatter.string(from: date)))
        }
        return result
    }

    private func todayKey() -> String {
        dayFormatter.string(from: Date())
    }

    private func save() {
        if let data = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([Habit].self, from: data) else { return }
        habits = decoded
    }
}
