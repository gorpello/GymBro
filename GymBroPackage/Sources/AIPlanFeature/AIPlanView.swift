import ComposableArchitecture
import DesignSystem
import L10n
import SwiftUI

public struct AIPlanView: View {
    @Bindable var store: StoreOf<AIPlan>

    public init(store: StoreOf<AIPlan>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 6) {
                    GymIcon(.wifiSlash, weight: .bold, size: 13)
                    Text(L10n.fullyOffline)
                }
                .font(.gym(12.5, .bold))
                .foregroundStyle(GymColor.sage)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(GymColor.sageSoft, in: .capsule)
                Text(L10n.aiIntro).font(.gym(14.5, .medium)).foregroundStyle(GymColor.textSecondary)
                VStack(alignment: .leading, spacing: 14) {
                    step(1, L10n.aiStepCopy)
                    step(2, L10n.aiStepAsk)
                    step(3, L10n.aiStepPaste)
                }
                .softCard(padding: 20, radius: 24)
                HStack(spacing: 10) {
                    Button(L10n.copyForAi) { store.send(.copyButtonTapped) }.buttonStyle(.primary)
                    Button(L10n.shareAsFile) { store.send(.shareFileButtonTapped) }
                        .buttonStyle(.primary(fill: GymColor.bgRaised2, foreground: GymColor.text))
                }
                TextField(L10n.aiPasteHint, text: $store.answer, axis: .vertical)
                    .font(.gym(14, .medium))
                    .lineLimit(6...12)
                    .padding(16)
                    .background(GymColor.bgRaised, in: .rect(cornerRadius: 20))
                HStack(spacing: 10) {
                    Button(L10n.pasteAction) { store.send(.pasteButtonTapped) }.buttonStyle(.ghost)
                    Button(L10n.chooseFile) { store.send(.chooseFileButtonTapped) }.buttonStyle(.ghost)
                    Spacer()
                    Button(L10n.showFormat) { store.send(.showFormatButtonTapped) }
                        .font(.gym(13, .semibold))
                        .foregroundStyle(GymColor.textSecondary)
                }
                Button(L10n.importAction) { store.send(.importButtonTapped) }
                    .buttonStyle(.primary)
                    .disabled(store.answer.isEmpty)
            }
            .padding(20)
        }
        .gymScreen(L10n.aiRoutine)
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(number)")
                .font(.gym(12, .extraBold))
                .foregroundStyle(GymColor.onEmber)
                .frame(width: 24, height: 24)
                .background(GymColor.ember, in: .circle)
            Text(text).font(.gym(14, .medium)).foregroundStyle(GymColor.text)
        }
    }
}

#Preview {
    NavigationStack {
        AIPlanView(store: Store(initialState: AIPlan.State()) { AIPlan() })
    }
}
