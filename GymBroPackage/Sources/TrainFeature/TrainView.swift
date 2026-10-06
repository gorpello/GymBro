import ComposableArchitecture
import DesignSystem
import L10n
import SwiftUI

public struct TrainView: View {
    @Bindable var store: StoreOf<Train>

    public init(store: StoreOf<Train>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            Group {
                switch store.step {
                case .focus: focus
                case .build: build
                }
            }
            .gymBackground()
            .navigationTitle(L10n.train.titleCased)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if store.step == .build {
                        Button {
                            store.send(.backButtonTapped)
                        } label: {
                            GymIcon(.caretLeft, weight: .bold, size: 16)
                        }
                        .accessibilityLabel("Back")
                    } else {
                        Button(role: .close) { store.send(.closeButtonTapped) }
                    }
                }
            }
        }
    }

    private var focus: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Kicker(L10n.step1, size: 12)
                Text(L10n.chooseFocus)
                    .font(.gym(30, .extraBold, relativeTo: .largeTitle))
                    .foregroundStyle(GymColor.text)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                BodyMapView(selected: store.selectedMuscles) { store.send(.muscleTapped($0)) }
                    .padding(16)
                    .background(GymColor.bgRaised, in: .rect(cornerRadius: 28))
                Text(store.selectedMuscles.isEmpty ? L10n.noMusclesYet : L10n.tapMuscles)
                    .font(.gym(13.5, .medium))
                    .foregroundStyle(GymColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                FlowLayout {
                    ForEach(store.selectedMuscles.sorted(), id: \.self) { id in
                        Pill(L10n.muscle(id), removable: true) { store.send(.muscleTapped(id)) }
                    }
                }
                Button(L10n.continueBtn.titleCased) { store.send(.continueButtonTapped) }
                    .buttonStyle(.primary)
                    .disabled(store.selectedMuscles.isEmpty)
                    .opacity(store.selectedMuscles.isEmpty ? 0.5 : 1)
                Kicker(L10n.orStartWith, size: 11, spacing: 2)
                    .padding(.top, 8)
                HStack(spacing: 12) {
                    focusOption(L10n.warmupFocus, hint: L10n.warmupFocusHint, icon: .personSimpleTaiChi) {
                        store.send(.warmupButtonTapped)
                    }
                    focusOption(L10n.cardioFocus, hint: L10n.cardioFocusHint, icon: .personSimpleRun) {
                        store.send(.cardioButtonTapped)
                    }
                }
            }
            .padding(20)
        }
    }

    private func focusOption(_ title: String, hint: String, icon: Ph, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                GymIcon(icon, size: 22)
                    .foregroundStyle(GymColor.accent)
                Text(title)
                    .font(.gym(15, .bold))
                    .foregroundStyle(GymColor.text)
                Text(hint)
                    .font(.gym(12, .medium))
                    .foregroundStyle(GymColor.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .softCard(padding: 16, radius: 22)
        }
        .buttonStyle(.pressable)
    }

    private var build: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Kicker(L10n.step2, size: 12)
                Text(L10n.buildSession)
                    .font(.gym(30, .extraBold, relativeTo: .largeTitle))
                    .foregroundStyle(GymColor.text)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        Pill(L10n.allExercisesShort, selected: store.muscleFilter == nil) { store.muscleFilter = nil }
                        ForEach(store.selectedMuscles.sorted(), id: \.self) { id in
                            Pill(L10n.muscle(id), selected: store.muscleFilter == id) { store.muscleFilter = id }
                        }
                        Rectangle().fill(GymColor.border).frame(width: 1, height: 24)
                        ForEach(store.equipmentOptions, id: \.self) { id in
                            Pill(L10n.equipment(id), selected: store.equipmentFilter == id) {
                                store.equipmentFilter = store.equipmentFilter == id ? nil : id
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                Text(L10n.pickedHint(store.suggestions.count))
                    .font(.gym(13, .medium))
                    .foregroundStyle(GymColor.textSecondary)
                list(L10n.suggestedPicks, rows: store.suggestions)
                list(L10n.moreOptions, rows: store.moreOptions)
                SearchField(L10n.searchAllExercises, text: $store.searchText)
            }
            .padding(20)
        }
        .safeAreaInset(edge: .bottom) {
            Button(L10n.startCount(store.picked.count).titleCased) { store.send(.startButtonTapped) }
                .buttonStyle(.primary)
                .disabled(store.picked.isEmpty)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
    }

    @ViewBuilder
    private func list(_ title: String, rows: [TrainExercise]) -> some View {
        if !rows.isEmpty {
            Kicker(title, size: 11, spacing: 2)
                .padding(.top, 6)
            VStack(spacing: 0) {
                ForEach(rows) { row in
                    let isPicked = store.picked.contains(row.id)
                    Button {
                        store.send(.exerciseTapped(id: row.id))
                    } label: {
                        HStack(spacing: 14) {
                            ExerciseArtView(art: row.art)
                                .frame(width: 54, height: 54)
                                .background(GymColor.bgRaised2, in: .rect(cornerRadius: 14))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.name)
                                    .font(.gym(15, .bold))
                                    .foregroundStyle(GymColor.text)
                                Text(row.detail)
                                    .font(.gym(12.5, .medium))
                                    .foregroundStyle(GymColor.textSecondary)
                            }
                            Spacer()
                            ZStack {
                                Circle().strokeBorder(isPicked ? GymColor.sage : GymColor.border, lineWidth: 2)
                                if isPicked {
                                    Circle().fill(GymColor.sage)
                                    GymIcon(.check, weight: .bold, size: 13).foregroundStyle(GymColor.onEmber)
                                }
                            }
                            .frame(width: 28, height: 28)
                        }
                        .padding(12)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isPicked ? .isSelected : [])
                }
            }
            .background(GymColor.bgRaised, in: .rect(cornerRadius: 22))
        }
    }
}

#Preview {
    TrainView(store: Store(initialState: Train.State()) { Train() })
}
