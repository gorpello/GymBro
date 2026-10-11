import ComposableArchitecture
import Database
import Foundation
import Routing
import SQLiteData

/// The Exercises tab: the catalogue and the user's own exercises, searchable, filterable and
/// grouped by muscle. Read from the database (see `ExerciseListing`) and re-read whenever the
/// filter or an exercise changes.
@Reducer
public struct ExerciseLibrary {
    @ObservableState
    public struct State: Equatable {
        @Presents public var editor: ExerciseEditor.State?
        public var filter = ExerciseFilter()
        @ObservationStateIgnored
        @Fetch public var listing = ExerciseListing()
        public var showsFilters = false

        public init() {}
    }

    public enum Action: BindableAction {
        case addButtonTapped
        case binding(BindingAction<State>)
        case clearFiltersButtonTapped
        case delegate(Delegate)
        case editor(PresentationAction<ExerciseEditor.Action>)
        case exerciseTapped(id: Exercise.ID)
        case favouriteButtonTapped(id: Exercise.ID)
        case filtersButtonTapped
        case task

        @CasePathable
        public enum Delegate {
            case navigate(Route)
        }
    }

    @Dependency(\.defaultDatabase) var database

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
            .onChange(of: \.filter) { _, filter in
                Reduce { state, _ in load(state, filter: filter) }
            }
        Reduce { state, action in
            switch action {
            case .addButtonTapped:
                state.editor = ExerciseEditor.State(name: state.filter.search.trimmingCharacters(in: .whitespaces))
                return .none
            case .binding, .delegate, .editor:
                return .none
            case .clearFiltersButtonTapped:
                state.filter = ExerciseFilter()
                return load(state, filter: state.filter)
            case let .exerciseTapped(id):
                return .send(.delegate(.navigate(.exerciseDetail(id: id))))
            case let .favouriteButtonTapped(id):
                return .run { _ in
                    await withErrorReporting {
                        try await database.write { db in
                            try ExercisePreference.edit(db, exerciseID: id) { $0.isFavorite.toggle() }
                        }
                    }
                }
            case .filtersButtonTapped:
                state.showsFilters = true
                return .none
            case .task:
                return load(state, filter: state.filter)
            }
        }
        .ifLet(\.$editor, action: \.editor) {
            ExerciseEditor()
        }
    }

    /// Points the listing at `filter`; it keeps following the database from there.
    private func load(_ state: State, filter: ExerciseFilter) -> Effect<Action> {
        .run { [listing = state.$listing] _ in
            await withErrorReporting {
                try await listing.load(ExerciseListing.Request(filter: filter)).task
            }
        }
        .cancellable(id: CancelID.listing, cancelInFlight: true)
    }

    private enum CancelID { case listing }
}
