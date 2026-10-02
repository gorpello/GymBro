import ComposableArchitecture
import DesignSystem
import L10n
import SwiftUI

public struct AboutView: View {
    let store: StoreOf<About>
    
    public init(store: StoreOf<About>) {
        self.store = store
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(spacing: 8) {
                    Text("GymBro").font(.gym(30, .extraBold)).foregroundStyle(GymColor.text)
                    Text(L10n.aboutBlurb).font(.gym(14, .medium)).foregroundStyle(GymColor.textSecondary)
                    Text(L10n.version(store.version)).font(.gym(12, .semibold)).foregroundStyle(GymColor.textTertiary)
                    // Required by GymMane's GPL-3.0 section 7(b) additional term.
                    Text("Based on GymMane by InlitX").font(.gym(12.5, .bold)).foregroundStyle(GymColor.accent)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                GroupCard {
                    perk(.gift, L10n.freeForever, L10n.freeForeverWhy)
                    perk(.wifiSlash, L10n.fullyOffline, L10n.fullyOfflineWhy)
                    perk(.export, L10n.yoursToTake, L10n.yoursToTakeWhy)
                }
                Kicker(L10n.whatsInside, size: 11, spacing: 2)
                GroupCard {
                    perk(.barbell, L10n.exercisesInside(store.exerciseCount), L10n.exercisesInsideWhy)
                    perk(.calculator, L10n.calculatorsInside, L10n.calculatorsInsideWhy)
                    perk(.mathOperations, L10n.mathInside, L10n.mathInsideWhy)
                }
                Kicker(L10n.madeWithLoveBy, size: 11, spacing: 2)
                Text("gorpello").font(.gym(15, .bold)).foregroundStyle(GymColor.text)
                Text("Exercise art: Workout Guide by Bryl Lim and Everkinetic, CC BY-SA 4.0. Font: Nunito, SIL Open Font License.")
                    .font(.gym(12, .medium))
                    .foregroundStyle(GymColor.textSecondary)
                HStack(spacing: 10) {
                    Button(L10n.sourceCode.titleCased) { store.send(.sourceCodeButtonTapped) }.buttonStyle(.ghost)
                    Button(L10n.buyCoffee) { store.send(.buyCoffeeButtonTapped) }.buttonStyle(.ghost)
                }
            }
            .padding(20)
        }
        .gymScreen(L10n.about)
    }
    
    private func perk(_ icon: Ph, _ title: String, _ detail: String) -> some View {
        OptionRow(title, icon: icon, detail: detail) { EmptyView() }
    }
}

#Preview {
    NavigationStack {
        AboutView(store: Store(initialState: About.State()) { About() })
    }
}
