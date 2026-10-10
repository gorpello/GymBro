import ComposableArchitecture
import Database
import DesignSystem
import L10n
import SwiftUI

public struct AwardsView: View {
    let store: StoreOf<Awards>

    public init(store: StoreOf<Awards>) {
        self.store = store
    }

    public var body: some View {
        let board = store.board
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !board.earned.isEmpty {
                    grid(L10n.awardsEarned, medals: board.earned)
                }
                if !board.locked.isEmpty {
                    grid(L10n.awardsLocked, medals: board.locked)
                }
            }
            .padding(20)
        }
        .gymScreen(L10n.awardsTitle, subtitle: "\(board.earned.count)/\(board.medals.count)")
        .task { await store.send(.task).finish() }
    }

    private func grid(_ title: String, medals: [AwardsBoard.Medal]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Kicker(title, size: 11, spacing: 2)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 18) {
                ForEach(medals) { medal in
                    Button {
                        store.send(.medalTapped(medal.kind))
                    } label: {
                        MedalCell(medal: medal)
                    }
                    .buttonStyle(.pressable)
                }
            }
        }
    }
}

/// A medal with its name, and either the day it was earned or what's left to do.
private struct MedalCell: View {
    let medal: AwardsBoard.Medal

    var body: some View {
        let isLocked = medal.earnedAt == nil
        VStack(spacing: 8) {
            MedalImage(medal.kind.rawValue, locked: isLocked)
                .frame(width: 84, height: 84)
            Text(medal.kind.name)
                .font(.gym(12.5, .bold))
                .foregroundStyle(isLocked ? GymColor.textTertiary : GymColor.text)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            if let earnedAt = medal.earnedAt {
                Text(earnedAt.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.gym(11, .medium))
                    .foregroundStyle(GymColor.textSecondary)
            } else {
                Text(medal.kind.line)
                    .font(.gym(11, .medium))
                    .foregroundStyle(GymColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                ProgressView(value: Double(medal.progress), total: Double(medal.kind.goal))
                    .tint(GymColor.accent)
                    .padding(.horizontal, 12)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(
            isLocked
                ? L10n.awardProgressLabel(
                    value: medal.progress.formatted(),
                    goal: medal.kind.goal.formatted()
                )
                : ""
        )
    }
}

#Preview {
    NavigationStack {
        AwardsView(store: previewStore())
    }
}

/// A store backed by a database seeded with a month of training.
@MainActor
private func previewStore() -> StoreOf<Awards> {
    prepareDependencies {
        // swiftlint:disable:next force_try
        try! $0.bootstrapDatabase()
        // swiftlint:disable:next force_try
        try! $0.seedDatabaseForPreviews()
    }
    return Store(initialState: Awards.State()) { Awards() }
}
