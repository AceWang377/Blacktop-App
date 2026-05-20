import Foundation
import CoreLocation
import MapKit

@MainActor
final class AppStore: ObservableObject {
    @Published var courts: [Court]
    @Published var filters = CourtFilters()
    @Published var selectedCourt: Court?
    @Published var savedCourtIDs: Set<String>
    @Published var appLanguage: AppLanguage
    #if DEBUG
    @Published var suggestions: [CourtSuggestion] = []
    @Published var courtCandidates: [CourtCandidate] = []
    @Published var isAdminUnlocked: Bool
    #endif
    @Published var hasCompletedOnboarding: Bool
    @Published var courtDataSource = "Local seed"
    @Published var isLoadingRemoteCourts = false
    @Published var countrySummaries: [CountryCourtSummary] = []
    @Published var contributorSession: ContributorSession?
    @Published var communityMessage: String?
    @Published var isSubmittingCommunityUpdate = false
    @Published var vibeSummariesByCourtID: [String: [CourtVibeSummary]] = [:]
    @Published var factVoteSummariesByCourtID: [String: [CourtFactVoteSummary]] = [:]
    @Published var userFactVotesByCourtID: [String: [CourtFactUserVote]] = [:]
    @Published var userVibeVotesByCourtID: [String: [CourtVibeUserVote]] = [:]
    @Published var isSyncingSavedCourts = false

    private let savedKey = "blacktop.savedCourts"
    private let onboardingKey = "blacktop.hasCompletedOnboarding"
    private let languageKey = "blacktop.appLanguage"
    private let maximumCachedCourts = 30_000
    #if DEBUG
    private let courtsKey = "blacktop.courts.override"
    private let adminKey = "blacktop.adminUnlocked"
    private let adminPasscode = "BLACKTOP-ADMIN"
    #endif
    private let supabaseCourtService = SupabaseCourtService()
    private let supabaseCommunityService = SupabaseCommunityService()
    private var loadedRemoteRegions: [MKCoordinateRegion] = []
    private var remoteLoadGeneration = 0
    private var loadedCommunitySignalCourtIDs: Set<String> = []

    init(courts: [Court] = CourtSeedStore.loadCourts()) {
        let cachedCourts = CourtDiskCache.load()
        #if DEBUG
        self.courts = Self.loadPersistedCourts() ?? cachedCourts ?? courts
        self.isAdminUnlocked = UserDefaults.standard.bool(forKey: adminKey)
        #else
        self.courts = cachedCourts ?? courts
        #endif
        let storedLanguage = UserDefaults.standard.string(forKey: languageKey).flatMap(AppLanguage.init(rawValue:))
        self.appLanguage = storedLanguage ?? AppLanguage.preferred
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
        self.courtDataSource = cachedCourts == nil ? "Local seed" : "Cached courts"
        let saved = UserDefaults.standard.stringArray(forKey: savedKey) ?? []
        self.savedCourtIDs = Set(saved)
        self.contributorSession = supabaseCommunityService.restoreSession()
    }

    var filteredCourts: [Court] {
        guard filters.isActive else { return courts }
        return courts
            .compactMap { court -> (court: Court, score: Int)? in
                let evaluation = filterEvaluation(for: court)
                guard evaluation.isIncluded else { return nil }
                return (court, evaluation.score)
            }
            .sorted {
                if $0.score == $1.score {
                    if $0.court.city == $1.court.city {
                        return $0.court.name.localizedCaseInsensitiveCompare($1.court.name) == .orderedAscending
                    }
                    return $0.court.city.localizedCaseInsensitiveCompare($1.court.city) == .orderedAscending
                }
                return $0.score > $1.score
            }
            .map(\.court)
    }

    var savedCourts: [Court] {
        courts.filter { savedCourtIDs.contains($0.id) }
    }

    var totalCourtCount: Int {
        let remoteTotal = countrySummaries.reduce(0) { $0 + $1.courtCount }
        return max(remoteTotal, courts.count)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: onboardingKey)
    }

    func setLanguage(_ language: AppLanguage) {
        appLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: languageKey)
    }

    func toggleSaved(_ court: Court) {
        if savedCourtIDs.contains(court.id) {
            savedCourtIDs.remove(court.id)
        } else {
            savedCourtIDs.insert(court.id)
        }
        persistSavedCourts()

        guard let contributorSession else { return }
        let isSaved = savedCourtIDs.contains(court.id)
        Task {
            await syncRemoteSavedCourt(courtID: court.id, isSaved: isSaved, session: contributorSession)
        }
    }

    func isSaved(_ court: Court) -> Bool {
        savedCourtIDs.contains(court.id)
    }

    func loadRemoteCourts() async {
        remoteLoadGeneration += 1
        let generation = remoteLoadGeneration
        isLoadingRemoteCourts = true
        defer {
            if generation == remoteLoadGeneration {
                isLoadingRemoteCourts = false
            }
        }

        do {
            let remoteCourts = try await supabaseCourtService.fetchCourts()
            guard generation == remoteLoadGeneration else { return }
            guard !remoteCourts.isEmpty else { return }
            courts = remoteCourts
            await loadCommunitySignals(for: remoteCourts)
            courtDataSource = "Supabase"
            selectedCourt = selectedCourt.flatMap { selected in
                remoteCourts.first { $0.id == selected.id }
            }
            persistCourtCache()
            print("Blacktop loaded \(remoteCourts.count) courts from Supabase")
        } catch {
            print("Blacktop Supabase court load failed: \(error)")
        }
    }

    func loadRemoteCourts(in region: MKCoordinateRegion, force: Bool = false) async {
        if !force, hasLoadedRemoteRegion(covering: region) { return }

        remoteLoadGeneration += 1
        let generation = remoteLoadGeneration
        isLoadingRemoteCourts = true
        defer {
            if generation == remoteLoadGeneration {
                isLoadingRemoteCourts = false
            }
        }

        do {
            let remoteCourts = try await supabaseCourtService.fetchCourts(in: region)
            guard generation == remoteLoadGeneration else { return }
            guard !remoteCourts.isEmpty else { return }
            mergeRemoteCourts(remoteCourts)
            await loadCommunitySignals(for: remoteCourts)
            loadedRemoteRegions.append(region.expanded(by: 0.45))
            courtDataSource = "Supabase area"
            selectedCourt = selectedCourt.flatMap { selected in
                courts.first { $0.id == selected.id }
            }
            persistCourtCache()
            print("Blacktop loaded \(remoteCourts.count) courts for current map area")
        } catch {
            print("Blacktop Supabase area load failed: \(error)")
        }
    }

    func loadCountrySummaries(force: Bool = false) async {
        guard force || countrySummaries.isEmpty else { return }

        do {
            countrySummaries = try await supabaseCourtService.fetchCountrySummaries()
        } catch {
            print("Blacktop country summary load failed: \(error)")
        }
    }

    func signInWithApple(identityToken: String, nonce: String) async {
        do {
            contributorSession = try await supabaseCommunityService.signInWithApple(identityToken: identityToken, nonce: nonce)
            communityMessage = localized("Signed in. You can now contribute court facts.", "已登录，可以提交球场信息。")
            await syncSavedCourtsAfterSignIn()
        } catch {
            communityMessage = localized("Sign in failed. Please try again.", "登录失败，请再试一次。")
            print("Blacktop Apple sign in failed: \(error)")
        }
    }

    func signOutContributor() {
        contributorSession = nil
        userFactVotesByCourtID = [:]
        userVibeVotesByCourtID = [:]
        supabaseCommunityService.clearSession()
        communityMessage = localized("Signed out.", "已退出登录。")
    }

    func submitFactVote(for court: Court, draft: CourtFactUpdateDraft) async {
        guard draft.isReady else { return }
        guard let session = await activeContributorSession() else {
            communityMessage = localized("Please sign in with Apple before voting.", "投票前请先使用 Apple 登录。")
            return
        }

        let previousSummaries = factVoteSummariesByCourtID[court.id] ?? []
        let previousUserVotes = userFactVotesByCourtID[court.id] ?? []
        applyOptimisticFactVote(for: court, draft: draft)

        isSubmittingCommunityUpdate = true
        defer { isSubmittingCommunityUpdate = false }

        do {
            try await supabaseCommunityService.submitFactVote(courtID: court.id, draft: draft, session: session)
            communityMessage = localized("Vote saved. Thanks for helping other players.", "投票已保存，谢谢你帮助其他球员。")
            await loadFactVotes(for: court)
        } catch SupabaseCommunityError.missingSession {
            factVoteSummariesByCourtID[court.id] = previousSummaries
            userFactVotesByCourtID[court.id] = previousUserVotes
            communityMessage = localized("Please sign in with Apple before voting.", "投票前请先使用 Apple 登录。")
        } catch {
            factVoteSummariesByCourtID[court.id] = previousSummaries
            userFactVotesByCourtID[court.id] = previousUserVotes
            communityMessage = localized("Could not save this vote. Please try again.", "暂时无法保存投票，请稍后再试。")
            print("Blacktop fact vote failed: \(error)")
        }
    }

    func loadFactVotes(for court: Court) async {
        do {
            let session = await activeContributorSession()
            factVoteSummariesByCourtID[court.id] = try await supabaseCommunityService.fetchFactVoteSummaries(courtID: court.id)
            userFactVotesByCourtID[court.id] = try await supabaseCommunityService.fetchUserFactVotes(courtID: court.id, session: session)
        } catch {
            print("Blacktop fact vote summary load failed: \(error)")
        }
    }

    func loadVibeSummaries(for court: Court) async {
        do {
            let session = await activeContributorSession()
            vibeSummariesByCourtID[court.id] = try await supabaseCommunityService.fetchVibeSummaries(courtID: court.id)
            userVibeVotesByCourtID[court.id] = try await supabaseCommunityService.fetchUserVibeVotes(courtID: court.id, session: session)
        } catch {
            print("Blacktop vibe summary load failed: \(error)")
        }
    }

    func submitVibeVote(for court: Court, category: CourtVibeCategory, option: CourtVibeOption) async {
        guard let session = await activeContributorSession() else {
            communityMessage = localized("Please sign in with Apple before voting.", "投票前请先使用 Apple 登录。")
            return
        }

        let previousSummaries = vibeSummariesByCourtID[court.id] ?? []
        let previousUserVotes = userVibeVotesByCourtID[court.id] ?? []
        applyOptimisticVibeVote(for: court, category: category, option: option)

        isSubmittingCommunityUpdate = true
        defer { isSubmittingCommunityUpdate = false }

        do {
            try await supabaseCommunityService.submitVibeVote(courtID: court.id, category: category, option: option, session: session)
            communityMessage = localized("Vote saved. Court vibe updated.", "投票已保存，球场氛围已更新。")
            await loadVibeSummaries(for: court)
        } catch SupabaseCommunityError.missingSession {
            vibeSummariesByCourtID[court.id] = previousSummaries
            userVibeVotesByCourtID[court.id] = previousUserVotes
            communityMessage = localized("Please sign in with Apple before voting.", "投票前请先使用 Apple 登录。")
        } catch {
            vibeSummariesByCourtID[court.id] = previousSummaries
            userVibeVotesByCourtID[court.id] = previousUserVotes
            communityMessage = localized("Could not save this vote. Please try again.", "暂时无法保存投票，请稍后再试。")
            print("Blacktop vibe vote failed: \(error)")
        }
    }

    func filterSortScore(for court: Court) -> Int {
        filterEvaluation(for: court).score
    }

    private func persistSavedCourts() {
        UserDefaults.standard.set(Array(savedCourtIDs), forKey: savedKey)
    }

    private func syncRemoteSavedCourt(courtID: String, isSaved: Bool, session: ContributorSession) async {
        do {
            if isSaved {
                try await supabaseCommunityService.saveCourt(courtID: courtID, session: session)
            } else {
                try await supabaseCommunityService.removeSavedCourt(courtID: courtID, session: session)
            }
        } catch {
            print("Blacktop saved court sync failed: \(error)")
        }
    }

    private func syncSavedCourtsAfterSignIn() async {
        guard let contributorSession else { return }
        isSyncingSavedCourts = true
        defer { isSyncingSavedCourts = false }

        do {
            savedCourtIDs = try await supabaseCommunityService.syncSavedCourtIDs(savedCourtIDs, session: contributorSession)
            persistSavedCourts()
            communityMessage = localized("Signed in. Saved courts are synced.", "已登录，收藏球场已同步。")
        } catch {
            communityMessage = localized("Signed in. Saved courts will sync later.", "已登录，收藏球场稍后同步。")
            print("Blacktop saved court merge failed: \(error)")
        }
    }

    private func loadCommunitySignals(for courts: [Court]) async {
        let idsToLoad = courts
            .map(\.id)
            .filter { !loadedCommunitySignalCourtIDs.contains($0) }
        guard !idsToLoad.isEmpty else { return }

        do {
            async let factSummaries = supabaseCommunityService.fetchFactVoteSummaries(courtIDs: idsToLoad)
            async let vibeSummaries = supabaseCommunityService.fetchVibeSummaries(courtIDs: idsToLoad)
            let loadedFacts = try await factSummaries
            let loadedVibes = try await vibeSummaries

            for (courtID, summaries) in Dictionary(grouping: loadedFacts, by: \.courtID) {
                factVoteSummariesByCourtID[courtID] = summaries
            }
            for (courtID, summaries) in Dictionary(grouping: loadedVibes, by: \.courtID) {
                vibeSummariesByCourtID[courtID] = summaries
            }
            loadedCommunitySignalCourtIDs.formUnion(idsToLoad)
        } catch {
            print("Blacktop community signal load failed: \(error)")
        }
    }

    private func activeContributorSession() async -> ContributorSession? {
        guard let session = contributorSession else { return nil }
        guard session.isExpired else { return session }

        do {
            let refreshedSession = try await supabaseCommunityService.refreshSession(session)
            contributorSession = refreshedSession
            return refreshedSession
        } catch {
            contributorSession = nil
            userFactVotesByCourtID = [:]
            userVibeVotesByCourtID = [:]
            supabaseCommunityService.clearSession()
            communityMessage = localized("Your session expired. Please sign in again.", "登录已过期，请重新登录。")
            print("Blacktop session refresh failed: \(error)")
            return nil
        }
    }

    private func applyOptimisticFactVote(for court: Court, draft: CourtFactUpdateDraft) {
        guard let newValue = draft.value else { return }

        let oldVote = userFactVotesByCourtID[court.id]?.first { $0.field == draft.field }
        if oldVote?.value == newValue { return }

        var userVotes = userFactVotesByCourtID[court.id] ?? []
        userVotes.removeAll { $0.field == draft.field }
        userVotes.append(CourtFactUserVote(courtID: court.id, field: draft.field, value: newValue))
        userFactVotesByCourtID[court.id] = userVotes.sorted { $0.field.rawValue < $1.field.rawValue }

        var summaries = factVoteSummariesByCourtID[court.id] ?? []
        summaries = adjustFactSummaries(
            summaries,
            courtID: court.id,
            field: draft.field,
            oldValue: oldVote?.value,
            newValue: newValue
        )
        factVoteSummariesByCourtID[court.id] = summaries
    }

    private func adjustFactSummaries(
        _ summaries: [CourtFactVoteSummary],
        courtID: String,
        field: CommunityFactField,
        oldValue: String?,
        newValue: String
    ) -> [CourtFactVoteSummary] {
        var summaries = summaries
        let oldFieldTotal = summaries.first { $0.field == field }?.fieldTotal ?? 0
        let newFieldTotal = oldValue == nil ? oldFieldTotal + 1 : oldFieldTotal

        if let oldValue {
            if let oldIndex = summaries.firstIndex(where: { $0.field == field && $0.value == oldValue }) {
                summaries[oldIndex].voteCount = max(0, summaries[oldIndex].voteCount - 1)
            }
        }

        if let newIndex = summaries.firstIndex(where: { $0.field == field && $0.value == newValue }) {
            summaries[newIndex].voteCount += 1
        } else {
            summaries.append(CourtFactVoteSummary(
                courtID: courtID,
                field: field,
                value: newValue,
                voteCount: 1,
                fieldTotal: newFieldTotal,
                percentage: 100
            ))
        }

        return summaries
            .filter { $0.field != field || $0.voteCount > 0 }
            .map { summary in
                guard summary.field == field else { return summary }
                var updated = summary
                updated.fieldTotal = newFieldTotal
                updated.percentage = Self.percentage(count: updated.voteCount, total: newFieldTotal)
                return updated
            }
    }

    private func applyOptimisticVibeVote(for court: Court, category: CourtVibeCategory, option: CourtVibeOption) {
        let oldVote = userVibeVotesByCourtID[court.id]?.first { $0.category == category }
        if oldVote?.option == option { return }

        var userVotes = userVibeVotesByCourtID[court.id] ?? []
        userVotes.removeAll { $0.category == category }
        userVotes.append(CourtVibeUserVote(courtID: court.id, category: category, option: option))
        userVibeVotesByCourtID[court.id] = userVotes.sorted { $0.category.rawValue < $1.category.rawValue }

        var summaries = vibeSummariesByCourtID[court.id] ?? []
        summaries = adjustVibeSummaries(
            summaries,
            courtID: court.id,
            category: category,
            oldOption: oldVote?.option,
            newOption: option
        )
        vibeSummariesByCourtID[court.id] = summaries
    }

    private func adjustVibeSummaries(
        _ summaries: [CourtVibeSummary],
        courtID: String,
        category: CourtVibeCategory,
        oldOption: CourtVibeOption?,
        newOption: CourtVibeOption
    ) -> [CourtVibeSummary] {
        var summaries = summaries
        let oldCategoryTotal = summaries.first { $0.category == category }?.categoryTotal ?? 0
        let newCategoryTotal = oldOption == nil ? oldCategoryTotal + 1 : oldCategoryTotal

        if let oldOption {
            if let oldIndex = summaries.firstIndex(where: { $0.category == category && $0.option == oldOption }) {
                summaries[oldIndex].voteCount = max(0, summaries[oldIndex].voteCount - 1)
            }
        }

        if let newIndex = summaries.firstIndex(where: { $0.category == category && $0.option == newOption }) {
            summaries[newIndex].voteCount += 1
        } else {
            summaries.append(CourtVibeSummary(
                courtID: courtID,
                category: category,
                option: newOption,
                voteCount: 1,
                categoryTotal: newCategoryTotal,
                percentage: 100
            ))
        }

        return summaries
            .filter { $0.category != category || $0.voteCount > 0 }
            .map { summary in
                guard summary.category == category else { return summary }
                var updated = summary
                updated.categoryTotal = newCategoryTotal
                updated.percentage = Self.percentage(count: updated.voteCount, total: newCategoryTotal)
                return updated
            }
    }

    private static func percentage(count: Int, total: Int) -> Int {
        guard total > 0 else { return 0 }
        return Int((Double(count) / Double(total) * 100).rounded())
    }

    private struct FilterEvaluation {
        var isIncluded: Bool
        var score: Int
    }

    private enum FilterConditionResult {
        case match(Int)
        case unknown
        case excluded
    }

    private func filterEvaluation(for court: Court) -> FilterEvaluation {
        guard filters.isActive else {
            return FilterEvaluation(isIncluded: true, score: 0)
        }

        var score = 0
        for result in filterConditionResults(for: court) {
            switch result {
            case .match(let value):
                score += value
            case .unknown:
                score += 1
            case .excluded:
                return FilterEvaluation(isIncluded: false, score: 0)
            }
        }

        return FilterEvaluation(isIncluded: true, score: score)
    }

    private func filterConditionResults(for court: Court) -> [FilterConditionResult] {
        var results: [FilterConditionResult] = []

        if filters.outdoor || filters.indoor {
            var desiredValues: Set<String> = []
            if filters.outdoor { desiredValues.insert("outdoor") }
            if filters.indoor { desiredValues.insert("indoor") }
            results.append(evaluateFactFilter(
                courtID: court.id,
                field: .courtType,
                desiredValues: desiredValues,
                staticValue: court.courtType.rawValue,
                staticUnknown: court.courtType == .unknown,
                staticMatch: court.courtType == .mixed || desiredValues.contains(court.courtType.rawValue)
            ))
        }

        if filters.free {
            results.append(evaluateFactFilter(
                courtID: court.id,
                field: .priceType,
                desiredValues: ["free"],
                staticValue: court.priceType.rawValue,
                staticUnknown: court.priceType == .unknown,
                staticMatch: court.priceType == .free
            ))
        }

        if filters.lights {
            results.append(evaluateFactFilter(
                courtID: court.id,
                field: .hasLights,
                desiredValues: ["yes"],
                staticValue: court.hasLights.rawValue,
                staticUnknown: court.hasLights == .unknown,
                staticMatch: court.hasLights == .yes
            ))
        }

        if filters.dryAfterRain {
            results.append(evaluateFactFilter(
                courtID: court.id,
                field: .drynessAfterRain,
                desiredValues: ["driesFast", "indoorUnaffected"],
                staticValue: court.drynessAfterRain.rawValue,
                staticUnknown: court.drynessAfterRain == .unknown,
                staticMatch: court.drynessAfterRain == .driesFast || court.drynessAfterRain == .indoorUnaffected
            ))
        }

        if filters.nets {
            results.append(evaluateFactFilter(
                courtID: court.id,
                field: .hasNets,
                desiredValues: ["all", "some"],
                staticValue: court.hasNets.rawValue,
                staticUnknown: court.hasNets == .unknown,
                staticMatch: court.hasNets == .all || court.hasNets == .some
            ))
        }

        if filters.standardRim {
            results.append(evaluateFactFilter(
                courtID: court.id,
                field: .rimHeight,
                desiredValues: ["standard"],
                staticValue: court.rimHeight.rawValue,
                staticUnknown: court.rimHeight == .unknown,
                staticMatch: court.rimHeight == .standard
            ))
        }

        if filters.solo {
            results.append(evaluateVibeFilter(
                courtID: court.id,
                category: .bestFor,
                desiredOptions: [.soloShooting],
                staticUnknown: court.goodForSolo == .unknown,
                staticMatch: court.goodForSolo == .yes
            ))
        }

        return results
    }

    private func evaluateFactFilter(
        courtID: String,
        field: CommunityFactField,
        desiredValues: Set<String>,
        staticValue: String,
        staticUnknown: Bool,
        staticMatch: Bool
    ) -> FilterConditionResult {
        let fieldSummaries = (factVoteSummariesByCourtID[courtID] ?? []).filter { $0.field == field }
        if !fieldSummaries.isEmpty {
            let maxVotes = fieldSummaries.map(\.voteCount).max() ?? 0
            let winningDesiredVotes = fieldSummaries
                .filter { desiredValues.contains($0.value) && $0.voteCount == maxVotes }
                .map(\.voteCount)
                .max()

            if let winningDesiredVotes {
                return .match(40 + winningDesiredVotes)
            }
            return .excluded
        }

        if staticMatch {
            return .match(12)
        }
        if staticUnknown || staticValue == "unknown" {
            return .unknown
        }
        return .excluded
    }

    private func evaluateVibeFilter(
        courtID: String,
        category: CourtVibeCategory,
        desiredOptions: Set<CourtVibeOption>,
        staticUnknown: Bool,
        staticMatch: Bool
    ) -> FilterConditionResult {
        let categorySummaries = (vibeSummariesByCourtID[courtID] ?? []).filter { $0.category == category }
        if !categorySummaries.isEmpty {
            let maxVotes = categorySummaries.map(\.voteCount).max() ?? 0
            let winningDesiredVotes = categorySummaries
                .filter { desiredOptions.contains($0.option) && $0.voteCount == maxVotes }
                .map(\.voteCount)
                .max()

            if let winningDesiredVotes {
                return .match(40 + winningDesiredVotes)
            }
            return .excluded
        }

        if staticMatch {
            return .match(12)
        }
        if staticUnknown {
            return .unknown
        }
        return .excluded
    }

    private func mergeRemoteCourts(_ remoteCourts: [Court]) {
        var merged = Dictionary(uniqueKeysWithValues: courts.map { ($0.id, $0) })
        for court in remoteCourts {
            merged[court.id] = court
        }
        courts = merged.values.sorted {
            if $0.city == $1.city { return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            return $0.city.localizedCaseInsensitiveCompare($1.city) == .orderedAscending
        }
    }

    private func persistCourtCache() {
        let snapshot = Array(courts.prefix(maximumCachedCourts))
        Task.detached(priority: .utility) {
            CourtDiskCache.save(snapshot)
        }
    }

    private func hasLoadedRemoteRegion(covering region: MKCoordinateRegion) -> Bool {
        loadedRemoteRegions.contains { loadedRegion in
            loadedRegion.contains(region.center) &&
                loadedRegion.span.latitudeDelta >= region.span.latitudeDelta * 0.70 &&
                loadedRegion.span.longitudeDelta >= region.span.longitudeDelta * 0.70
        }
    }

    #if DEBUG
    func addSuggestion(_ suggestion: CourtSuggestion) {
        suggestions.insert(suggestion, at: 0)
    }

    func updateCourt(_ court: Court) {
        guard let index = courts.firstIndex(where: { $0.id == court.id }) else { return }
        courts[index] = court
        persistCourts()
    }

    func addApprovedCourt(_ court: Court) {
        courts.insert(court, at: 0)
        persistCourts()
    }

    func resetCourtsToSeed() {
        courts = CourtSeedStore.loadCourts()
        UserDefaults.standard.removeObject(forKey: courtsKey)
    }

    func unlockAdmin(passcode: String) -> Bool {
        let didUnlock = passcode.trimmingCharacters(in: .whitespacesAndNewlines) == adminPasscode
        if didUnlock {
            isAdminUnlocked = true
            UserDefaults.standard.set(true, forKey: adminKey)
        }
        return didUnlock
    }

    func lockAdmin() {
        isAdminUnlocked = false
        UserDefaults.standard.set(false, forKey: adminKey)
    }

    func submitCourtCandidate(name: String, area: String, latitude: Double, longitude: Double, courtType: CourtType) {
        courtCandidates.insert(
            CourtCandidate(
                name: name.isEmpty ? "Unnamed court candidate" : name,
                area: area.isEmpty ? "Area pending" : area,
                latitude: latitude,
                longitude: longitude,
                courtType: courtType
            ),
            at: 0
        )
    }

    private func persistCourts() {
        guard let data = try? JSONEncoder().encode(courts) else { return }
        UserDefaults.standard.set(data, forKey: courtsKey)
    }

    private static func loadPersistedCourts() -> [Court]? {
        guard let data = UserDefaults.standard.data(forKey: "blacktop.courts.override") else { return nil }
        return try? JSONDecoder().decode([Court].self, from: data)
    }
    #endif
}

private enum CourtDiskCache {
    private static let fileName = "blacktop-courts-cache-v1.json"
    private static let maxAge: TimeInterval = 60 * 60 * 24 * 14

    static func load() -> [Court]? {
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        guard let payload = try? JSONDecoder().decode(Payload.self, from: data) else { return nil }
        guard Date().timeIntervalSince1970 - payload.cachedAt < maxAge else { return nil }
        return payload.courts.isEmpty ? nil : payload.courts
    }

    static func save(_ courts: [Court]) {
        guard !courts.isEmpty else { return }
        let payload = Payload(cachedAt: Date().timeIntervalSince1970, courts: courts)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        try? FileManager.default.createDirectory(
            at: cacheURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? data.write(to: cacheURL, options: [.atomic])
    }

    private static var cacheURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appending(path: fileName)
    }

    private struct Payload: Codable {
        var cachedAt: TimeInterval
        var courts: [Court]
    }
}

#if DEBUG
struct CourtCandidate: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var area: String
    var latitude: Double
    var longitude: Double
    var courtType: CourtType
    var submittedAt = Date()
}
#endif

private extension MKCoordinateRegion {
    func expanded(by ratio: Double) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(
                latitudeDelta: span.latitudeDelta * (1 + ratio),
                longitudeDelta: span.longitudeDelta * (1 + ratio)
            )
        )
    }

    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let minLatitude = center.latitude - span.latitudeDelta / 2
        let maxLatitude = center.latitude + span.latitudeDelta / 2
        let minLongitude = center.longitude - span.longitudeDelta / 2
        let maxLongitude = center.longitude + span.longitudeDelta / 2

        return coordinate.latitude >= minLatitude &&
            coordinate.latitude <= maxLatitude &&
            coordinate.longitude >= minLongitude &&
            coordinate.longitude <= maxLongitude
    }
}
