import ComposableArchitecture
import Database
import DesignSystem
import L10n
import SwiftUI

public struct StickerView: View {
    @Bindable var store: StoreOf<Sticker>
    @GestureState private var drag: CGSize = .zero
    @GestureState private var pinch: CGFloat = 1
    @GestureState private var twist: Angle = .zero

    public init(store: StoreOf<Sticker>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 16) {
            canvas
            Text(L10n.stickerHint).font(.gym(12.5, .medium)).foregroundStyle(GymColor.textSecondary)
            SegToggle(
                [
                    (Sticker.Style.workout, L10n.stickerWorkout),
                    (.streak, L10n.stickerStreak),
                    (.date, L10n.stickerDate),
                    (.week, L10n.stickerWeek),
                ],
                selection: $store.style,
                fontSize: 12.5
            )
            HStack(spacing: 10) {
                Button(L10n.stickerGallery) { store.send(.galleryButtonTapped) }.buttonStyle(.ghost)
                Button(L10n.stickerCamera) { store.send(.cameraButtonTapped) }.buttonStyle(.ghost)
            }
            HStack(spacing: 10) {
                Button(L10n.save.titleCased) { store.send(.saveButtonTapped) }
                    .buttonStyle(.primary(fill: GymColor.bgRaised2, foreground: GymColor.text))
                Button(L10n.share.titleCased) { store.send(.shareButtonTapped) }
                    .buttonStyle(.primary)
            }
        }
        .padding(20)
        .gymScreen(L10n.stickerOpen)
        .task { await store.send(.task).finish() }
    }

    private var canvas: some View {
        RoundedRectangle(cornerRadius: 26)
            .fill(GymColor.bgRaised2)
            .aspectRatio(9 / 14, contentMode: .fit)
            .overlay {
                if !store.hasPhoto {
                    Text(L10n.stickerNoPhoto).font(.gym(14, .semibold)).foregroundStyle(GymColor.textTertiary)
                }
            }
            .overlay {
                sticker
                    .scaleEffect(store.scale * pinch)
                    .rotationEffect(.degrees(store.rotation) + twist)
                    .offset(x: store.offset.width + drag.width, y: store.offset.height + drag.height)
                    .gesture(
                        DragGesture()
                            .updating($drag) { value, state, _ in state = value.translation }
                            .onEnded { store.send(.stickerDragged(translation: $0.translation)) }
                            .simultaneously(
                                with: MagnifyGesture()
                                    .updating($pinch) { value, state, _ in state = value.magnification }
                                    .onEnded { store.send(.stickerPinched(magnification: $0.magnification)) }
                            )
                            .simultaneously(
                                with: RotateGesture()
                                    .updating($twist) { value, state, _ in state = value.rotation }
                                    .onEnded { store.send(.stickerRotated(degrees: $0.rotation.degrees)) })
                    )
            }
            .clipShape(.rect(cornerRadius: 26))
    }

    @ViewBuilder
    private var sticker: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch store.style {
            case .workout:
                Text(dateTitle).font(.gym(12, .bold)).foregroundStyle(.white.opacity(0.7))
                HStack(spacing: 18) {
                    stat(L10n.duration, UnitFormat.clock(store.summary.workout?.durationSeconds ?? 0))
                    stat(L10n.volume, volume)
                    stat(L10n.setsCaps, "\(store.summary.setCount)")
                }
                ForEach(store.summary.exercises.prefix(4)) { exercise in
                    Text(L10n.exerciseName(id: exercise.id, fallback: exercise.name))
                        .font(.gym(13, .semibold))
                        .foregroundStyle(.white)
                }
            case .streak:
                HStack(spacing: 8) {
                    GymIcon(.flame, weight: .fill, size: 28).foregroundStyle(GymColor.accent)
                    Text("\(store.summary.streak)").font(.gym(44, .extraBold)).foregroundStyle(.white)
                }
                Text(L10n.shareStreakLabel).font(.gym(12, .extraBold)).tracking(2).foregroundStyle(.white.opacity(0.7))
            case .date:
                Text(dateTitle).font(.gym(26, .extraBold)).foregroundStyle(.white)
            case .week:
                HStack(spacing: 6) {
                    ForEach(Array(L10n.weekdayInitials.enumerated()), id: \.offset) { index, initial in
                        let done = index < store.summary.weekDone.count && store.summary.weekDone[index]
                        Text(initial)
                            .font(.gym(12, .bold))
                            .foregroundStyle(done ? .black : .white)
                            .frame(width: 28, height: 28)
                            .background(done ? Color.white : Color.white.opacity(0.15), in: .circle)
                    }
                }
            }
        }
        .padding(18)
        .background(.black.opacity(0.55), in: .rect(cornerRadius: 20))
    }

    /// "Saturday, Sep 19".
    private var dateTitle: String {
        store.summary.date?.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()) ?? ""
    }

    /// "8.4 t".
    private var volume: String {
        let volume = UnitFormat.volume(store.summary.volumeKg, units: store.summary.units)
        return "\(volume.value) \(volume.unit)"
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.gym(10, .bold)).tracking(1).foregroundStyle(.white.opacity(0.7))
            Text(value).font(.gym(20, .extraBold)).foregroundStyle(.white)
        }
    }
}

#Preview {
    NavigationStack {
        StickerView(store: previewStore(Sticker.State(), Sticker()))
    }
}

/// A store backed by a database seeded with a month of training.
@MainActor
private func previewStore<R: Reducer>(_ state: R.State, _ reducer: R) -> Store<R.State, R.Action> {
    prepareDependencies {
        // swiftlint:disable:next force_try
        try! $0.bootstrapDatabase()
        // swiftlint:disable:next force_try
        try! $0.seedDatabaseForPreviews()
    }
    return Store(initialState: state) { reducer }
}
