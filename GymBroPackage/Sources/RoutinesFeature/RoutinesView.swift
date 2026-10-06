import ComposableArchitecture
import DesignSystem
import L10n
import SwiftUI

public struct RoutinesView: View {
    @Bindable var store: StoreOf<Routines>

    public init(store: StoreOf<Routines>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Kicker(L10n.weeklyPlan, size: 12, spacing: 2)
                weeklyPlan
                Kicker(L10n.yourRoutines, size: 12, spacing: 2)
                    .padding(.top, 10)
                if store.groups.isEmpty {
                    Text(L10n.noRoutines)
                        .font(.gym(14, .medium))
                        .foregroundStyle(GymColor.textSecondary)
                }
                ForEach(store.groups) { group in
                    if !group.id.isEmpty {
                        HStack(spacing: 8) {
                            GymIcon(.folder, size: 18).foregroundStyle(GymColor.accent)
                            Text(group.id).font(.gym(16, .extraBold)).foregroundStyle(GymColor.text)
                            Spacer()
                            Text("\(group.routines.count)").font(.gym(13, .semibold)).foregroundStyle(
                                GymColor.textTertiary)
                        }
                    }
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14
                    ) {
                        ForEach(group.routines) { routine in
                            RoutineFolderCard(routine: routine, group: group.id) {
                                store.send(.routineTapped(id: routine.id))
                            } onStart: {
                                store.send(.startButtonTapped(id: routine.id))
                            } onDuplicate: {
                                store.send(.duplicateButtonTapped(id: routine.id))
                            }
                        }
                    }
                }
                VStack(spacing: 10) {
                    Button(L10n.newRoutine.titleCased) { store.send(.newRoutineButtonTapped) }
                        .buttonStyle(.primary)
                    HStack(spacing: 10) {
                        Button(L10n.templates) { store.send(.templatesButtonTapped) }
                            .buttonStyle(.ghost)
                        Button(L10n.aiRoutine) { store.send(.aiRoutineButtonTapped) }
                            .buttonStyle(.ghost)
                    }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .gymScreen(L10n.routines)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    store.send(.importButtonTapped)
                } label: {
                    GymIcon(.downloadSimple, size: 18)
                }
                .accessibilityLabel(L10n.importRoutines)
                Button {
                    store.send(.shareButtonTapped)
                } label: {
                    GymIcon(.shareNetwork, size: 18)
                }
                .accessibilityLabel(L10n.shareWeek)
            }
        }
        .sheet(item: $store.scope(state: \.templates, action: \.templates)) { templatesStore in
            TemplatesView(store: templatesStore)
        }
    }

    private var weeklyPlan: some View {
        VStack(spacing: 0) {
            ForEach(Array(L10n.weekdayShortNames.enumerated()), id: \.offset) { index, day in
                let routine = index < store.weeklyPlan.count ? store.weeklyPlan[index] : nil
                Button {
                    store.send(.weekdayTapped(index))
                } label: {
                    HStack {
                        Text(day).font(.gym(16, .bold)).foregroundStyle(GymColor.text)
                        Spacer()
                        Text(routine ?? L10n.restDayShort)
                            .font(.gym(16, routine == nil ? .medium : .bold))
                            .foregroundStyle(routine == nil ? GymColor.textTertiary : GymColor.text)
                        GymIcon(.caretRight, weight: .bold, size: 12).foregroundStyle(GymColor.textTertiary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 15)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
        .background(GymColor.bgRaised, in: .rect(cornerRadius: 26))
    }
}

/// A routine drawn as a folder with coloured paper sticking out (`routine_folder.dart`).
struct RoutineFolderCard: View {
    let routine: RoutineCard
    let group: String
    let onOpen: () -> Void
    let onStart: () -> Void
    let onDuplicate: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private static let tab: CGFloat = 16

    var body: some View {
        let hue = GymColor.folderHues[routine.hue % GymColor.folderHues.count]
        let dark = colorScheme == .dark
        VStack(spacing: 0) {
            Button(action: onOpen) {
                ZStack(alignment: .top) {
                    // Folder back with its tab.
                    UnevenRoundedRectangle(topLeadingRadius: 14, topTrailingRadius: 14)
                        .fill(GymColor.bgRaised)
                        .frame(width: 74, height: Self.tab + 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    UnevenRoundedRectangle(bottomLeadingRadius: 22, bottomTrailingRadius: 22, topTrailingRadius: 20)
                        .fill(GymColor.bgRaised)
                        .padding(.top, Self.tab)
                    // Paper sheets.
                    RoundedRectangle(cornerRadius: 12)
                        .fill(GymColor.mix(hue, .black, dark ? 0.42 : 0.18))
                        .frame(height: 64)
                        .rotationEffect(.radians(-0.018))
                        .padding(.horizontal, 12)
                        .padding(.top, Self.tab + 8)
                    RoundedRectangle(cornerRadius: 12)
                        .fill(hue)
                        .frame(height: 64)
                        .overlay(alignment: .topLeading) {
                            VStack(alignment: .leading, spacing: 5) {
                                Capsule().fill(Color.black.opacity(0.25)).frame(height: 3)
                                Capsule().fill(Color.black.opacity(0.12)).frame(height: 3).padding(.trailing, 50)
                            }
                            .padding(EdgeInsets(top: 12, leading: 14, bottom: 0, trailing: 40))
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, Self.tab + 16)
                    // Front pocket with the name.
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .top) {
                            HStack(spacing: 4) {
                                Text(routine.name).font(.gym(18, .extraBold)).foregroundStyle(GymColor.text).lineLimit(
                                    1)
                                GymIcon(.caretRight, weight: .bold, size: 12).foregroundStyle(GymColor.textSecondary)
                            }
                            Spacer()
                            Menu {
                                Button(L10n.duplicateRoutine, action: onDuplicate)
                            } label: {
                                GymIcon(.dotsThreeVertical, weight: .bold, size: 16)
                                    .foregroundStyle(GymColor.text)
                                    .frame(width: 34, height: 34)
                                    .background(GymColor.bgRaised2.opacity(0.8), in: .circle)
                            }
                        }
                        Spacer()
                        Text(
                            [group, L10n.exerciseCount(routine.exerciseCount)].filter { !$0.isEmpty }.joined(
                                separator: " · ")
                        )
                        .font(.gym(12.5, .semibold))
                        .foregroundStyle(GymColor.textSecondary)
                        .lineLimit(1)
                    }
                    .padding(EdgeInsets(top: 12, leading: 14, bottom: 10, trailing: 8))
                    .frame(height: 100)
                    .background(GymColor.mix(GymColor.bgRaised2, hue, dark ? 0.14 : 0.3), in: .rect(cornerRadius: 18))
                    .shadow(color: .black.opacity(dark ? 0.35 : 0.1), radius: 7, y: -3)
                    .padding(.horizontal, 6)
                    .padding(.top, Self.tab + 50)
                }
                .frame(height: 150, alignment: .top)
            }
            .buttonStyle(.pressable(scale: 0.975))
            Button(action: onStart) {
                Label {
                    Text(L10n.startWorkout.titleCased)
                } icon: {
                    GymIcon(.play, weight: .fill, size: 12)
                }
                .font(.gym(15, .bold))
                .foregroundStyle(GymColor.textSecondary)
                .frame(maxWidth: .infinity, minHeight: 46)
            }
            .buttonStyle(.plain)
            .background(
                GymColor.bgRaised, in: UnevenRoundedRectangle(bottomLeadingRadius: 22, bottomTrailingRadius: 22))
        }
    }
}

struct TemplatesView: View {
    let store: StoreOf<Templates>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                SheetTitle(L10n.templates, subtitle: L10n.templatesHint)
                    .padding(.vertical, 8)
                ForEach(store.templates) { template in
                    Button {
                        store.send(.templateTapped(id: template.id))
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(template.name).font(.gym(17, .extraBold)).foregroundStyle(GymColor.text)
                                Spacer()
                                Text(L10n.dayCount(template.dayCount)).font(.gym(12.5, .semibold)).foregroundStyle(
                                    GymColor.textSecondary)
                            }
                            Text(template.blurb)
                                .font(.gym(13, .medium))
                                .foregroundStyle(GymColor.textSecondary)
                                .multilineTextAlignment(.leading)
                        }
                        .softCard(padding: 18, radius: 20)
                    }
                    .buttonStyle(.pressable)
                }
            }
            .padding(20)
        }
        .gymBackground()
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    NavigationStack {
        RoutinesView(store: Store(initialState: Routines.State()) { Routines() })
    }
}
