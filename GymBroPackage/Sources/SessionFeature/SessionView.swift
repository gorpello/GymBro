import ComposableArchitecture
import DesignSystem
import L10n
import SwiftUI

public struct SessionView: View {
    @Bindable var store: StoreOf<Session>
    
    public init(store: StoreOf<Session>) {
        self.store = store
    }
    
    public var body: some View {
        Group {
            if store.isFinished {
                SessionSummaryView(store: store)
            } else {
                live
            }
        }
        .gymBackground()
        .overlay {
            if store.isLocked {
                LockOverlay { store.send(.unlockCompleted) }
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: store.isLocked)
        .sheet(isPresented: $store.showsOverview) {
            overview
        }
    }
    
    private var live: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                topBar
                progress
                if let exercise = store.current {
                    Text(exercise.name)
                        .font(.gym(28, .extraBold, relativeTo: .largeTitle))
                        .foregroundStyle(GymColor.text)
                        .padding(.top, 4)
                    Pill(L10n.muscle(exercise.muscle))
                    VStack(alignment: .leading, spacing: 4) {
                        if let last = exercise.last {
                            HStack(spacing: 8) {
                                Text(L10n.last).foregroundStyle(GymColor.textSecondary)
                                Text(last).foregroundStyle(GymColor.textSecondary)
                            }
                        }
                        if let next = exercise.next {
                            HStack(spacing: 8) {
                                Text(L10n.nextTime).foregroundStyle(GymColor.accent)
                                Text(next).foregroundStyle(GymColor.text)
                                Text("· \(L10n.nextHold)").foregroundStyle(GymColor.textTertiary)
                            }
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        }
                    }
                    .font(.gym(13, .semibold))
                    ExerciseArtView(art: exercise.art, color: GymColor.text, live: !store.isPaused)
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .softCard(padding: 0, radius: 26, fill: GymColor.bgRaised2)
                    restPanel
                    setTable(exercise)
                    actions
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }
    
    private var topBar: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(store.isPaused ? GymColor.warn : GymColor.text)
                .frame(width: 8, height: 8)
            Text(store.isPaused ? L10n.paused : L10n.inProgress)
                .font(.gym(14, .extraBold))
                .foregroundStyle(GymColor.text)
            Spacer()
            Text(store.elapsed)
                .font(.gym(22, .extraBold))
                .monospacedDigit()
                .foregroundStyle(GymColor.text)
            RoundButton(.fingerprint, label: L10n.lockWorkout, size: 44) { store.send(.lockButtonTapped) }
            RoundButton(store.isPaused ? .play : .pause, label: store.isPaused ? L10n.resumeWorkout : L10n.pauseWorkout, size: 44) {
                store.send(.pauseButtonTapped)
            }
        }
        .padding(.top, 8)
    }
    
    private var progress: some View {
        VStack(spacing: 10) {
            HStack {
                Text("\(L10n.exercises) \(store.currentIndex + 1) / \(store.exercises.count)")
                    .font(.gym(13, .semibold))
                    .tracking(0.6)
                    .foregroundStyle(GymColor.textSecondary)
                Spacer()
                Button {
                    store.send(.overviewButtonTapped)
                } label: {
                    HStack(spacing: 6) {
                        GymIcon(.listBullets, size: 14)
                        Text(L10n.allExercisesShort)
                    }
                    .font(.gym(13, .semibold))
                    .foregroundStyle(GymColor.textSecondary)
                }
            }
            HStack(spacing: 4) {
                ForEach(store.exercises.indices, id: \.self) { index in
                    Capsule()
                        .fill(index <= store.currentIndex ? GymColor.text : GymColor.bgRaised2)
                        .frame(height: 4)
                }
            }
        }
    }
    
    private var restPanel: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom) {
                Button("–15") { store.send(.restAdjustButtonTapped(seconds: -15)) }
                    .buttonStyle(.ghost)
                Spacer()
                Text(store.restRemaining == nil ? L10n.setDone : L10n.liveResting)
                    .font(.gym(12, .extraBold))
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(GymColor.text)
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .background(GymColor.bgRaised2, in: UnevenRoundedRectangle(topLeadingRadius: 18, topTrailingRadius: 18))
                Spacer()
                Button("+15") { store.send(.restAdjustButtonTapped(seconds: 15)) }
                    .buttonStyle(.ghost)
            }
            Button {
                store.send(.skipRestButtonTapped)
            } label: {
                VStack(spacing: 14) {
                    RestTicks(progress: store.restProgress)
                        .frame(height: 30)
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.elapsed).font(.gym(22, .extraBold)).foregroundStyle(GymColor.text)
                            Text(L10n.elapsedCaps).font(.gym(11, .bold)).tracking(1.2).foregroundStyle(GymColor.textSecondary)
                        }
                        Spacer()
                        VStack(spacing: 0) {
                            Text(store.restRemaining ?? "–")
                                .font(.gym(44, .extraBold))
                                .monospacedDigit()
                                .foregroundStyle(GymColor.text)
                            Text(L10n.tapToSkip.uppercased())
                                .font(.gym(12, .extraBold))
                                .tracking(1.2)
                                .foregroundStyle(GymColor.sage)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(store.setsDone)/\(store.setsTotal)").font(.gym(22, .extraBold)).foregroundStyle(GymColor.text)
                            Text(L10n.setsCaps).font(.gym(11, .bold)).tracking(1.2).foregroundStyle(GymColor.textSecondary)
                        }
                    }
                }
                .padding(22)
                .background(GymColor.bgRaised2, in: .rect(cornerRadius: 26))
                .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(GymColor.border))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.tapToSkip)
        }
    }
    
    private func setTable(_ exercise: SessionExercise) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(L10n.setCol).frame(width: 28)
                Spacer()
                Text(L10n.repsCol).frame(width: 110)
                Spacer()
                Text(L10n.weightCol(store.unit.uppercased())).frame(width: 130)
                Spacer()
                Color.clear.frame(width: 36, height: 1)
            }
            .font(.gym(12, .semibold))
            .foregroundStyle(GymColor.textSecondary)
            .padding(.horizontal, 10)
            .padding(.top, 12)
            ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                SetRowView(index: index + 1, set: set) { action in
                    switch action {
                    case let .reps(delta): store.send(.repsChanged(setID: set.id, delta: delta))
                    case let .weight(delta): store.send(.weightChanged(setID: set.id, delta: delta))
                    case .done: store.send(.setDoneButtonTapped(setID: set.id))
                    }
                }
            }
        }
        .padding(10)
        .background(GymColor.bgRaised, in: .rect(cornerRadius: 26))
    }
    
    private var actions: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Button(L10n.addSet.titleCased) { store.send(.addSetButtonTapped) }
                    .buttonStyle(.ghost)
                Button(L10n.addWarmup.titleCased) { store.send(.addWarmupButtonTapped) }
                    .buttonStyle(.ghost)
                Spacer()
            }
            if store.currentIndex < store.exercises.count - 1 {
                Button(L10n.nextExercise.titleCased) { store.send(.nextExerciseButtonTapped) }
                    .buttonStyle(.primary)
            }
            Button(L10n.finishSession.titleCased) { store.send(.finishButtonTapped) }
                .buttonStyle(.primary(fill: GymColor.bgRaised2, foreground: GymColor.text))
        }
        .padding(.top, 4)
    }
    
    private var overview: some View {
        NavigationStack {
            List {
                ForEach(Array(store.exercises.enumerated()), id: \.element.id) { index, exercise in
                    Button {
                        store.send(.exerciseSelected(index: index))
                    } label: {
                        HStack(spacing: 14) {
                            ExerciseArtView(art: exercise.art)
                                .frame(width: 48, height: 48)
                                .background(GymColor.bgRaised2, in: .rect(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.name).font(.gym(15, .bold)).foregroundStyle(GymColor.text)
                                Text(L10n.setsDoneOf(done: exercise.sets.filter(\.done).count, total: exercise.sets.count))
                                    .font(.gym(12.5, .medium))
                                    .foregroundStyle(GymColor.textSecondary)
                            }
                            Spacer()
                            if index == store.currentIndex {
                                Text(L10n.nowLabel).font(.gym(12, .bold)).foregroundStyle(GymColor.accent)
                            }
                        }
                    }
                    .listRowBackground(GymColor.bgRaised)
                }
                Button(L10n.addExercise.titleCased) { store.send(.addExerciseButtonTapped) }
                    .font(.gym(15, .bold))
                    .listRowBackground(GymColor.bgRaised)
            }
            .scrollContentBackground(.hidden)
            .gymBackground()
            .navigationTitle(L10n.workoutOverview)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }
}

/// One set: number, reps stepper, weight stepper and the done check (sage when done).
struct SetRowView: View {
    enum Change { case reps(Int), weight(Double), done }
    
    let index: Int
    let set: SessionSet
    let onChange: (Change) -> Void
    
    var body: some View {
        HStack {
            Text(set.kind == .warmup ? "W" : "\(index)")
                .font(.gym(17, .extraBold))
                .foregroundStyle(set.kind == .warmup ? GymColor.warn : GymColor.text)
                .frame(width: 28)
            Spacer()
            StepperControl("\(set.reps)", fontSize: 17, minWidth: 34) {
                onChange(.reps(-1))
            } onIncrement: {
                onChange(.reps(1))
            }
            Spacer()
            StepperControl(set.weight.formatted(.number.precision(.fractionLength(0...1))), fontSize: 17, minWidth: 44) {
                onChange(.weight(-2.5))
            } onIncrement: {
                onChange(.weight(2.5))
            }
            Spacer()
            Button {
                onChange(.done)
            } label: {
                ZStack {
                    Circle().strokeBorder(set.done ? GymColor.sage : GymColor.textTertiary, lineWidth: 2)
                    if set.done {
                        Circle().fill(GymColor.sage)
                        GymIcon(.check, weight: .bold, size: 15).foregroundStyle(.white)
                    }
                }
                .frame(width: 36, height: 36)
            }
            .buttonStyle(.pressable(scale: 0.88))
            .accessibilityLabel(L10n.markSet(index))
            .accessibilityAddTraits(set.done ? .isSelected : [])
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 18)
        .background(set.done ? GymColor.sageSoft : .clear, in: .rect(cornerRadius: 18))
        .sensoryFeedback(.success, trigger: set.done) { _, new in new }
    }
}

/// Bar of vertical ticks that empties as rest runs down.
struct RestTicks: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { proxy in
            let count = max(1, Int(proxy.size.width / 9))
            HStack(spacing: 0) {
                ForEach(0..<count, id: \.self) { i in
                    Capsule()
                        .fill(Double(i) / Double(count) < progress ? GymColor.sage : GymColor.bgRaised)
                        .frame(width: 3)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

/// Covers the session so pocket taps do nothing. Press and hold the fingerprint to unlock.
struct LockOverlay: View {
    let onUnlock: () -> Void
    
    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
            VStack(spacing: 18) {
                Text(L10n.screenLocked)
                    .font(.gym(22, .extraBold))
                    .foregroundStyle(GymColor.text)
                Text(L10n.lockedHint)
                    .font(.gym(14, .medium))
                    .foregroundStyle(GymColor.textSecondary)
                    .multilineTextAlignment(.center)
                GymIcon(.fingerprint, size: 40)
                    .foregroundStyle(GymColor.text)
                    .frame(width: 96, height: 96)
                    .background(GymColor.bgRaised, in: .circle)
                    .onLongPressGesture(minimumDuration: 0.8, perform: onUnlock)
                    .accessibilityLabel(L10n.holdToUnlock)
                    .accessibilityAction(named: L10n.unlockWorkout, onUnlock)
            }
            .padding(32)
        }
    }
}

/// "Workout logged" summary with duration, volume, records and what to do next.
struct SessionSummaryView: View {
    let store: StoreOf<Session>
    
    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Kicker(L10n.sessionComplete, color: GymColor.sage, size: 13)
                    .padding(.top, 40)
                if let summary = store.summary {
                    HStack(spacing: 12) {
                        StatBlock(L10n.duration, value: summary.duration)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .softCard(padding: 18, radius: 22)
                        StatBlock(L10n.volume, value: summary.volume, unit: summary.volumeUnit)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .softCard(padding: 18, radius: 22)
                    }
                    if summary.prCount > 0 {
                        HStack {
                            GymIcon(.trophy, weight: .fill, size: 20).foregroundStyle(GymColor.brass)
                            Text(L10n.prCount(summary.prCount)).font(.gym(16, .bold)).foregroundStyle(GymColor.text)
                            Spacer()
                        }
                        .softCard(padding: 18, radius: 22)
                    }
                    if let vs = summary.vsLastTime {
                        VStack(alignment: .leading, spacing: 6) {
                            Kicker(L10n.vsLastTime, size: 11, spacing: 1.5)
                            Text(vs).font(.gym(15, .semibold)).foregroundStyle(GymColor.text)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .softCard(padding: 18, radius: 22)
                    }
                }
                VStack(spacing: 10) {
                    Button(L10n.share.titleCased) { store.send(.shareButtonTapped) }
                        .buttonStyle(.primary)
                    Button(L10n.stickerOpen) { store.send(.stickerButtonTapped) }
                        .buttonStyle(.primary(fill: GymColor.bgRaised2, foreground: GymColor.text))
                    Button(L10n.saveAsRoutine.titleCased) { store.send(.saveAsRoutineButtonTapped) }
                        .buttonStyle(.primary(fill: GymColor.bgRaised2, foreground: GymColor.text))
                    Button(L10n.done.titleCased) { store.send(.doneButtonTapped) }
                        .buttonStyle(.ghost)
                }
            }
            .padding(20)
        }
    }
}

#Preview {
    SessionView(store: Store(initialState: Session.State()) { Session() })
}
