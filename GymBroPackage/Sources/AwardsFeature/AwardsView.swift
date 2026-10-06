import ComposableArchitecture
import DesignSystem
import L10n
import SwiftUI

public struct AwardsView: View {
    let store: StoreOf<Awards>

    public init(store: StoreOf<Awards>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                grid(L10n.awardsEarned, rows: store.earned, locked: false)
                grid(L10n.awardsLocked, rows: store.locked, locked: true)
            }
            .padding(20)
        }
        .gymScreen(L10n.awardsTitle, subtitle: "\(store.earned.count)/\(store.earned.count + store.locked.count)")
    }

    private func grid(_ title: String, rows: [AwardRow], locked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Kicker(title, size: 11, spacing: 2)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 18) {
                ForEach(rows) { row in
                    Button {
                        store.send(.medalTapped(id: row.id))
                    } label: {
                        VStack(spacing: 8) {
                            MedalImage(row.id, locked: locked)
                                .frame(width: 84, height: 84)
                            Text(row.name)
                                .font(.gym(12.5, .bold))
                                .foregroundStyle(locked ? GymColor.textTertiary : GymColor.text)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            Text(row.date ?? row.line)
                                .font(.gym(11, .medium))
                                .foregroundStyle(GymColor.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                    .buttonStyle(.pressable)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AwardsView(store: Store(initialState: Awards.State()) { Awards() })
    }
}
