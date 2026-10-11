import SwiftUI

private extension Color {
    static let ftcGreen = Color(red: 0.055, green: 0.561, blue: 0.431)      // #0E8F6E
    static let ftcGreenDeep = Color(red: 0.035, green: 0.361, blue: 0.278) // #095C47
    static let ftcAmber = Color(red: 1.0, green: 0.757, blue: 0.271)       // #FFC145
    static let ftcBg = Color(red: 0.063, green: 0.086, blue: 0.075)       // near-black green
}

struct ContentView: View {
    @StateObject private var model = TimerModel()

    var body: some View {
        ZStack {
            Color.ftcBg.ignoresSafeArea()

            VStack(spacing: 28) {
                VStack(spacing: 6) {
                    Text("FOCUS TIMER")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(2)
                    Text("平日90分だけ、守る。")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.top, 40)

                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 14)

                    Circle()
                        .trim(from: 0, to: model.progress)
                        .stroke(
                            model.completedToday ? Color.ftcAmber : Color.ftcGreen,
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: model.progress)

                    VStack(spacing: 8) {
                        Text(model.formattedTime)
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        if model.completedToday {
                            Label("今日の90分、達成", systemImage: "checkmark.seal.fill")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.ftcAmber)
                        } else {
                            Text(model.isRunning ? "集中中…" : "準備OK")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .frame(width: 240, height: 240)
                .padding(.vertical, 10)

                HStack(spacing: 16) {
                    Button(action: model.reset) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 56, height: 56)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }

                    Button(action: model.isRunning ? model.pause : model.start) {
                        Image(systemName: model.isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.ftcBg)
                            .frame(width: 84, height: 84)
                            .background(Color.ftcGreen)
                            .clipShape(Circle())
                    }

                    Color.clear.frame(width: 56, height: 56)
                }

                HStack(spacing: 10) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.ftcAmber)
                        .font(.system(size: 14))
                    Text("連続 \(model.streakCount()) 日")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.75))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
