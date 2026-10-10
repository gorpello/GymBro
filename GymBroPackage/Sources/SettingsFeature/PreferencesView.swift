import ComposableArchitecture
import Database
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
                    picker(
                        L10n.theme, icon: .moon, selection: $store.settings.theme,
                        options: [
                            (.system, L10n.themeAuto), (.dark, L10n.darkTheme), (.light, L10n.lightTheme),
                        ])
                    OptionRow(L10n.languageLabel, icon: .translate, value: languageName)
                    OptionRow(L10n.unitsLabel, icon: .scales) {
                        SegToggle(
                            [(WeightUnit.kg, "kg"), (WeightUnit.lb, "lb")], selection: $store.settings.units,
                            fontSize: 13
                        )
                        .frame(width: 110)
                    }
                    picker(
                        L10n.weekStartSetting, icon: .calendarBlank, selection: $store.settings.weekStart,
                        options: [1, 6, 7].map { ($0, weekdayName($0)) })
                    toggle(L10n.heatmapLabelsSetting, icon: .gridFour, isOn: $store.settings.heatmapLabels)
                    picker(
                        L10n.background, icon: .image, selection: $store.settings.background,
                        options: [
                            (.dots, "Dots"), (.grid, "Grid"), (.plain, "None"),
                        ])
                }
                section(L10n.sectionTraining) {
                    OptionRow(L10n.restTimer, icon: .timer) {
                        StepperControl(
                            store.settings.restSeconds == 0 ? L10n.restOff : "\(store.settings.restSeconds)s",
                            fontSize: 15,
                            buttonSize: 34,
                            minWidth: 56,
                            onDecrement: { store.send(.restDecrementButtonTapped) },
                            onIncrement: { store.send(.restIncrementButtonTapped) }
                        )
                    }
                    picker(
                        L10n.effortSetting, icon: .gauge, selection: $store.settings.effort,
                        options: [
                            (.off, L10n.restOff), (.rpe, "RPE"), (.rir, "RIR"),
                        ])
                    toggle(L10n.autoAdvance, icon: .skipForward, isOn: $store.settings.autoAdvance)
                    toggle(L10n.countdownSetting, icon: .timer, isOn: $store.settings.countdown)
                    toggle(L10n.keepScreenOn, icon: .sun, isOn: $store.settings.keepScreenOn)
                    toggle(L10n.multiPlanSetting, icon: .stack, isOn: $store.settings.multiPlan)
                    toggle(L10n.levelHintsSetting, icon: .trendUp, isOn: $store.settings.levelHints)
                    picker(
                        L10n.demoSizeTitle, icon: .filmStrip, selection: $store.settings.demoSize,
                        options: [
                            (.large, L10n.demoLarge), (.small, L10n.demoSmall), (.off, L10n.demoOff),
                        ])
                    Button {
                        store.send(.placesButtonTapped)
                    } label: {
                        OptionRow(L10n.placesLabel.titleCased, icon: .mapPin, value: "")
                    }
                    .buttonStyle(.plain)
                }
                section(L10n.sectionAlerts) {
                    OptionRow(L10n.trainReminder, icon: .bell, value: trainReminderTime)
                    OptionRow(
                        L10n.alarmSound,
                        icon: .speakerHigh,
                        value: store.settings.alarmSoundName ?? L10n.alarmDefaultName
                    )
                    picker(
                        L10n.alarmStyleTitle, icon: .vibrate, selection: $store.settings.alarmStyle,
                        options: [
                            (.loud, L10n.alarmStyleLoud), (.quiet, L10n.alarmStyleQuiet),
                            (.vibrate, L10n.alarmStyleVibrate),
                        ])
                }
                section(L10n.sectionHome) {
                    toggle(L10n.focusCard, icon: .target, isOn: $store.settings.focusCard)
                    toggle(L10n.homeRecommended, icon: .sparkle, isOn: $store.settings.homeRecommended)
                    toggle(L10n.gamificationSetting, icon: .medal, isOn: $store.settings.gamification)
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
        .task { await store.send(.task).finish() }
    }

    /// The language the app is shown in, in that language's own words.
    private var languageName: String {
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        return Locale.current.localizedString(forLanguageCode: code)?.capitalized(with: .current) ?? code
    }

    /// The reminder time, e.g. "18:30", or "Off".
    private var trainReminderTime: String {
        guard let minutes = store.settings.trainReminderMinutes else { return L10n.restOff }
        var components = DateComponents()
        components.hour = minutes / 60
        components.minute = minutes % 60
        return Calendar.current.date(from: components)?.formatted(date: .omitted, time: .shortened) ?? ""
    }

    /// `weekday` counts from Monday = 1; Foundation's weekday symbols start on Sunday.
    private func weekdayName(_ weekday: Int) -> String {
        Calendar.current.standaloneWeekdaySymbols[weekday % 7]
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

    private func picker<Value: Hashable>(
        _ title: String, icon: Ph, selection: Binding<Value>, options: [(Value, String)]
    ) -> some View {
        Menu {
            Picker(title, selection: selection) {
                ForEach(options, id: \.0) { Text($0.1).tag($0.0) }
            }
        } label: {
            OptionRow(title, icon: icon, value: options.first { $0.0 == selection.wrappedValue }?.1 ?? "")
        }
        .buttonStyle(.plain)
    }

    private func action(
        _ title: String, icon: Ph, tint: Color = GymColor.text, perform: @escaping () -> Void
    ) -> some View {
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
        PreferencesView(store: previewStore())
    }
}

@MainActor
private func previewStore() -> StoreOf<Preferences> {
    prepareDependencies {
        // swiftlint:disable:next force_try
        try! $0.bootstrapDatabase()
    }
    return Store(initialState: Preferences.State()) { Preferences() }
}
