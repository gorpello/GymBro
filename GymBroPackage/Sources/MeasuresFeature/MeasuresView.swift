import ComposableArchitecture
import DesignSystem
import L10n
import SwiftUI

public struct MeasuresView: View {
    @Bindable var store: StoreOf<Measures>
    
    public init(store: StoreOf<Measures>) {
        self.store = store
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.measuresHint)
                    .font(.gym(14, .medium))
                    .foregroundStyle(GymColor.textSecondary)
                ForEach(store.rows) { row in
                    Button {
                        store.send(.measureTapped(key: row.id))
                    } label: {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L10n.measureName(row.id)).font(.gym(15.5, .bold)).foregroundStyle(GymColor.text)
                                if let last = row.history.last {
                                    StatValue(last.value.formatted(.number.precision(.fractionLength(0...1))), unit: unit(row.id), size: 20)
                                } else {
                                    Text(L10n.measureNoneYet).font(.gym(13, .medium)).foregroundStyle(GymColor.textTertiary)
                                }
                            }
                            Spacer()
                            if row.history.count > 1 {
                                Sparkline(row.history.map(\.value), showsRange: false)
                                    .frame(width: 100, height: 36)
                            }
                            GymIcon(.caretRight, weight: .bold, size: 12).foregroundStyle(GymColor.textTertiary)
                        }
                        .softCard(padding: 18, radius: 22)
                    }
                    .buttonStyle(.pressable(scale: 0.98))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .gymScreen(L10n.measures, subtitle: L10n.measureCount(store.readingCount))
        .sheet(item: $store.scope(state: \.entry, action: \.entry)) { entryStore in
            MeasureEntryView(store: entryStore, unit: unit(entryStore.key))
        }
    }
    
    private func unit(_ key: String) -> String {
        key == "bodyfat" ? "%" : store.unit
    }
}

struct MeasureEntryView: View {
    let store: StoreOf<MeasureEntry>
    let unit: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                SheetTitle(L10n.measureName(store.key))
                    .padding(.top, 12)
                StatValue(store.value.formatted(.number.precision(.fractionLength(1))), unit: unit, size: 52)
                HStack(spacing: 10) {
                    ForEach([-1.0, -0.1, 0.1, 1.0], id: \.self) { delta in
                        Button((delta > 0 ? "+" : "–") + abs(delta).formatted()) { store.send(.valueChanged(delta)) }
                            .buttonStyle(.ghost)
                    }
                }
                Button(L10n.save.titleCased) { store.send(.saveButtonTapped) }
                    .buttonStyle(.primary)
                if !store.history.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Kicker(L10n.measureHistory, size: 11, spacing: 2)
                            .padding(.bottom, 8)
                        ForEach(store.history.reversed()) { reading in
                            HStack {
                                Text(reading.date).font(.gym(14.5, .semibold)).foregroundStyle(GymColor.text)
                                Spacer()
                                Text("\(reading.value.formatted()) \(unit)").font(.gym(14.5, .bold)).foregroundStyle(GymColor.text)
                                Button { store.send(.deleteReadingTapped(id: reading.id)) } label: { GymIcon(.trash, size: 16) }
                                    .foregroundStyle(GymColor.textTertiary)
                                    .padding(.leading, 8)
                                    .accessibilityLabel(L10n.delete)
                            }
                            .padding(.vertical, 10)
                        }
                    }
                }
            }
            .padding(20)
        }
        .gymBackground()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    NavigationStack {
        MeasuresView(store: Store(initialState: Measures.State()) { Measures() })
    }
}
