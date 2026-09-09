import SwiftUI

struct SpeedControlView: View {
    let speed: GameSpeed
    let onSelect: (GameSpeed) -> Void

    var body: some View {
        HStack(spacing: 2) {
            ForEach(GameSpeed.allCases) { option in
                Button {
                    onSelect(option)
                } label: {
                    Text(option.label)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .frame(width: 28, height: 32)
                        .foregroundStyle(option == speed ? Color.black : Theme.textPrimary)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(option == speed ? Theme.accent : Color.white.opacity(0.10))
                        )
                }
            }
        }
    }
}
