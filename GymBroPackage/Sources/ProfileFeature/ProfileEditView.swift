import ComposableArchitecture
import Database
import DesignSystem
import L10n
import SwiftUI

public struct ProfileEditView: View {
    @Bindable var store: StoreOf<ProfileEdit>

    public init(store: StoreOf<ProfileEdit>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(spacing: 6) {
                    Text(L10n.yourProfile)
                        .font(.gym(17, .bold))
                        .foregroundStyle(GymColor.text)
                    Text(L10n.autofills)
                        .font(.gym(13, .medium))
                        .foregroundStyle(GymColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                textField(L10n.nameLabel, text: $store.profile.name, contentType: .name)
                textField(L10n.handleLabel, text: $store.profile.handle, contentType: .username)

                GroupCard {
                    OptionRow(L10n.sexLabel) {
                        SegToggle([(Sex.male, L10n.male), (Sex.female, L10n.female)], selection: $store.profile.sex)
                            .frame(width: 180)
                    }
                    stepper(L10n.ageLabel, value: "\(store.profile.age)", field: .age)
                    stepper(L10n.heightLabel, value: "\(Int(store.profile.heightCm.rounded())) cm", field: .height)
                    stepper(
                        L10n.weightLabel,
                        value: ProfileFormat.weight(kg: store.profile.weightKg, units: store.units),
                        field: .weight
                    )
                    stepper(L10n.weeklyGoal, value: "\(store.profile.weeklyGoal)×", field: .weeklyGoal)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Kicker(L10n.activityLabel, size: 11, spacing: 2)
                    SegToggle(
                        zip(UserProfile.activityFactors, activityNames).map { (value: $0, label: $1) },
                        selection: $store.profile.activityFactor
                    )
                }

                Button(L10n.done.titleCased) { store.send(.doneButtonTapped) }
                    .buttonStyle(.primary)
                    .padding(.top, 6)
            }
            .padding(20)
        }
        .gymBackground()
    }

    private var activityNames: [String] {
        [L10n.actSedentary, L10n.actLight, L10n.actModerate, L10n.actActive]
    }

    private func textField(_ title: String, text: Binding<String>, contentType: UITextContentType) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Kicker(title, size: 11, spacing: 2)
            TextField(title, text: text)
                .textContentType(contentType)
                .autocorrectionDisabled()
                .font(.gym(15, .semibold))
                .foregroundStyle(GymColor.text)
                .tint(GymColor.accent)
                .padding(.horizontal, 16)
                .frame(height: 48)
                .background(GymColor.bgRaised, in: .capsule)
        }
    }

    private func stepper(_ title: String, value: String, field: ProfileEdit.Field) -> some View {
        OptionRow(title) {
            StepperControl(
                value,
                fontSize: 15,
                buttonSize: 34,
                minWidth: 76,
                onDecrement: { store.send(.decrementButtonTapped(field)) },
                onIncrement: { store.send(.incrementButtonTapped(field)) }
            )
        }
    }
}

#Preview {
    ProfileEditView(store: Store(initialState: ProfileEdit.State()) { ProfileEdit() })
}
