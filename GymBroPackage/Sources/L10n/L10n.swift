// Converted from the GymMane ARB files. Keys and translations live in Resources/Localizable.xcstrings.
import Foundation

public enum L10n {
    public static var languageName: String { tr("languageName") }
    public static func vsLastMonthLabel(_ fraction: Double) -> String { tr("vsLastMonthLabel", percent(fraction)) }
    public static func levelStreakLabel(level: Int, streak: String) -> String { tr("levelStreakLabel", level, streak) }
    public static var save: String { tr("save") }
    public static var cancel: String { tr("cancel") }
    public static var cancelCaps: String { tr("cancelCaps") }
    public static var deleteCaps: String { tr("deleteCaps") }
    public static var done: String { tr("done") }
    public static var `set`: String { tr("set") }
    public static var home: String { tr("home") }
    public static var progress: String { tr("progress") }
    public static var exercises: String { tr("exercises") }
    public static var settings: String { tr("settings") }
    public static var today: String { tr("today") }
    public static var thisWeek: String { tr("thisWeek") }
    public static var recommended: String { tr("recommended") }
    public static var goal: String { tr("goal") }
    public static var volume: String { tr("volume") }
    public static var setsToday: String { tr("setsToday") }
    public static var prs: String { tr("prs") }
    public static var todaysFocus: String { tr("todaysFocus") }
    public static var todaysRoutine: String { tr("todaysRoutine") }
    public static var startWorkout: String { tr("startWorkout") }
    public static var routines: String { tr("routines") }
    public static var tools: String { tr("tools") }
    public static var firstSessionHint: String { tr("firstSessionHint") }
    public static func exerciseCount(_ n: Int) -> String { tr("exerciseCount", n) }
    public static var pushDay: String { tr("pushDay") }
    public static var pullDay: String { tr("pullDay") }
    public static var legDay: String { tr("legDay") }
    public static var pushFocus: String { tr("pushFocus") }
    public static var pullFocus: String { tr("pullFocus") }
    public static var legFocus: String { tr("legFocus") }
    public static var train: String { tr("train") }
    public static var step1: String { tr("step1") }
    public static var step2: String { tr("step2") }
    public static var chooseFocus: String { tr("chooseFocus") }
    public static var buildSession: String { tr("buildSession") }
    public static var tapMuscles: String { tr("tapMuscles") }
    public static var noMusclesYet: String { tr("noMusclesYet") }
    public static var continueBtn: String { tr("continueBtn") }
    public static var nothingForFocus: String { tr("nothingForFocus") }
    public static var goBackPick: String { tr("goBackPick") }
    public static func pickedHint(_ n: Int) -> String { tr("pickedHint", n) }
    public static var pickAnExercise: String { tr("pickAnExercise") }
    public static var searchAllExercises: String { tr("searchAllExercises") }
    public static var noExercisesMatch: String { tr("noExercisesMatch") }
    public static var createItInstead: String { tr("createItInstead") }
    public static func startCount(_ n: Int) -> String { tr("startCount", n) }
    public static var inProgress: String { tr("inProgress") }
    public static var paused: String { tr("paused") }
    public static var last: String { tr("last") }
    public static var rest: String { tr("rest") }
    public static var skip: String { tr("skip") }
    public static var addSet: String { tr("addSet") }
    public static var finishSession: String { tr("finishSession") }
    public static var setDone: String { tr("setDone") }
    public static var nextExercise: String { tr("nextExercise") }
    public static var skipExercise: String { tr("skipExercise") }
    public static func skipExerciseBody(_ name: String) -> String { tr("skipExerciseBody", name) }
    public static var dropExerciseAction: String { tr("dropExerciseAction") }
    public static var restOff: String { tr("restOff") }
    public static var setCol: String { tr("setCol") }
    public static var repsCol: String { tr("repsCol") }
    public static func weightCol(_ unit: String) -> String { tr("weightCol", unit) }
    public static var repsTitle: String { tr("repsTitle") }
    public static func weightTitle(_ unit: String) -> String { tr("weightTitle", unit) }
    public static var sessionComplete: String { tr("sessionComplete") }
    public static var finishHeadlinePr: String { tr("finishHeadlinePr") }
    public static var finishHeadlineGoal: String { tr("finishHeadlineGoal") }
    public static var finishHeadlineStreak: String { tr("finishHeadlineStreak") }
    public static var finishHeadlineDefault: String { tr("finishHeadlineDefault") }
    public static func finishBodyPr(_ prs: Int) -> String { tr("finishBodyPr", prs) }
    public static var finishBodyGoal: String { tr("finishBodyGoal") }
    public static func finishBodyStreak(_ streak: Int) -> String { tr("finishBodyStreak", streak) }
    public static var finishBodyDefault: String { tr("finishBodyDefault") }
    public static var vsLastTime: String { tr("vsLastTime") }
    public static var firstTime: String { tr("firstTime") }
    public static func prCount(_ n: Int) -> String { tr("prCount", n) }
    public static var duration: String { tr("duration") }
    public static var setsCaps: String { tr("setsCaps") }
    public static func exerciseXofY(i: Int, n: Int) -> String { tr("exerciseXofY", i, n) }
    public static var decrease: String { tr("decrease") }
    public static var increase: String { tr("increase") }
    public static func markSet(_ n: Int) -> String { tr("markSet", n) }
    public static var pauseWorkout: String { tr("pauseWorkout") }
    public static var resumeWorkout: String { tr("resumeWorkout") }
    public static var discardTitle: String { tr("discardTitle") }
    public static var discardBody: String { tr("discardBody") }
    public static var keepTraining: String { tr("keepTraining") }
    public static var discard: String { tr("discard") }
    public static var notifRestChannel: String { tr("notifRestChannel") }
    public static var notifRestChannelWhy: String { tr("notifRestChannelWhy") }
    public static var notifAlertChannel: String { tr("notifAlertChannel") }
    public static var notifAlertChannelWhy: String { tr("notifAlertChannelWhy") }
    public static var restOverTitle: String { tr("restOverTitle") }
    public static var restOverBody: String { tr("restOverBody") }
    public static var totalVolume30d: String { tr("totalVolume30d") }
    public static var volumeCumulative: String { tr("volumeCumulative") }
    public static var volumeChartEmpty: String { tr("volumeChartEmpty") }
    public static var weekRhythm: String { tr("weekRhythm") }
    public static var weekRhythmHint: String { tr("weekRhythmHint") }
    public static func weekRhythmBest(_ day: String) -> String { tr("weekRhythmBest", day) }
    public static var weekRhythmEmpty: String { tr("weekRhythmEmpty") }
    public static var allTime: String { tr("allTime") }
    public static var allTimeSessions: String { tr("allTimeSessions") }
    public static var allTimeTime: String { tr("allTimeTime") }
    public static var allTimeVolume: String { tr("allTimeVolume") }
    public static var allTimeSets: String { tr("allTimeSets") }
    public static func allTimeAvg(_ time: String) -> String { tr("allTimeAvg", time) }
    public static func hoursShort(_ n: Int) -> String { tr("hoursShort", n) }
    public static var consistency: String { tr("consistency") }
    public static func sessionsLogged(_ n: Int) -> String { tr("sessionsLogged", n) }
    public static func streakDays(_ n: Int) -> String { tr("streakDays", n) }
    public static var bodyweight: String { tr("bodyweight") }
    public static var notLoggedYet: String { tr("notLoggedYet") }
    public static var logShort: String { tr("logShort") }
    public static var logBodyweight: String { tr("logBodyweight") }
    public static var trackWeight: String { tr("trackWeight") }
    public static var muscleMap: String { tr("muscleMap") }
    public static var days7: String { tr("days7") }
    public static var days30: String { tr("days30") }
    public static var heatLow: String { tr("heatLow") }
    public static var heatHigh: String { tr("heatHigh") }
    public static var muscleMapEmpty: String { tr("muscleMapEmpty") }
    public static var muscleMapHint: String { tr("muscleMapHint") }
    public static func muscleMapBehind(_ names: String) -> String { tr("muscleMapBehind", names) }
    public static func ofTarget(_ fraction: Double) -> String { tr("ofTarget", percent(fraction)) }
    public static var muscleSplit: String { tr("muscleSplit") }
    public static var splitEmpty: String { tr("splitEmpty") }
    public static var personalRecords: String { tr("personalRecords") }
    public static var prEmpty: String { tr("prEmpty") }
    public static var strength1rm: String { tr("strength1rm") }
    public static var strengthEmpty: String { tr("strengthEmpty") }
    public static func oneRmEst(_ w: String) -> String { tr("oneRmEst", w) }
    public static var restDayShort: String { tr("restDayShort") }
    public static var restDay: String { tr("restDay") }
    public static var delete: String { tr("delete") }
    public static var deleteEntry: String { tr("deleteEntry") }
    public static func deleteEntryBody(_ name: String) -> String { tr("deleteEntryBody", name) }
    public static var bodyweightHistory: String { tr("bodyweightHistory") }
    public static var noBodyweightYet: String { tr("noBodyweightYet") }
    public static var exercisesCaps: String { tr("exercisesCaps") }
    public static var timeCaps: String { tr("timeCaps") }
    public static func libraryCount(_ n: Int) -> String { tr("libraryCount", n) }
    public static var searchExercises: String { tr("searchExercises") }
    public static var muscleFilter: String { tr("muscleFilter") }
    public static var levelFilter: String { tr("levelFilter") }
    public static var newExercise: String { tr("newExercise") }
    public static var exerciseName: String { tr("exerciseName") }
    public static var equipmentLabel: String { tr("equipmentLabel") }
    public static var addExercise: String { tr("addExercise") }
    public static var advanced: String { tr("advanced") }
    public static var demoMedia: String { tr("demoMedia") }
    public static var addMedia: String { tr("addMedia") }
    public static var mediaHint: String { tr("mediaHint") }
    public static var changeMedia: String { tr("changeMedia") }
    public static var videoSelected: String { tr("videoSelected") }
    public static var favouritesOnly: String { tr("favouritesOnly") }
    public static var noFavouritesYet: String { tr("noFavouritesYet") }
    public static var noFavouritesHint: String { tr("noFavouritesHint") }
    public static var clearFilters: String { tr("clearFilters") }
    public static var noExercisesFound: String { tr("noExercisesFound") }
    public static var noExercisesHint: String { tr("noExercisesHint") }
    public static var personalRecord: String { tr("personalRecord") }
    public static var history: String { tr("history") }
    public static var noHistory: String { tr("noHistory") }
    public static var notes: String { tr("notes") }
    public static var notePlaceholder: String { tr("notePlaceholder") }
    public static func showAllNotes(_ n: Int) -> String { tr("showAllNotes", n) }
    public static func notHere(gear: String, place: String) -> String { tr("notHere", gear, place) }
    public static var notHereWhy: String { tr("notHereWhy") }
    public static var altHere: String { tr("altHere") }
    public static var places: String { tr("places") }
    public static var placesShort: String { tr("placesShort") }
    public static var placesHint: String { tr("placesHint") }
    public static var placeAll: String { tr("placeAll") }
    public static var placeNew: String { tr("placeNew") }
    public static var placeNameLabel: String { tr("placeNameLabel") }
    public static var placeNamePlaceholder: String { tr("placeNamePlaceholder") }
    public static var placeGearLabel: String { tr("placeGearLabel") }
    public static func placeGearCount(_ n: Int) -> String { tr("placeGearCount", n) }
    public static func placeExercises(_ n: Int) -> String { tr("placeExercises", n) }
    public static var placeEmptyTitle: String { tr("placeEmptyTitle") }
    public static var placeEmptyBody: String { tr("placeEmptyBody") }
    public static var placeDeleteTitle: String { tr("placeDeleteTitle") }
    public static var placeDeleteBody: String { tr("placeDeleteBody") }
    public static var placeGym: String { tr("placeGym") }
    public static var placeHome: String { tr("placeHome") }
    public static var placeOutdoors: String { tr("placeOutdoors") }
    public static var placeFilterLabel: String { tr("placeFilterLabel") }
    public static var noGearOnly: String { tr("noGearOnly") }
    public static func placeActive(_ name: String) -> String { tr("placeActive", name) }
    public static var journal: String { tr("journal") }
    public static func noteCount(_ n: Int) -> String { tr("noteCount", n) }
    public static var noteKindNote: String { tr("noteKindNote") }
    public static var noteKindPlan: String { tr("noteKindPlan") }
    public static var noteKindDone: String { tr("noteKindDone") }
    public static var noteKindPain: String { tr("noteKindPain") }
    public static var noteFilterAll: String { tr("noteFilterAll") }
    public static var newNote: String { tr("newNote") }
    public static var editNote: String { tr("editNote") }
    public static var addNote: String { tr("addNote") }
    public static var noteEmptyTitle: String { tr("noteEmptyTitle") }
    public static var noteEmptyBody: String { tr("noteEmptyBody") }
    public static var noteNoneForExercise: String { tr("noteNoneForExercise") }
    public static var noteKindLabel: String { tr("noteKindLabel") }
    public static var noteTextLabel: String { tr("noteTextLabel") }
    public static var noteDateLabel: String { tr("noteDateLabel") }
    public static var noteExerciseLabel: String { tr("noteExerciseLabel") }
    public static var noteMediaLabel: String { tr("noteMediaLabel") }
    public static var noteGeneral: String { tr("noteGeneral") }
    public static var noteAttach: String { tr("noteAttach") }
    public static var noteRemoveMedia: String { tr("noteRemoveMedia") }
    public static var deleteNoteTitle: String { tr("deleteNoteTitle") }
    public static var deleteNoteBody: String { tr("deleteNoteBody") }
    public static var noteToday: String { tr("noteToday") }
    public static var noteYesterday: String { tr("noteYesterday") }
    public static var noteAllNotes: String { tr("noteAllNotes") }
    public static var noteCalendar: String { tr("noteCalendar") }
    public static var noteNoneOnDay: String { tr("noteNoneOnDay") }
    public static var noteAddOnDay: String { tr("noteAddOnDay") }
    public static var notePrevMonth: String { tr("notePrevMonth") }
    public static var noteNextMonth: String { tr("noteNextMonth") }
    public static func noteMonthCount(_ n: Int) -> String { tr("noteMonthCount", n) }
    public static var measures: String { tr("measures") }
    public static var measuresHint: String { tr("measuresHint") }
    public static func measureCount(_ n: Int) -> String { tr("measureCount", n) }
    public static var measureNoneYet: String { tr("measureNoneYet") }
    public static var measureHistory: String { tr("measureHistory") }
    public static var measureNeck: String { tr("measureNeck") }
    public static var measureShoulders: String { tr("measureShoulders") }
    public static var measureChest: String { tr("measureChest") }
    public static var measureArm: String { tr("measureArm") }
    public static var measureForearm: String { tr("measureForearm") }
    public static var measureWaist: String { tr("measureWaist") }
    public static var measureHips: String { tr("measureHips") }
    public static var measureThigh: String { tr("measureThigh") }
    public static var measureCalf: String { tr("measureCalf") }
    public static var measureBodyfat: String { tr("measureBodyfat") }
    public static var timeline: String { tr("timeline") }
    public static var timelineHint: String { tr("timelineHint") }
    public static var timelineEmptyTitle: String { tr("timelineEmptyTitle") }
    public static func photoCount(_ n: Int) -> String { tr("photoCount", n) }
    public static var poseFront: String { tr("poseFront") }
    public static var poseSide: String { tr("poseSide") }
    public static var poseBack: String { tr("poseBack") }
    public static var photoEvery: String { tr("photoEvery") }
    public static func photoEveryDays(_ n: Int) -> String { tr("photoEveryDays", n) }
    public static var photoEveryOff: String { tr("photoEveryOff") }
    public static var timelineEvery: String { tr("timelineEvery") }
    public static var custom: String { tr("custom") }
    public static func photoNextIn(_ n: Int) -> String { tr("photoNextIn", n) }
    public static var photoDueNow: String { tr("photoDueNow") }
    public static var addTodayPhotos: String { tr("addTodayPhotos") }
    public static func posePhoto(_ pose: String) -> String { tr("posePhoto", pose) }
    public static var compare: String { tr("compare") }
    public static var compareNeedTwo: String { tr("compareNeedTwo") }
    public static func dayNumber(_ n: Int) -> String { tr("dayNumber", n) }
    public static func daysApart(_ n: Int) -> String { tr("daysApart", n) }
    public static var deleteEntryTitle: String { tr("deleteEntryTitle") }
    public static var deleteDayBody: String { tr("deleteDayBody") }
    public static var timelinePhotos: String { tr("timelinePhotos") }
    public static var timelineBody: String { tr("timelineBody") }
    public static var timelineBodyEmpty: String { tr("timelineBodyEmpty") }
    public static var timelineBodyHint: String { tr("timelineBodyHint") }
    public static func timelineWindow(from: String, to: String) -> String { tr("timelineWindow", from, to) }
    public static func sessionCount(_ n: Int) -> String { tr("sessionCount", n) }
    public static var notifPhotoChannel: String { tr("notifPhotoChannel") }
    public static var notifPhotoChannelWhy: String { tr("notifPhotoChannelWhy") }
    public static var notifPhotoTitle: String { tr("notifPhotoTitle") }
    public static func notifPhotoBody(_ n: Int) -> String { tr("notifPhotoBody", n) }
    public static var share: String { tr("share") }
    public static var sharePick: String { tr("sharePick") }
    public static var shareSession: String { tr("shareSession") }
    public static var shareStreak: String { tr("shareStreak") }
    public static var shareBody: String { tr("shareBody") }
    public static var shareCompare: String { tr("shareCompare") }
    public static var shareHint: String { tr("shareHint") }
    public static var shareFailed: String { tr("shareFailed") }
    public static var shareWeekOf: String { tr("shareWeekOf") }
    public static var shareStreakLabel: String { tr("shareStreakLabel") }
    public static var shareSessionsLabel: String { tr("shareSessionsLabel") }
    public static var shareVolumeLabel: String { tr("shareVolumeLabel") }
    public static var shareSetsLabel: String { tr("shareSetsLabel") }
    public static var shareNothing: String { tr("shareNothing") }
    public static var restForExercise: String { tr("restForExercise") }
    public static var restUsingDefault: String { tr("restUsingDefault") }
    public static var restCustom: String { tr("restCustom") }
    public static var setType: String { tr("setType") }
    public static var setTypeNormal: String { tr("setTypeNormal") }
    public static var setTypeWarmup: String { tr("setTypeWarmup") }
    public static var setTypeDrop: String { tr("setTypeDrop") }
    public static var setTypeFailure: String { tr("setTypeFailure") }
    public static var addWarmup: String { tr("addWarmup") }
    public static func platesPerSide(_ plates: String) -> String { tr("platesPerSide", plates) }
    public static var howTo: String { tr("howTo") }
    public static var similar: String { tr("similar") }
    public static var primaryLabel: String { tr("primaryLabel") }
    public static var secondaryLabel: String { tr("secondaryLabel") }
    public static var none: String { tr("none") }
    public static func setCount(_ n: Int) -> String { tr("setCount", n) }
    public static func volumeSuffix(_ v: String) -> String { tr("volumeSuffix", v) }
    public static var weeklyPlan: String { tr("weeklyPlan") }
    public static var yourRoutines: String { tr("yourRoutines") }
    public static var noRoutines: String { tr("noRoutines") }
    public static var newRoutine: String { tr("newRoutine") }
    public static var routineName: String { tr("routineName") }
    public static var schedule: String { tr("schedule") }
    public static var addFromList: String { tr("addFromList") }
    public static var addExercises: String { tr("addExercises") }
    public static var deleteRoutine: String { tr("deleteRoutine") }
    public static func exercisesWithCount(_ n: Int) -> String { tr("exercisesWithCount", n) }
    public static func setDay(_ day: String) -> String { tr("setDay", day) }
    public static var newRoutineName: String { tr("newRoutineName") }
    public static var dragToReorder: String { tr("dragToReorder") }
    public static func reorderHandle(_ name: String) -> String { tr("reorderHandle", name) }
    public static var removeFromRoutine: String { tr("removeFromRoutine") }
    public static var dropExercise: String { tr("dropExercise") }
    public static func dropExerciseBody(_ name: String) -> String { tr("dropExerciseBody", name) }
    public static var drop: String { tr("drop") }
    public static var addToWorkout: String { tr("addToWorkout") }
    public static var resetData: String { tr("resetData") }
    public static var resetTitle: String { tr("resetTitle") }
    public static var resetBody: String { tr("resetBody") }
    public static var resetConfirm: String { tr("resetConfirm") }
    public static var resetDone: String { tr("resetDone") }
    public static var support: String { tr("support") }
    public static var reportBug: String { tr("reportBug") }
    public static var requestFeature: String { tr("requestFeature") }
    public static var starOnGithub: String { tr("starOnGithub") }
    public static var buyCoffee: String { tr("buyCoffee") }
    public static var cantOpenLink: String { tr("cantOpenLink") }
    public static var theme: String { tr("theme") }
    public static var darkTheme: String { tr("darkTheme") }
    public static var lightTheme: String { tr("lightTheme") }
    public static var languageLabel: String { tr("languageLabel") }
    public static var unitsLabel: String { tr("unitsLabel") }
    public static var restTimer: String { tr("restTimer") }
    public static var alarmBlockedTitle: String { tr("alarmBlockedTitle") }
    public static var alarmBlockedBody: String { tr("alarmBlockedBody") }
    public static var alarmBlockedAction: String { tr("alarmBlockedAction") }
    public static var alarmSound: String { tr("alarmSound") }
    public static var alarmDefaultName: String { tr("alarmDefaultName") }
    public static var alarmSoundHint: String { tr("alarmSoundHint") }
    public static var alarmChoose: String { tr("alarmChoose") }
    public static var alarmPreview: String { tr("alarmPreview") }
    public static var alarmReset: String { tr("alarmReset") }
    public static var alarmTooLong: String { tr("alarmTooLong") }
    public static var alarmInvalid: String { tr("alarmInvalid") }
    public static func alarmChanged(_ name: String) -> String { tr("alarmChanged", name) }
    public static var alarmChangedDefault: String { tr("alarmChangedDefault") }
    public static var addActivityWidget: String { tr("addActivityWidget") }
    public static var addStatsWidget: String { tr("addStatsWidget") }
    public static var pinUnsupported: String { tr("pinUnsupported") }
    public static var background: String { tr("background") }
    public static var bgNone: String { tr("bgNone") }
    public static var bgDots: String { tr("bgDots") }
    public static var bgGrid: String { tr("bgGrid") }
    public static var exportCsv: String { tr("exportCsv") }
    public static var exportBackup: String { tr("exportBackup") }
    public static var importBackup: String { tr("importBackup") }
    public static var importHint: String { tr("importHint") }
    public static var `import`: String { tr("import") }
    public static var chooseFile: String { tr("chooseFile") }
    public static var importFromApp: String { tr("importFromApp") }
    public static var importUnknownFormat: String { tr("importUnknownFormat") }
    public static var importZipNoWeights: String { tr("importZipNoWeights") }
    public static func importWeights(_ n: Int) -> String { tr("importWeights", n) }
    public static var importReadFailed: String { tr("importReadFailed") }
    public static var importUnitTitle: String { tr("importUnitTitle") }
    public static var importUnitBody: String { tr("importUnitBody") }
    public static var importNothing: String { tr("importNothing") }
    public static func importDone(_ n: Int) -> String { tr("importDone", n) }
    public static var aboutGymmane: String { tr("aboutGymmane") }
    public static var yourProfile: String { tr("yourProfile") }
    public static var autofills: String { tr("autofills") }
    public static var nameLabel: String { tr("nameLabel") }
    public static var sexLabel: String { tr("sexLabel") }
    public static var macroProtein: String { tr("macroProtein") }
    public static var macroCarbs: String { tr("macroCarbs") }
    public static var macroFat: String { tr("macroFat") }
    public static var male: String { tr("male") }
    public static var female: String { tr("female") }
    public static var ageLabel: String { tr("ageLabel") }
    public static var heightLabel: String { tr("heightLabel") }
    public static var weightLabel: String { tr("weightLabel") }
    public static var weeklyGoal: String { tr("weeklyGoal") }
    public static var activityLabel: String { tr("activityLabel") }
    public static var addPhoto: String { tr("addPhoto") }
    public static var removePhoto: String { tr("removePhoto") }
    public static var takePhoto: String { tr("takePhoto") }
    public static var chooseGallery: String { tr("chooseGallery") }
    public static var backupCopied: String { tr("backupCopied") }
    public static var backupImported: String { tr("backupImported") }
    public static var backupFailed: String { tr("backupFailed") }
    public static var nothingToExport: String { tr("nothingToExport") }
    public static var athlete: String { tr("athlete") }
    public static func calculatorsCount(_ n: Int) -> String { tr("calculatorsCount", n) }
    public static var result: String { tr("result") }
    public static var weightLifted: String { tr("weightLifted") }
    public static var repsPerformed: String { tr("repsPerformed") }
    public static var neck: String { tr("neck") }
    public static var waist: String { tr("waist") }
    public static var hip: String { tr("hip") }
    public static var targetWeight: String { tr("targetWeight") }
    public static var workingWeight: String { tr("workingWeight") }
    public static var activityLevel: String { tr("activityLevel") }
    public static var barWeight: String { tr("barWeight") }
    public static var perSide: String { tr("perSide") }
    public static var justTheBar: String { tr("justTheBar") }
    public static func perSideCount(_ n: Int) -> String { tr("perSideCount", n) }
    public static func rampSet(pct: String, reps: Int) -> String { tr("rampSet", pct, reps) }
    public static var toolNameRm: String { tr("toolNameRm") }
    public static var toolNameBmi: String { tr("toolNameBmi") }
    public static var toolNameCal: String { tr("toolNameCal") }
    public static var toolNameBf: String { tr("toolNameBf") }
    public static var toolNamePlate: String { tr("toolNamePlate") }
    public static var toolNameWarmup: String { tr("toolNameWarmup") }
    public static var toolTitleRm: String { tr("toolTitleRm") }
    public static var toolTitleBmi: String { tr("toolTitleBmi") }
    public static var toolTitleCal: String { tr("toolTitleCal") }
    public static var toolTitleBf: String { tr("toolTitleBf") }
    public static var toolTitlePlate: String { tr("toolTitlePlate") }
    public static var toolTitleWarmup: String { tr("toolTitleWarmup") }
    public static var toolHintRm: String { tr("toolHintRm") }
    public static var toolHintCal: String { tr("toolHintCal") }
    public static var toolHintBf: String { tr("toolHintBf") }
    public static var toolHintPlate: String { tr("toolHintPlate") }
    public static var toolHintWarmup: String { tr("toolHintWarmup") }
    public static var toolDescRm: String { tr("toolDescRm") }
    public static var toolDescBmi: String { tr("toolDescBmi") }
    public static var toolDescCal: String { tr("toolDescCal") }
    public static var toolDescBf: String { tr("toolDescBf") }
    public static var toolDescPlate: String { tr("toolDescPlate") }
    public static var toolDescWarmup: String { tr("toolDescWarmup") }
    public static var bmiUnderweight: String { tr("bmiUnderweight") }
    public static var bmiNormal: String { tr("bmiNormal") }
    public static var bmiOverweight: String { tr("bmiOverweight") }
    public static var bmiObese: String { tr("bmiObese") }
    public static var actSedentary: String { tr("actSedentary") }
    public static var actLight: String { tr("actLight") }
    public static var actActive: String { tr("actActive") }
    public static var actModerate: String { tr("actModerate") }
    public static var muscleChest: String { tr("muscleChest") }
    public static var muscleBack: String { tr("muscleBack") }
    public static var muscleShoulders: String { tr("muscleShoulders") }
    public static var muscleBiceps: String { tr("muscleBiceps") }
    public static var muscleTriceps: String { tr("muscleTriceps") }
    public static var muscleForearm: String { tr("muscleForearm") }
    public static var muscleTrapezius: String { tr("muscleTrapezius") }
    public static var muscleAbdomen: String { tr("muscleAbdomen") }
    public static var muscleObliques: String { tr("muscleObliques") }
    public static var muscleQuads: String { tr("muscleQuads") }
    public static var muscleHamstrings: String { tr("muscleHamstrings") }
    public static var muscleGlutes: String { tr("muscleGlutes") }
    public static var muscleCalves: String { tr("muscleCalves") }
    public static var mgChest: String { tr("mgChest") }
    public static var mgBack: String { tr("mgBack") }
    public static var mgLegs: String { tr("mgLegs") }
    public static var mgShoulders: String { tr("mgShoulders") }
    public static var mgArms: String { tr("mgArms") }
    public static var mgCore: String { tr("mgCore") }
    public static var equipBarbell: String { tr("equipBarbell") }
    public static var equipDumbbell: String { tr("equipDumbbell") }
    public static var equipCable: String { tr("equipCable") }
    public static var equipMachine: String { tr("equipMachine") }
    public static var equipBodyweight: String { tr("equipBodyweight") }
    public static var equipWeighted: String { tr("equipWeighted") }
    public static var equipBand: String { tr("equipBand") }
    public static var equipKettlebell: String { tr("equipKettlebell") }
    public static var equipRings: String { tr("equipRings") }
    public static var equipOther: String { tr("equipOther") }
    public static var diffBeginner: String { tr("diffBeginner") }
    public static var diffAdvanced: String { tr("diffAdvanced") }
    public static var diffIntermediate: String { tr("diffIntermediate") }
    public static var about: String { tr("about") }
    public static func version(_ v: String) -> String { tr("version", v) }
    public static var aboutBlurb: String { tr("aboutBlurb") }
    public static var freeForever: String { tr("freeForever") }
    public static var freeForeverWhy: String { tr("freeForeverWhy") }
    public static var fullyOffline: String { tr("fullyOffline") }
    public static var fullyOfflineWhy: String { tr("fullyOfflineWhy") }
    public static var yoursToTake: String { tr("yoursToTake") }
    public static var yoursToTakeWhy: String { tr("yoursToTakeWhy") }
    public static var whatsInside: String { tr("whatsInside") }
    public static func exercisesInside(_ n: Int) -> String { tr("exercisesInside", n) }
    public static var exercisesInsideWhy: String { tr("exercisesInsideWhy") }
    public static var calculatorsInside: String { tr("calculatorsInside") }
    public static var calculatorsInsideWhy: String { tr("calculatorsInsideWhy") }
    public static var mathInside: String { tr("mathInside") }
    public static var mathInsideWhy: String { tr("mathInsideWhy") }
    public static var yourNumbers: String { tr("yourNumbers") }
    public static var sessionsCaps: String { tr("sessionsCaps") }
    public static var liftedCaps: String { tr("liftedCaps") }
    public static var streakCaps: String { tr("streakCaps") }
    public static func daysUnit(_ n: Int) -> String { tr("daysUnit", n) }
    public static var restDefaultLabel: String { tr("restDefaultLabel") }
    public static func restDefault(_ s: Int) -> String { tr("restDefault", s) }
    public static var reset: String { tr("reset") }
    public static var welcomeKicker: String { tr("welcomeKicker") }
    public static var welcomeBlurb: String { tr("welcomeBlurb") }
    public static var welcomeStart: String { tr("welcomeStart") }
    public static func onbStep(i: Int, n: Int) -> String { tr("onbStep", i, n) }
    public static var onbNameTitle: String { tr("onbNameTitle") }
    public static var onbNameHint: String { tr("onbNameHint") }
    public static var onbNameWhy: String { tr("onbNameWhy") }
    public static var onbBodyTitle: String { tr("onbBodyTitle") }
    public static var onbBodyWhy: String { tr("onbBodyWhy") }
    public static var onbGoalTitle: String { tr("onbGoalTitle") }
    public static var onbGoalWhy: String { tr("onbGoalWhy") }
    public static func perWeek(_ n: Int) -> String { tr("perWeek", n) }
    public static var onbUnitsTitle: String { tr("onbUnitsTitle") }
    public static var next: String { tr("next") }
    public static var back: String { tr("back") }
    public static var skip2: String { tr("skip2") }
    public static var madeWithLoveBy: String { tr("madeWithLoveBy") }
    public static var sourceCode: String { tr("sourceCode") }
    public static var suggested: String { tr("suggested") }
    public static var results: String { tr("results") }
    public static var noMatches: String { tr("noMatches") }
    public static var tapToEdit: String { tr("tapToEdit") }
    public static var editEntry: String { tr("editEntry") }
    public static var editEntryHint: String { tr("editEntryHint") }
    public static var removeSet: String { tr("removeSet") }
    public static var continueWorkout: String { tr("continueWorkout") }
    public static var continueWorkoutBody: String { tr("continueWorkoutBody") }
    public static var addBodyWidget: String { tr("addBodyWidget") }
    public static var repsOnly: String { tr("repsOnly") }
    public static var repsOnlyHint: String { tr("repsOnlyHint") }
    public static var useDefaultArt: String { tr("useDefaultArt") }
    public static func daysShort(_ n: Int) -> String { tr("daysShort", n) }
    public static var focusCard: String { tr("focusCard") }
    public static var autoAdvance: String { tr("autoAdvance") }
    public static var keepScreenOn: String { tr("keepScreenOn") }
    public static var lockWorkout: String { tr("lockWorkout") }
    public static var unlockWorkout: String { tr("unlockWorkout") }
    public static var lockedCaps: String { tr("lockedCaps") }
    public static var holdToUnlock: String { tr("holdToUnlock") }
    public static var liveChannel: String { tr("liveChannel") }
    public static var liveChannelWhy: String { tr("liveChannelWhy") }
    public static func liveSet(n: Int, total: Int) -> String { tr("liveSet", n, total) }
    public static var liveResting: String { tr("liveResting") }
    public static var liveAllDone: String { tr("liveAllDone") }
    public static var autoAdvanceHint: String { tr("autoAdvanceHint") }
    public static var autoProgress: String { tr("autoProgress") }
    public static func autoProgressHint(_ w: String) -> String { tr("autoProgressHint", w) }
    public static var placePlates: String { tr("placePlates") }
    public static var platesAll: String { tr("platesAll") }
    public static func platesOwned(_ n: Int) -> String { tr("platesOwned", n) }
    public static var platePairs: String { tr("platePairs") }
    public static func plateAchievable(_ w: String) -> String { tr("plateAchievable", w) }
    public static var autoWarmup: String { tr("autoWarmup") }
    public static var autoWarmupHint: String { tr("autoWarmupHint") }
    public static var trainReminder: String { tr("trainReminder") }
    public static var trainReminderHint: String { tr("trainReminderHint") }
    public static var notifTrainChannel: String { tr("notifTrainChannel") }
    public static var notifTrainChannelWhy: String { tr("notifTrainChannelWhy") }
    public static var notifTrainTitle: String { tr("notifTrainTitle") }
    public static var notifTrainBody: String { tr("notifTrainBody") }
    public static var exportCatalog: String { tr("exportCatalog") }
    public static var importRoutine: String { tr("importRoutine") }
    public static var planIntro: String { tr("planIntro") }
    public static var planFormat: String { tr("planFormat") }
    public static func planImported(_ n: Int) -> String { tr("planImported", n) }
    public static var planNothing: String { tr("planNothing") }
    public static var planFailed: String { tr("planFailed") }
    public static var routineGroup: String { tr("routineGroup") }
    public static var newGroup: String { tr("newGroup") }
    public static var noGroup: String { tr("noGroup") }
    public static var groupNameHint: String { tr("groupNameHint") }
    public static var filters: String { tr("filters") }
    public static var setsPlannedHint: String { tr("setsPlannedHint") }
    public static var nextTime: String { tr("nextTime") }
    public static var nextHold: String { tr("nextHold") }
    public static var bgPhoto: String { tr("bgPhoto") }
    public static var bgPhotoPick: String { tr("bgPhotoPick") }
    public static var bgPhotoChange: String { tr("bgPhotoChange") }
    public static var bgPhotoRemove: String { tr("bgPhotoRemove") }
    public static var bgDim: String { tr("bgDim") }
    public static var dimSoft: String { tr("dimSoft") }
    public static var dimMedium: String { tr("dimMedium") }
    public static var dimStrong: String { tr("dimStrong") }
    public static var bgPhotoHint: String { tr("bgPhotoHint") }
    public static var reminderSmart: String { tr("reminderSmart") }
    public static var reminderFixed: String { tr("reminderFixed") }
    public static var reminderSmartHint: String { tr("reminderSmartHint") }
    public static var reminderSmartEmpty: String { tr("reminderSmartEmpty") }
    public static func habitFocus(_ day: String) -> String { tr("habitFocus", day) }
    public static var duplicateRoutine: String { tr("duplicateRoutine") }
    public static func copySuffix(_ name: String) -> String { tr("copySuffix", name) }
    public static var saveAsRoutine: String { tr("saveAsRoutine") }
    public static var savedAsRoutine: String { tr("savedAsRoutine") }
    public static var templates: String { tr("templates") }
    public static var templatesHint: String { tr("templatesHint") }
    public static func templateAdded(_ n: Int) -> String { tr("templateAdded", n) }
    public static var tplFullbody: String { tr("tplFullbody") }
    public static var tplPpl: String { tr("tplPpl") }
    public static var tplUpperlower: String { tr("tplUpperlower") }
    public static var tplStronglifts: String { tr("tplStronglifts") }
    public static var tplStartingstrength: String { tr("tplStartingstrength") }
    public static var tplHome: String { tr("tplHome") }
    public static func dayCount(_ n: Int) -> String { tr("dayCount", n) }
    public static var logRpe: String { tr("logRpe") }
    public static var rpeTitle: String { tr("rpeTitle") }
    public static var rpeHint: String { tr("rpeHint") }
    public static var superset: String { tr("superset") }
    public static var supersetLink: String { tr("supersetLink") }
    public static var supersetHint: String { tr("supersetHint") }
    public static var aiRoutine: String { tr("aiRoutine") }
    public static var aiIntro: String { tr("aiIntro") }
    public static var aiStep1: String { tr("aiStep1") }
    public static var aiStep2: String { tr("aiStep2") }
    public static var aiStep3: String { tr("aiStep3") }
    public static var aiStep4: String { tr("aiStep4") }
    public static func aiMissing(_ n: Int) -> String { tr("aiMissing", n) }
    public static var importApps: String { tr("importApps") }
    public static var importOtherCsv: String { tr("importOtherCsv") }
    public static var importAskApp: String { tr("importAskApp") }
    public static var awardFirstStepName: String { tr("awardFirstStepName") }
    public static var awardFirstStepLine: String { tr("awardFirstStepLine") }
    public static var awardFirstWorkoutName: String { tr("awardFirstWorkoutName") }
    public static var awardFirstWorkoutLine: String { tr("awardFirstWorkoutLine") }
    public static var awardFirstRoutineName: String { tr("awardFirstRoutineName") }
    public static var awardFirstRoutineLine: String { tr("awardFirstRoutineLine") }
    public static var awardFirstRecordName: String { tr("awardFirstRecordName") }
    public static var awardFirstRecordLine: String { tr("awardFirstRecordLine") }
    public static var awardStreak3Name: String { tr("awardStreak3Name") }
    public static var awardStreak3Line: String { tr("awardStreak3Line") }
    public static var awardTonne1Name: String { tr("awardTonne1Name") }
    public static var awardTonne1Line: String { tr("awardTonne1Line") }
    public static var awardSets100Name: String { tr("awardSets100Name") }
    public static var awardSets100Line: String { tr("awardSets100Line") }
    public static var awardHours10Name: String { tr("awardHours10Name") }
    public static var awardHours10Line: String { tr("awardHours10Line") }
    public static var awardWorkouts50Name: String { tr("awardWorkouts50Name") }
    public static var awardWorkouts50Line: String { tr("awardWorkouts50Line") }
    public static var awardHours50Name: String { tr("awardHours50Name") }
    public static var awardHours50Line: String { tr("awardHours50Line") }
    public static var awardsTitle: String { tr("awardsTitle") }
    public static var awardWon: String { tr("awardWon") }
    public static var yearTitle: String { tr("yearTitle") }
    public static var yearBestMonth: String { tr("yearBestMonth") }
    public static var yearMonths: String { tr("yearMonths") }
    public static var awardSpinHint: String { tr("awardSpinHint") }
    public static var awardUnlocked: String { tr("awardUnlocked") }
    public static var awardNice: String { tr("awardNice") }
    public static var awardSaveImage: String { tr("awardSaveImage") }
    public static var awardSaved: String { tr("awardSaved") }
    public static var awardStreakBottom: String { tr("awardStreakBottom") }
    public static var awardStreak7Top: String { tr("awardStreak7Top") }
    public static var awardStreak7Name: String { tr("awardStreak7Name") }
    public static var awardStreak7Line: String { tr("awardStreak7Line") }
    public static var awardStreak30Top: String { tr("awardStreak30Top") }
    public static var awardStreak30Name: String { tr("awardStreak30Name") }
    public static var awardStreak30Line: String { tr("awardStreak30Line") }
    public static var awardWorkouts100Top: String { tr("awardWorkouts100Top") }
    public static var awardWorkouts100Bottom: String { tr("awardWorkouts100Bottom") }
    public static var awardWorkouts100Name: String { tr("awardWorkouts100Name") }
    public static var awardWorkouts100Line: String { tr("awardWorkouts100Line") }
    public static var awardTonnes100Top: String { tr("awardTonnes100Top") }
    public static var awardTonnes100Bottom: String { tr("awardTonnes100Bottom") }
    public static var awardTonnes100Name: String { tr("awardTonnes100Name") }
    public static var awardTonnes100Line: String { tr("awardTonnes100Line") }
    public static var awardSets1000Top: String { tr("awardSets1000Top") }
    public static var awardSets1000Bottom: String { tr("awardSets1000Bottom") }
    public static var awardSets1000Name: String { tr("awardSets1000Name") }
    public static var awardSets1000Line: String { tr("awardSets1000Line") }
    public static var profile: String { tr("profile") }
    public static var editProfile: String { tr("editProfile") }
    public static var pickBadge: String { tr("pickBadge") }
    public static var badgeTitle: String { tr("badgeTitle") }
    public static var statWorkouts: String { tr("statWorkouts") }
    public static var statTrained: String { tr("statTrained") }
    public static var statSets: String { tr("statSets") }
    public static var statLifted: String { tr("statLifted") }
    public static var statStreak: String { tr("statStreak") }
    public static var statDays: String { tr("statDays") }
    public static var unitHours: String { tr("unitHours") }
    public static var unitDays: String { tr("unitDays") }
    public static var snapshots: String { tr("snapshots") }
    public static var snapNow: String { tr("snapNow") }
    public static var calendarLegend: String { tr("calendarLegend") }
    public static var addCover: String { tr("addCover") }
    public static var addTodayWidget: String { tr("addTodayWidget") }
    public static var monthTitle: String { tr("monthTitle") }
    public static var photosCard: String { tr("photosCard") }
    public static var handleLabel: String { tr("handleLabel") }
    public static var setupTitle: String { tr("setupTitle") }
    public static var setupHint: String { tr("setupHint") }
    public static var setupWorkout: String { tr("setupWorkout") }
    public static var setupWeight: String { tr("setupWeight") }
    public static var setupMeasures: String { tr("setupMeasures") }
    public static var setupPhoto: String { tr("setupPhoto") }
    public static var progressTitle: String { tr("progressTitle") }
    public static var tileVolume30: String { tr("tileVolume30") }
    public static var tileAddWeight: String { tr("tileAddWeight") }
    public static var heatToneTitle: String { tr("heatToneTitle") }
    public static var heatToneHint: String { tr("heatToneHint") }
    public static var thisWeekTitle: String { tr("thisWeekTitle") }
    public static var momentsEmptyTitle: String { tr("momentsEmptyTitle") }
    public static var deletePhotoTitle: String { tr("deletePhotoTitle") }
    public static var deletePhotoBody: String { tr("deletePhotoBody") }
    public static var awardsEarned: String { tr("awardsEarned") }
    public static var awardsLocked: String { tr("awardsLocked") }
    public static var awardStreak100Name: String { tr("awardStreak100Name") }
    public static var awardWorkouts10Name: String { tr("awardWorkouts10Name") }
    public static var awardWorkouts10Line: String { tr("awardWorkouts10Line") }
    public static var awardWorkouts365Name: String { tr("awardWorkouts365Name") }
    public static var awardWorkouts365Line: String { tr("awardWorkouts365Line") }
    public static var awardTonnes10Name: String { tr("awardTonnes10Name") }
    public static var awardTonnes10Line: String { tr("awardTonnes10Line") }
    public static var awardHours100Name: String { tr("awardHours100Name") }
    public static var awardHours100Line: String { tr("awardHours100Line") }
    public static func awardWonOn(_ date: String) -> String { tr("awardWonOn", date) }
    public static func awardProgressLabel(value: String, goal: String) -> String {
        tr("awardProgressLabel", value, goal)
    }
    public static func badgeName(_ id: String) -> String { tr("badgeName." + id) }
    public static func memberSince(_ date: String) -> String { tr("memberSince", date) }
    public static func levelShort(_ n: Int) -> String { tr("levelShort", n) }
    public static func levelToNext(n: Int, next: Int) -> String { tr("levelToNext", n, next) }
    public static func heightCm(_ n: Int) -> String { tr("heightCm", n) }
    public static func heatToneName(_ id: String) -> String { tr("heatToneName." + id) }
    public static func setsThisWeek(_ n: Int) -> String { tr("setsThisWeek", n) }
    public static func weekOfGoal(n: Int, goal: Int) -> String { tr("weekOfGoal", n, goal) }
    public static func momentCount(_ n: Int) -> String { tr("momentCount", n) }
    public static var badgeHint: String { tr("badgeHint") }
    public static var momentsEmptyHint: String { tr("momentsEmptyHint") }
    public static var awardStreak100Line: String { tr("awardStreak100Line") }
    public static var coverLabel: String { tr("coverLabel") }
    public static var removeCover: String { tr("removeCover") }
    public static var startTitle: String { tr("startTitle") }
    public static var logTitle: String { tr("logTitle") }
    public static var logHint: String { tr("logHint") }
    public static var orStartFrom: String { tr("orStartFrom") }
    public static var pickExercisesOption: String { tr("pickExercisesOption") }
    public static var chooseFocusOption: String { tr("chooseFocusOption") }
    public static var plannedRoutine: String { tr("plannedRoutine") }
    public static var logWorkoutAction: String { tr("logWorkoutAction") }
    public static var logging: String { tr("logging") }
    public static var placesLabel: String { tr("placesLabel") }
    public static var undo: String { tr("undo") }
    public static var deleteSet: String { tr("deleteSet") }
    public static var setDeleted: String { tr("setDeleted") }
    public static var removeWarmup: String { tr("removeWarmup") }
    public static var addWeightAction: String { tr("addWeightAction") }
    public static var workoutOverview: String { tr("workoutOverview") }
    public static var allExercisesShort: String { tr("allExercisesShort") }
    public static func setsDoneOf(done: Int, total: Int) -> String { tr("setsDoneOf", done, total) }
    public static var nowLabel: String { tr("nowLabel") }
    public static var deleteWorkout: String { tr("deleteWorkout") }
    public static var deleteWorkoutBody: String { tr("deleteWorkoutBody") }
    public static var themeAuto: String { tr("themeAuto") }
    public static var themeAutoHint: String { tr("themeAutoHint") }
    public static var demoSizeTitle: String { tr("demoSizeTitle") }
    public static var demoLarge: String { tr("demoLarge") }
    public static var demoSmall: String { tr("demoSmall") }
    public static var demoOff: String { tr("demoOff") }
    public static var demoLoopTitle: String { tr("demoLoopTitle") }
    public static var demoLoopAlways: String { tr("demoLoopAlways") }
    public static var demoLoopShort: String { tr("demoLoopShort") }
    public static var demoLoopHint: String { tr("demoLoopHint") }
    public static var alarmStyleTitle: String { tr("alarmStyleTitle") }
    public static var alarmStyleLoud: String { tr("alarmStyleLoud") }
    public static var alarmStyleQuiet: String { tr("alarmStyleQuiet") }
    public static var alarmStyleVibrate: String { tr("alarmStyleVibrate") }
    public static var alarmStyleHint: String { tr("alarmStyleHint") }
    public static var suggestedPicks: String { tr("suggestedPicks") }
    public static var moreOptions: String { tr("moreOptions") }
    public static var suggestInWorkouts: String { tr("suggestInWorkouts") }
    public static var suggestInWorkoutsHint: String { tr("suggestInWorkoutsHint") }
    public static var dontSuggest: String { tr("dontSuggest") }
    public static var onbPlaceTitle: String { tr("onbPlaceTitle") }
    public static var onbPlaceWhy: String { tr("onbPlaceWhy") }
    public static var onbPlaceGear: String { tr("onbPlaceGear") }
    public static func distanceCol(_ unit: String) -> String { tr("distanceCol", unit) }
    public static var timeCol: String { tr("timeCol") }
    public static var timeMinutesTitle: String { tr("timeMinutesTitle") }
    public static var timeSecondsTitle: String { tr("timeSecondsTitle") }
    public static func distanceTitle(_ unit: String) -> String { tr("distanceTitle", unit) }
    public static var holdLabel: String { tr("holdLabel") }
    public static var stopLabel: String { tr("stopLabel") }
    public static func startHold(_ time: String) -> String { tr("startHold", time) }
    public static var exerciseTypeLabel: String { tr("exerciseTypeLabel") }
    public static var typeReps: String { tr("typeReps") }
    public static var typeTime: String { tr("typeTime") }
    public static var typeCardio: String { tr("typeCardio") }
    public static var exerciseTypeHint: String { tr("exerciseTypeHint") }
    public static var howToLabel: String { tr("howToLabel") }
    public static var howToHint: String { tr("howToHint") }
    public static var editExercise: String { tr("editExercise") }
    public static var saveChanges: String { tr("saveChanges") }
    public static var noStepsYet: String { tr("noStepsYet") }
    public static var addSteps: String { tr("addSteps") }
    public static var setTypeRestPause: String { tr("setTypeRestPause") }
    public static var setTypeNormalInfo: String { tr("setTypeNormalInfo") }
    public static var setTypeWarmupInfo: String { tr("setTypeWarmupInfo") }
    public static var setTypeDropInfo: String { tr("setTypeDropInfo") }
    public static var setTypeFailureInfo: String { tr("setTypeFailureInfo") }
    public static var setTypeRestPauseInfo: String { tr("setTypeRestPauseInfo") }
    public static var planFormatNotes: String { tr("planFormatNotes") }
    public static var planSets: String { tr("planSets") }
    public static var planSetsHint: String { tr("planSetsHint") }
    public static var autoValue: String { tr("autoValue") }
    public static var clearPlan: String { tr("clearPlan") }
    public static var planChip: String { tr("planChip") }
    public static var shareRoutine: String { tr("shareRoutine") }
    public static var shareWeek: String { tr("shareWeek") }
    public static var shareWeekHint: String { tr("shareWeekHint") }
    public static func shareMessage(_ name: String) -> String { tr("shareMessage", name) }
    public static var importRoutines: String { tr("importRoutines") }
    public static var importPasteHint: String { tr("importPasteHint") }
    public static var pasteAction: String { tr("pasteAction") }
    public static func routineCount(_ n: Int) -> String { tr("routineCount", n) }
    public static var useTheirSchedule: String { tr("useTheirSchedule") }
    public static var useTheirScheduleHint: String { tr("useTheirScheduleHint") }
    public static var addToMyRoutines: String { tr("addToMyRoutines") }
    public static func routinesAdded(_ n: Int) -> String { tr("routinesAdded", n) }
    public static var nothingToImport: String { tr("nothingToImport") }
    public static var aiStepCopy: String { tr("aiStepCopy") }
    public static var aiStepAsk: String { tr("aiStepAsk") }
    public static var aiStepPaste: String { tr("aiStepPaste") }
    public static var copyForAi: String { tr("copyForAi") }
    public static var copiedDone: String { tr("copiedDone") }
    public static var aiPasteHint: String { tr("aiPasteHint") }
    public static var importAction: String { tr("importAction") }
    public static var showFormat: String { tr("showFormat") }
    public static var shareAsFile: String { tr("shareAsFile") }
    public static var recoveryTab: String { tr("recoveryTab") }
    public static func recoveryOverall(_ fraction: Double) -> String { tr("recoveryOverall", percent(fraction)) }
    public static var recoveryAllFresh: String { tr("recoveryAllFresh") }
    public static func recoveryStill(_ muscles: String) -> String { tr("recoveryStill", muscles) }
    public static var recoveryTired: String { tr("recoveryTired") }
    public static var recoveryFresh: String { tr("recoveryFresh") }
    public static var recoveryHint: String { tr("recoveryHint") }
    public static func recoveryPct(_ fraction: Double) -> String { tr("recoveryPct", percent(fraction)) }
    public static func readyInHours(_ h: Int) -> String { tr("readyInHours", h) }
    public static var tplAbcd: String { tr("tplAbcd") }
    public static var tplAbcde: String { tr("tplAbcde") }
    public static var elapsedCaps: String { tr("elapsedCaps") }
    public static var tapToSkip: String { tr("tapToSkip") }
    public static var screenLocked: String { tr("screenLocked") }
    public static var lockedHint: String { tr("lockedHint") }
    public static var liveDoneSet: String { tr("liveDoneSet") }
    public static var liveSkipRest: String { tr("liveSkipRest") }
    public static var livePause: String { tr("livePause") }
    public static var liveResume: String { tr("liveResume") }
    public static var liveNext: String { tr("liveNext") }
    public static func liveUpNext(_ name: String) -> String { tr("liveUpNext", name) }
    public static var stickerOpen: String { tr("stickerOpen") }
    public static var stickerNoPhoto: String { tr("stickerNoPhoto") }
    public static var stickerWorkout: String { tr("stickerWorkout") }
    public static var stickerStreak: String { tr("stickerStreak") }
    public static var stickerDate: String { tr("stickerDate") }
    public static var stickerHint: String { tr("stickerHint") }
    public static var stickerSaved: String { tr("stickerSaved") }
    public static var stickerWeek: String { tr("stickerWeek") }
    public static var getReady: String { tr("getReady") }
    public static var stickerGallery: String { tr("stickerGallery") }
    public static var stickerCamera: String { tr("stickerCamera") }
    public static var shareIntroTitle: String { tr("shareIntroTitle") }
    public static var shareIntroBody: String { tr("shareIntroBody") }
    public static var removedFromRoutine: String { tr("removedFromRoutine") }
    public static var radarTitle: String { tr("radarTitle") }
    public static var radarHint: String { tr("radarHint") }
    public static var radarEmpty: String { tr("radarEmpty") }
    public static var radarBalanced: String { tr("radarBalanced") }
    public static func radarFocus(_ list: String) -> String { tr("radarFocus", list) }
    public static var countdownReady: String { tr("countdownReady") }
    public static var countdownSkip: String { tr("countdownSkip") }
    public static var countdownSetting: String { tr("countdownSetting") }
    public static var effortSetting: String { tr("effortSetting") }
    public static var effortHint: String { tr("effortHint") }
    public static var rirTitle: String { tr("rirTitle") }
    public static var rirHint: String { tr("rirHint") }
    public static var addWeekWidget: String { tr("addWeekWidget") }
    public static var gamificationSetting: String { tr("gamificationSetting") }
    public static func repCount(_ n: Int) -> String { tr("repCount", n) }
    public static var prBestSet: String { tr("prBestSet") }
    public static var weekStartSetting: String { tr("weekStartSetting") }
    public static var stepOutOfWorkout: String { tr("stepOutOfWorkout") }
    public static var saveToRoutine: String { tr("saveToRoutine") }
    public static var routineUpdated: String { tr("routineUpdated") }
    public static func saveChangesTitle(_ name: String) -> String { tr("saveChangesTitle", name) }
    public static var saveChangesBody: String { tr("saveChangesBody") }
    public static var routineOrderChanged: String { tr("routineOrderChanged") }
    public static var mineOnly: String { tr("mineOnly") }
    public static func createNamed(_ name: String) -> String { tr("createNamed", name) }
    public static var orStartWith: String { tr("orStartWith") }
    public static var warmupFocus: String { tr("warmupFocus") }
    public static var warmupFocusHint: String { tr("warmupFocusHint") }
    public static var cardioFocus: String { tr("cardioFocus") }
    public static var cardioFocusHint: String { tr("cardioFocusHint") }
    public static var homeRecommended: String { tr("homeRecommended") }
    public static var archivedFilter: String { tr("archivedFilter") }
    public static var archiveExercise: String { tr("archiveExercise") }
    public static var restoreExercise: String { tr("restoreExercise") }
    public static var archivedToast: String { tr("archivedToast") }
    public static var archivedToastHint: String { tr("archivedToastHint") }
    public static var archivedBanner: String { tr("archivedBanner") }
    public static var videoMarksHint: String { tr("videoMarksHint") }
    public static var videoMarkHere: String { tr("videoMarkHere") }
    public static var sectionGeneral: String { tr("sectionGeneral") }
    public static var sectionTraining: String { tr("sectionTraining") }
    public static var sectionAlerts: String { tr("sectionAlerts") }
    public static var sectionHome: String { tr("sectionHome") }
    public static var sectionWidgets: String { tr("sectionWidgets") }
    public static var sectionData: String { tr("sectionData") }
    public static var multiPlanSetting: String { tr("multiPlanSetting") }
    public static var multiPlanHint: String { tr("multiPlanHint") }
    public static func routineOfDay(n: Int, total: Int) -> String { tr("routineOfDay", n, total) }
    public static var planAboutMe: String { tr("planAboutMe") }
    public static func planBody(sex: String, age: Int, height: String, weight: String) -> String {
        tr("planBody", sex, age, height, weight)
    }
    public static func planDays(_ n: Int) -> String { tr("planDays", n) }
    public static var planNoHistory: String { tr("planNoHistory") }
    public static func planHistory(_ n: Int) -> String { tr("planHistory", n) }
    public static var planBestLifts: String { tr("planBestLifts") }
    public static var planAskFirst: String { tr("planAskFirst") }
    public static var backToTop: String { tr("backToTop") }
    public static var deleteExerciseTitle: String { tr("deleteExerciseTitle") }
    public static func deleteExerciseBody(_ name: String) -> String { tr("deleteExerciseBody", name) }
    public static var exportForStravaHint: String { tr("exportForStravaHint") }
    public static var manualStartTime: String { tr("manualStartTime") }
    public static var manualDuration: String { tr("manualDuration") }
    public static var manualDurationUnset: String { tr("manualDurationUnset") }
    public static var stravaRow: String { tr("stravaRow") }
    public static var stravaBeta: String { tr("stravaBeta") }
    public static var stravaIntro: String { tr("stravaIntro") }
    public static var stravaEmpty: String { tr("stravaEmpty") }
    public static var tapToPause: String { tr("tapToPause") }
    public static var holdPausedHint: String { tr("holdPausedHint") }
    public static var finishHoldNow: String { tr("finishHoldNow") }
    public static var barWeightExercise: String { tr("barWeightExercise") }
    public static var barWeightHint: String { tr("barWeightHint") }
    public static var barWeightCustom: String { tr("barWeightCustom") }
    public static var groupRename: String { tr("groupRename") }
    public static var groupUngroup: String { tr("groupUngroup") }
    public static var groupDeleteAll: String { tr("groupDeleteAll") }
    public static func groupDeleteTitle(_ name: String) -> String { tr("groupDeleteTitle", name) }
    public static func groupDeleteBody(_ count: String) -> String { tr("groupDeleteBody", count) }
    public static var tplRr: String { tr("tplRr") }
    public static var levelUpKicker: String { tr("levelUpKicker") }
    public static func levelUpBody(reps: Int, name: String) -> String { tr("levelUpBody", reps, name) }
    public static func levelUpSwap(_ routine: String) -> String { tr("levelUpSwap", routine) }
    public static var levelUpSee: String { tr("levelUpSee") }
    public static var levelUpLater: String { tr("levelUpLater") }
    public static var levelUpStay: String { tr("levelUpStay") }
    public static func levelUpSwapped(name: String, routine: String) -> String { tr("levelUpSwapped", name, routine) }
    public static var levelUpStayed: String { tr("levelUpStayed") }
    public static var levelHintsSetting: String { tr("levelHintsSetting") }
    public static var heatmapLabelsSetting: String { tr("heatmapLabelsSetting") }
    public static var rmPercent: String { tr("rmPercent") }
    public static func rmAtPercent(_ pct: String) -> String { tr("rmAtPercent", pct) }
    public static var copyWorkout: String { tr("copyWorkout") }
    public static var goalSet: String { tr("goalSet") }
    public static var goalTargetReps: String { tr("goalTargetReps") }
    public static func goalToGo(_ value: String) -> String { tr("goalToGo", value) }
    public static var goalReached: String { tr("goalReached") }
    public static func goalDaysLeft(_ n: Int) -> String { tr("goalDaysLeft", n) }
    public static var goalOverdue: String { tr("goalOverdue") }
    public static var goalDeadline: String { tr("goalDeadline") }
    public static var goalNoDeadline: String { tr("goalNoDeadline") }
    public static var goalRemove: String { tr("goalRemove") }

    /// Name of a built-in exercise in the current language, falling back to `fallback`.
    public static func exerciseName(id: String, fallback: String) -> String {
        Bundle.module.localizedString(forKey: "\(id).name", value: fallback, table: "ExerciseCatalog")
    }

    /// One how-to step of a built-in exercise in the current language.
    public static func exerciseStep(id: String, index: Int, fallback: String) -> String {
        Bundle.module.localizedString(forKey: "\(id).step.\(index)", value: fallback, table: "ExerciseCatalog")
    }

    /// Formats `0.72` as "72%" with the current locale's spacing and symbol.
    private static func percent(_ fraction: Double) -> String {
        fraction.formatted(.percent.precision(.fractionLength(0)))
    }

    private static func tr(_ key: String, _ args: any CVarArg...) -> String {
        let format = Bundle.module.localizedString(forKey: key, value: nil, table: nil)
        return args.isEmpty ? format : String(format: format, locale: .current, arguments: args)
    }
}
