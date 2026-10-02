import ComposableArchitecture
import DesignSystem
import L10n
import SwiftUI

public struct PreferencesView: View {
    @Bindable var store: StoreOf<Preferences>
    
    public init(store: StoreOf<Preferences>) {
        self.store = store
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                section(L10n.sectionGeneral) {
                    picker(L10n.theme, icon: .moon, selection: $store.theme, options: [
                        ("auto", L10n.themeAuto), ("dark", L10n.darkTheme), ("light", L10n.lightTheme),
                    ])
                    OptionRow(L10n.languageLabel, icon: .translate, value: store.languageName)
                    OptionRow(L10n.unitsLabel, icon: .scales) {
                        SegToggle([("kg", "kg"), ("lb", "lb")], selection: $store.units, fontSize: 13)
                            .frame(width: 110)
                    }
                    OptionRow(L10n.weekStartSetting, icon: .calendarBlank, value: store.weekStart)
                    toggle(L10n.heatmapLabelsSetting, icon: .gridFour, isOn: $store.heatmapLabels)
                    picker(L10n.background, icon: .image, selection: $store.background, options: [
                        ("dots", "Dots"), ("grid", "Grid"), ("none", "None"),
                    ])
                }
                section(L10n.sectionTraining) {
                    OptionRow(L10n.restTimer, icon: .timer) {
                        StepperControl(
                            store.restSeconds == 0 ? L10n.restOff : "\(store.restSeconds)s",
                            fontSize: 15,
                            buttonSize: 34,
                            minWidth: 56,
                            onDecrement: { store.send(.restDecrementButtonTapped) },
                            onIncrement: { store.send(.restIncrementButtonTapped) }
                        )
                    }
                    picker(L10n.effortSetting, icon: .gauge, selection: $store.effort, options: [
                        ("off", L10n.restOff), ("rpe", "RPE"), ("rir", "RIR"),
                    ])
                    toggle(L10n.autoAdvance, icon: .skipForward, isOn: $store.autoAdvance)
                    toggle(L10n.countdownSetting, icon: .timer, isOn: $store.countdown)
                    toggle(L10n.keepScreenOn, icon: .sun, isOn: $store.keepScreenOn)
                    toggle(L10n.multiPlanSetting, icon: .stack, isOn: $store.multiPlan)
                    toggle(L10n.levelHintsSetting, icon: .trendUp, isOn: $store.levelHints)
                    picker(L10n.demoSizeTitle, icon: .filmStrip, selection: $store.demoSize, options: [
                        ("large", L10n.demoLarge), ("small", L10n.demoSmall), ("off", L10n.demoOff),
                    ])
                    Button { store.send(.placesButtonTapped) } label: {
                        OptionRow(L10n.placesLabel.titleCased, icon: .mapPin, value: "")
                    }
                    .buttonStyle(.plain)
                }
                section(L10n.sectionAlerts) {
                    OptionRow(L10n.trainReminder, icon: .bell, value: store.trainReminder)
                    OptionRow(L10n.alarmSound, icon: .speakerHigh, value: store.alarmSoundName)
                    picker(L10n.alarmStyleTitle, icon: .vibrate, selection: $store.alarmStyle, options: [
                        ("loud", L10n.alarmStyleLoud), ("quiet", L10n.alarmStyleQuiet), ("vibrate", L10n.alarmStyleVibrate),
                    ])
                }
                section(L10n.sectionHome) {
                    toggle(L10n.focusCard, icon: .target, isOn: $store.focusCard)
                    toggle(L10n.homeRecommended, icon: .sparkle, isOn: $store.homeRecommended)
                    toggle(L10n.gamificationSetting, icon: .medal, isOn: $store.gamification)
                }
                section(L10n.sectionData) {
                    action(L10n.exportCsv, icon: .fileCsv) { store.send(.exportCsvButtonTapped) }
                    action(L10n.exportBackup, icon: .fileZip) { store.send(.exportBackupButtonTapped) }
                    action(L10n.importBackup, icon: .downloadSimple) { store.send(.importBackupButtonTapped) }
                    action(L10n.importFromApp, icon: .arrowsLeftRight) { store.send(.importFromAppButtonTapped) }
                    action(L10n.stravaRow, icon: .bicycle) { store.send(.stravaButtonTapped) }
                    action(L10n.resetData, icon: .trash, tint: GymColor.danger) { store.send(.deleteAllButtonTapped) }
                }
                section(L10n.support) {
                    action(L10n.reportBug, icon: .bug) { store.send(.reportBugButtonTapped) }
                    action(L10n.requestFeature, icon: .lightbulb) { store.send(.requestFeatureButtonTapped) }
                    action(L10n.starOnGithub, icon: .star) { store.send(.starButtonTapped) }
                    action(L10n.buyCoffee, icon: .coffee) { store.send(.buyCoffeeButtonTapped) }
                    action(L10n.aboutGymmane, icon: .info) { store.send(.aboutButtonTapped) }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .gymScreen(L10n.settings)
    }
    
    private func section(_ title: String, @ViewBuilder rows: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Kicker(title, size: 11, spacing: 2)
                .padding(.leading, 4)
                .padding(.top, 14)
            GroupCard(content: rows)
        }
    }
    
    private func toggle(_ title: String, icon: Ph, isOn: Binding<Bool>) -> some View {
        OptionRow(title, icon: icon) {
            Toggle(title, isOn: isOn).labelsHidden().toggleStyle(.gym)
        }
    }
    
    private func picker(_ title: String, icon: Ph, selection: Binding<String>, options: [(String, String)]) -> some View {
        Menu {
            Picker(title, selection: selection) {
                ForEach(options, id: \.0) { Text($0.1).tag($0.0) }
            }
        } label: {
            OptionRow(title, icon: icon, value: options.first { $0.0 == selection.wrappedValue }?.1 ?? "")
        }
        .buttonStyle(.plain)
    }
    
    private func action(_ title: String, icon: Ph, tint: Color = GymColor.text, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            OptionRow(title, icon: icon) {
                GymIcon(.caretRight, weight: .bold, size: 12).foregroundStyle(GymColor.textTertiary)
            }
            .foregroundStyle(tint)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        PreferencesView(store: Store(initialState: Preferences.State()) { Preferences() })
    }
}
