import SwiftUI

private extension Color {
    static let ftcGreen = Color(red: 0.055, green: 0.561, blue: 0.431)      // #0E8F6E
    static let ftcAmber = Color(red: 1.0, green: 0.757, blue: 0.271)       // #FFC145
    static let ftcBg = Color(red: 0.063, green: 0.086, blue: 0.075)
    static let ftcCard = Color(red: 0.094, green: 0.129, blue: 0.113)
}

private func yen(_ value: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.groupingSeparator = ","
    let sign = value < 0 ? "-" : ""
    let formatted = formatter.string(from: NSNumber(value: abs(value))) ?? "\(abs(value))"
    return "\(sign)¥\(formatted)"
}

struct ContentView: View {
    @StateObject private var store = FinanceStore()
    @State private var isAddingEntry = false

    private var allEntriesThisMonthSorted: [Entry] {
        (store.entriesThisMonth(for: .mainJob) + store.entriesThisMonth(for: .sideJob))
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ftcBg.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FINANCE TRACKER")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(2)
                        Text("本業と副業、分けて見える")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    HStack(spacing: 12) {
                        SummaryCard(title: "本業", amount: store.totalThisMonth(for: .mainJob), accent: .ftcGreen)
                        SummaryCard(title: "副業", amount: store.totalThisMonth(for: .sideJob), accent: .ftcAmber)
                    }

                    Text("今月の記録")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))

                    if allEntriesThisMonthSorted.isEmpty {
                        Spacer()
                        Text("右上の + から、収入・支出を記録しましょう")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .center)
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 10) {
                                ForEach(allEntriesThisMonthSorted) { entry in
                                    EntryRow(entry: entry, store: store)
                                }
                            }
                            .padding(.bottom, 24)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAddingEntry = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.ftcGreen)
                    }
                }
            }
            .toolbarBackground(Color.ftcBg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $isAddingEntry) {
                AddEntryView(store: store)
                    .presentationDetents([.medium])
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct SummaryCard: View {
    let title: String
    let amount: Int
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            Text(yen(amount))
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(amount < 0 ? .red.opacity(0.85) : .white)
            Capsule()
                .fill(accent)
                .frame(width: 28, height: 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ftcCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct EntryRow: View {
    let entry: Entry
    @ObservedObject var store: FinanceStore

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: entry.date)
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(entry.source.label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(entry.source == .mainJob ? .ftcGreen : .ftcAmber)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((entry.source == .mainJob ? Color.ftcGreen : Color.ftcAmber).opacity(0.15))
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.memo.isEmpty ? entry.type.label : entry.memo)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                Text(dateLabel)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()

            Text(yen(entry.signedAmount))
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundColor(entry.type == .income ? .white : .red.opacity(0.85))
        }
        .padding(14)
        .background(Color.ftcCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .swipeActions {
            Button(role: .destructive) {
                store.delete(entry)
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }
}

private struct AddEntryView: View {
    @ObservedObject var store: FinanceStore
    @Environment(\.dismiss) private var dismiss

    @State private var source: IncomeSource = .sideJob
    @State private var type: EntryType = .income
    @State private var amountText: String = ""
    @State private var memo: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Picker("区分", selection: $source) {
                    ForEach(IncomeSource.allCases) { item in
                        Text(item.label).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                Picker("種類", selection: $type) {
                    ForEach(EntryType.allCases) { item in
                        Text(item.label).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                TextField("金額（円）", text: $amountText)
                    .keyboardType(.numberPad)

                TextField("メモ（任意）", text: $memo)
            }
            .navigationTitle("記録を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if let amount = Int(amountText) {
                            store.addEntry(source: source, type: type, amount: amount, memo: memo)
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
