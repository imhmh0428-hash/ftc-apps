import SwiftUI

private extension Color {
    static let ftcGreen = Color(red: 0.055, green: 0.561, blue: 0.431)      // #0E8F6E
    static let ftcAmber = Color(red: 1.0, green: 0.757, blue: 0.271)       // #FFC145
    static let ftcBg = Color(red: 0.063, green: 0.086, blue: 0.075)        // near-black green
    static let ftcCard = Color(red: 0.094, green: 0.129, blue: 0.113)      // slightly lighter card
}

struct ContentView: View {
    @StateObject private var store = HabitStore()
    @State private var isAddingHabit = false
    @State private var newHabitName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ftcBg.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 4) {
                    Text("HABIT TRACKER")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(2)
                    Text("つづく、を可視化する")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.bottom, 12)

                    if store.habits.isEmpty {
                        Spacer()
                        Text("右上の + から、続けたい習慣を追加しましょう")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .center)
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(store.habits) { habit in
                                    HabitRow(habit: habit, store: store)
                                }
                                .onDelete(perform: store.delete)
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
                        isAddingHabit = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.ftcGreen)
                    }
                }
            }
            .toolbarBackground(Color.ftcBg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("新しい習慣", isPresented: $isAddingHabit) {
                TextField("例: 朝のストレッチ", text: $newHabitName)
                Button("追加") {
                    store.addHabit(named: newHabitName)
                    newHabitName = ""
                }
                Button("キャンセル", role: .cancel) {
                    newHabitName = ""
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct HabitRow: View {
    let habit: Habit
    @ObservedObject var store: HabitStore

    var body: some View {
        let done = store.isCompletedToday(habit)
        let streak = store.streak(for: habit)
        let week = store.last7Days(for: habit)

        HStack(spacing: 14) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    store.toggleToday(habit)
                }
            } label: {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 28))
                    .foregroundColor(done ? Color.ftcGreen : .white.opacity(0.25))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(habit.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)

                HStack(spacing: 6) {
                    ForEach(0..<week.count, id: \.self) { index in
                        Circle()
                            .fill(week[index] ? Color.ftcGreen : Color.white.opacity(0.12))
                            .frame(width: 10, height: 10)
                    }
                }
            }

            Spacer()

            if streak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.ftcAmber)
                    Text("\(streak)")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.ftcAmber)
                }
            }
        }
        .padding(16)
        .background(Color.ftcCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    ContentView()
}
