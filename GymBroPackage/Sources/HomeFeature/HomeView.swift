import ComposableArchitecture
import DesignSystem
import L10n
import SwiftUI

public struct HomeView: View {
    let store: StoreOf<Home>

    public init(store: StoreOf<Home>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                todayCard
                WeekStrip(initials: L10n.weekdayInitials, done: store.weekDone, today: store.todayWeekdayIndex)
                    .softCard(padding: 16, radius: 24)
                recommended
                SectionHeader(L10n.thisWeekTitle)
                    .padding(.top, 12)
                thisWeek
                Button {
                    store.send(.activityButtonTapped)
                } label: {
                    SectionHeader(L10n.activityLabel) {
                        GymIcon(.caretRight, weight: .bold, size: 14)
                            .foregroundStyle(GymColor.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 12)
                HeatGrid(weeks: store.activity)
                    .softCard(padding: 20, radius: 24)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .gymBackground()
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Kicker(L10n.today)
                Text(store.dateTitle)
                    .font(.gym(26, .extraBold, relativeTo: .largeTitle))
                    .foregroundStyle(GymColor.text)
            }
            Spacer()
            HStack(spacing: 6) {
                GymIcon(.flame, weight: .fill, size: 14)
                    .foregroundStyle(GymColor.accent)
                Text("\(store.streak)")
                    .font(.gym(15, .extraBold))
                    .foregroundStyle(GymColor.text)
            }
            .padding(.horizontal, 14)
            .frame(height: 40)
            .background(GymColor.bgRaised, in: .capsule)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(L10n.streakDays(store.streak))
        }
        .padding(.top, 8)
    }

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Kicker(L10n.todaysRoutine, size: 11)
            if let name = store.todayRoutineName {
                Text(name)
                    .font(.gym(34, .extraBold, relativeTo: .largeTitle))
                    .foregroundStyle(GymColor.text)
                    .padding(.top, 10)
                Text(L10n.exerciseCount(store.todayExerciseCount))
                    .font(.gym(15, .medium))
                    .foregroundStyle(GymColor.textSecondary)
                    .padding(.top, 4)
            } else {
                Text(L10n.firstSessionHint)
                    .font(.gym(20, .extraBold, relativeTo: .title2))
                    .foregroundStyle(GymColor.text)
                    .padding(.top, 10)
                    .padding(.trailing, 90)
            }
            Button {
                store.send(.startWorkoutButtonTapped)
            } label: {
                Label {
                    Text(L10n.startWorkout.titleCased)
                } icon: {
                    GymIcon(.play, weight: .fill, size: 14)
                }
            }
            .buttonStyle(.primary)
            .padding(.top, 28)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(28)
        .background {
            ZStack(alignment: .topTrailing) {
                GymColor.bgRaised
                Circle()
                    .fill(GymColor.accentSoft)
                    .frame(width: 220, height: 220)
                    .offset(x: -170, y: 40)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                Circle()
                    .fill(GymColor.bgRaised2.opacity(0.8))
                    .frame(width: 150, height: 150)
                    .offset(x: -40, y: -60)
                GymImage.runner
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .padding(.trailing, 16)
                    .padding(.top, 8)
                    .opacity(0.8)
                    .accessibilityHidden(true)
            }
        }
        .clipShape(.rect(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(GymColor.border, lineWidth: 1))
    }

    private var recommended: some View {
        VStack(alignment: .leading, spacing: 12) {
            Kicker(L10n.recommended, size: 11)
            HStack(spacing: 12) {
                folder(L10n.routines, detail: L10n.routineCount(store.routineCount), icon: .folders, hue: 0) {
                    store.send(.routinesButtonTapped)
                }
                folder(L10n.tools, detail: L10n.calculatorsInside, icon: .calculator, hue: 4) {
                    store.send(.toolsButtonTapped)
                }
                folder(L10n.journal, detail: L10n.noteCount(store.noteCount), icon: .notebook, hue: 2) {
                    store.send(.journalButtonTapped)
                }
            }
        }
        .padding(.top, 8)
    }

    private func folder(_ title: String, detail: String, icon: Ph, hue: Int, action: @escaping () -> Void) -> some View
    {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                GymIcon(icon, weight: .fill, size: 18)
                    .foregroundStyle(Color.black.opacity(0.65))
                    .frame(width: 36, height: 36)
                    .background(GymColor.folderHues[hue], in: .rect(cornerRadius: 10))
                Text(title.titleCased)
                    .font(.gym(14, .bold))
                    .foregroundStyle(GymColor.text)
                    .lineLimit(1)
                Text(detail)
                    .font(.gym(11.5, .medium, relativeTo: .caption))
                    .foregroundStyle(GymColor.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .softCard(padding: 14, radius: 20)
        }
        .buttonStyle(.pressable)
    }

    private var thisWeek: some View {
        HStack(alignment: .center) {
            StatBlock(L10n.volume, value: store.volume, unit: store.volumeUnit)
            Spacer()
            StatBlock(L10n.setsToday, value: "\(store.setsToday)")
            Spacer()
            StatBlock(L10n.prs, value: "\(store.prCount)")
            Spacer()
            GoalRing(done: store.weeklySessions, goal: store.weeklyGoal)
        }
        .softCard(padding: 24, radius: 24)
    }
}

#Preview {
    HomeView(store: Store(initialState: Home.State()) { Home() })
}
