import ComposableArchitecture
import DesignSystem
import L10n
import SwiftUI

public struct PlanImportView: View {
    @Bindable var store: StoreOf<PlanImport>

    public init(store: StoreOf<PlanImport>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SheetTitle(L10n.importRoutines, subtitle: L10n.importPasteHint)
                    .padding(.top, 8)
                TextField(L10n.importPasteHint, text: $store.text, axis: .vertical)
                    .font(.gym(14, .medium))
                    .lineLimit(5...10)
                    .padding(16)
                    .background(GymColor.bgRaised, in: .rect(cornerRadius: 20))
                HStack(spacing: 10) {
                    Button(L10n.pasteAction) { store.send(.pasteButtonTapped) }.buttonStyle(.ghost)
                    Button(L10n.chooseFile) { store.send(.chooseFileButtonTapped) }.buttonStyle(.ghost)
                }
                if !store.found.isEmpty {
                    Kicker(L10n.routineCount(store.found.count), size: 11, spacing: 2)
                    VStack(spacing: 8) {
                        ForEach(store.found) { routine in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(routine.name).font(.gym(15.5, .bold)).foregroundStyle(GymColor.text)
                                    Text(L10n.exerciseCount(routine.exerciseCount)).font(.gym(12.5, .medium))
                                        .foregroundStyle(GymColor.textSecondary)
                                }
                                Spacer()
                                if let day = routine.weekday {
                                    Text(day).font(.gym(12.5, .bold)).foregroundStyle(GymColor.accent)
                                }
                            }
                            .softCard(padding: 14, radius: 18)
                        }
                    }
                    if store.missing > 0 {
                        Text(L10n.aiMissing(store.missing)).font(.gym(12.5, .medium)).foregroundStyle(GymColor.warn)
                    }
                    OptionRow(L10n.useTheirSchedule, detail: L10n.useTheirScheduleHint) {
                        Toggle(L10n.useTheirSchedule, isOn: $store.usesTheirSchedule).labelsHidden().toggleStyle(.gym)
                    }
                    .background(GymColor.bgRaised, in: .rect(cornerRadius: 20))
                    Button(L10n.addToMyRoutines) { store.send(.addButtonTapped) }
                        .buttonStyle(.primary)
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
    PlanImportView(store: Store(initialState: PlanImport.State()) { PlanImport() })
}
