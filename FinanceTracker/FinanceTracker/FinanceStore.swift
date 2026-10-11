import Foundation
import Combine

enum IncomeSource: String, Codable, CaseIterable, Identifiable {
    case mainJob
    case sideJob

    var id: String { rawValue }

    var label: String {
        switch self {
        case .mainJob: return "本業"
        case .sideJob: return "副業"
        }
    }
}

enum EntryType: String, Codable, CaseIterable, Identifiable {
    case income
    case expense

    var id: String { rawValue }

    var label: String {
        switch self {
        case .income: return "収入"
        case .expense: return "支出"
        }
    }

    var sign: Int { self == .income ? 1 : -1 }
}

struct Entry: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var source: IncomeSource
    var type: EntryType
    var amount: Int
    var memo: String

    init(id: UUID = UUID(), date: Date = Date(), source: IncomeSource, type: EntryType, amount: Int, memo: String) {
        self.id = id
        self.date = date
        self.source = source
        self.type = type
        self.amount = amount
        self.memo = memo
    }

    var signedAmount: Int { amount * type.sign }
}

final class FinanceStore: ObservableObject {
    @Published var entries: [Entry] = []

    private let defaultsKey = "financeTracker.entries"
    private let calendar = Calendar.current

    init() {
        load()
        if entries.isEmpty {
            entries = [
                Entry(date: Date(), source: .mainJob, type: .income, amount: 280000, memo: "給与"),
                Entry(date: Date(), source: .sideJob, type: .income, amount: 980, memo: "note記事"),
                Entry(date: Date(), source: .sideJob, type: .expense, amount: 1500, memo: "LINE公式 月額")
            ]
            save()
        }
    }

    func addEntry(source: IncomeSource, type: EntryType, amount: Int, memo: String, date: Date = Date()) {
        guard amount > 0 else { return }
        entries.append(Entry(date: date, source: source, type: type, amount: amount, memo: memo))
        save()
    }

    func delete(_ entry: Entry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    func entriesThisMonth(for source: IncomeSource) -> [Entry] {
        entries
            .filter { $0.source == source && isThisMonth($0.date) }
            .sorted { $0.date > $1.date }
    }

    func totalThisMonth(for source: IncomeSource) -> Int {
        entriesThisMonth(for: source).reduce(0) { $0 + $1.signedAmount }
    }

    private func isThisMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: Date(), toGranularity: .month)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([Entry].self, from: data) else { return }
        entries = decoded
    }
}
