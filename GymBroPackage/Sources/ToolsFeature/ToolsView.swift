import ComposableArchitecture
import DesignSystem
import L10n
import SwiftUI

public struct ToolsView: View {
    let store: StoreOf<Tools>

    public init(store: StoreOf<Tools>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(Array(store.toolIDs.enumerated()), id: \.element) { index, id in
                    Button {
                        store.send(.toolTapped(id: id))
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            GymIcon(toolIcon(id), weight: .fill, size: 20)
                                .foregroundStyle(Color.black.opacity(0.65))
                                .frame(width: 42, height: 42)
                                .background(
                                    GymColor.folderHues[index % GymColor.folderHues.count], in: .rect(cornerRadius: 12))
                            Text(L10n.toolName(id)).font(.gym(16, .extraBold)).foregroundStyle(GymColor.text)
                            Text(L10n.toolDesc(id))
                                .font(.gym(12.5, .medium))
                                .foregroundStyle(GymColor.textSecondary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2, reservesSpace: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .softCard(padding: 18, radius: 22)
                    }
                    .buttonStyle(.pressable)
                }
            }
            .padding(20)
        }
        .gymScreen(L10n.tools, subtitle: L10n.calculatorsCount(store.toolIDs.count))
    }
}

func toolIcon(_ id: String) -> Ph {
    switch id {
    case "rm": .barbell
    case "plate": .circlesThree
    case "warmup": .fire
    case "bmi": .scales
    case "cal": .forkKnife
    default: .percent
    }
}

public struct ToolDetailView: View {
    let store: StoreOf<ToolDetail>

    public init(store: StoreOf<ToolDetail>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Kicker(L10n.result, size: 11, spacing: 2)
                    StatValue(store.result, unit: store.resultUnit, size: 46)
                    ForEach(store.details, id: \.self) { line in
                        Text(line).font(.gym(14, .semibold)).foregroundStyle(GymColor.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .softCard(padding: 22, radius: 26)
                GroupCard {
                    ForEach(store.inputs) { input in
                        OptionRow(input.label.sentenceCased) {
                            StepperControl(
                                "\(input.value.formatted(.number.precision(.fractionLength(0...1)))) \(input.unit)",
                                fontSize: 15,
                                minWidth: 70,
                                onDecrement: { store.send(.inputChanged(id: input.id, delta: -1)) },
                                onIncrement: { store.send(.inputChanged(id: input.id, delta: 1)) }
                            )
                        }
                    }
                }
            }
            .padding(20)
        }
        .gymScreen(L10n.toolName(store.id), subtitle: L10n.toolDesc(store.id))
    }
}

#Preview {
    NavigationStack {
        ToolsView(store: Store(initialState: Tools.State()) { Tools() })
    }
}
