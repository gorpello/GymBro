import ComposableArchitecture
import DesignSystem
import L10n
import SwiftUI

public struct OnboardingView: View {
    @Bindable var store: StoreOf<Onboarding>
    
    public init(store: StoreOf<Onboarding>) {
        self.store = store
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                if store.step != .welcome {
                    RoundButton(.caretLeft, label: "Back") { store.send(.backButtonTapped) }
                    Spacer()
                    Kicker(L10n.onbStep(i: store.step.rawValue, n: Onboarding.Step.allCases.count - 1), size: 11)
                    Spacer()
                } else {
                    Spacer()
                }
                Button(L10n.skip2) { store.send(.skipButtonTapped) }
                    .font(.gym(14, .semibold))
                    .foregroundStyle(GymColor.textSecondary)
            }
            .frame(height: 44)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    content
                }
                .padding(.top, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
            Button((store.step == .welcome ? L10n.welcomeStart : L10n.next).titleCased) {
                store.send(.nextButtonTapped)
            }
            .buttonStyle(.primary)
        }
        .padding(20)
        .gymBackground()
        .animation(.snappy, value: store.step)
    }
    
    @ViewBuilder
    private var content: some View {
        switch store.step {
        case .welcome:
            Kicker(L10n.welcomeKicker, size: 12)
            Text("GymBro").font(.gym(44, .extraBold)).foregroundStyle(GymColor.text)
            Text(L10n.welcomeBlurb).font(.gym(15, .medium)).foregroundStyle(GymColor.textSecondary)
            GroupCard {
                OptionRow(L10n.freeForever, icon: .gift, detail: L10n.freeForeverWhy) { EmptyView() }
                OptionRow(L10n.fullyOffline, icon: .wifiSlash, detail: L10n.fullyOfflineWhy) { EmptyView() }
                OptionRow(L10n.yoursToTake, icon: .export, detail: L10n.yoursToTakeWhy) { EmptyView() }
            }
        case .name:
            title(L10n.onbNameTitle, L10n.onbNameWhy)
            TextField(L10n.onbNameHint, text: $store.name)
                .font(.gym(22, .bold))
                .padding(18)
                .background(GymColor.bgRaised, in: .rect(cornerRadius: 20))
        case .body:
            title(L10n.onbBodyTitle, L10n.onbBodyWhy)
            Kicker(L10n.sexLabel, size: 11, spacing: 2)
            SegToggle([("male", L10n.male), ("female", L10n.female)], selection: $store.sex, fontSize: 14)
            GroupCard {
                OptionRow(L10n.ageLabel) {
                    Stepper(value: $store.age, in: 12...99) { Text("\(store.age)").font(.gym(16, .bold)) }
                        .fixedSize()
                }
                OptionRow(L10n.heightLabel) {
                    Stepper(value: $store.heightCm, in: 100...230) { Text("\(Int(store.heightCm)) cm").font(.gym(16, .bold)) }
                        .fixedSize()
                }
                OptionRow(L10n.weightLabel) {
                    Stepper(value: $store.weightKg, in: 30...250, step: 0.5) {
                        Text("\(store.weightKg.formatted()) kg").font(.gym(16, .bold))
                    }
                    .fixedSize()
                }
            }
        case .goal:
            title(L10n.onbGoalTitle, L10n.onbGoalWhy)
            HStack(spacing: 8) {
                ForEach(1...7, id: \.self) { n in
                    Button("\(n)") { store.weeklyGoal = n }
                        .font(.gym(18, .extraBold))
                        .foregroundStyle(store.weeklyGoal == n ? GymColor.onEmber : GymColor.text)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(store.weeklyGoal == n ? GymColor.ember : GymColor.bgRaised, in: .rect(cornerRadius: 14))
                        .accessibilityAddTraits(store.weeklyGoal == n ? .isSelected : [])
                }
            }
            Text(L10n.perWeek(store.weeklyGoal)).font(.gym(15, .semibold)).foregroundStyle(GymColor.textSecondary)
        case .units:
            title(L10n.onbUnitsTitle, L10n.autofills)
            SegToggle([("kg", "kg"), ("lb", "lb")], selection: $store.units, fontSize: 18)
        case .places:
            title(L10n.onbPlaceTitle, L10n.onbPlaceWhy)
            ForEach(["gym", "home", "outdoors"], id: \.self) { id in
                ToggleChip(L10n.placePresetName(id), isOn: store.places.contains(id)) { store.send(.placeTapped(id)) }
            }
        }
    }
    
    private func title(_ title: String, _ why: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.gym(28, .extraBold)).foregroundStyle(GymColor.text)
            Text(why).font(.gym(14.5, .medium)).foregroundStyle(GymColor.textSecondary)
        }
    }
}

#Preview {
    OnboardingView(store: Store(initialState: Onboarding.State()) { Onboarding() })
}
