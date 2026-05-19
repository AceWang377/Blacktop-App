import SwiftUI
import MapKit
import CoreLocation

struct CourtMapView: View {
    @EnvironmentObject private var store: AppStore
    @StateObject private var locationManager = BlacktopLocationManager()
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 53.3811, longitude: -1.4701),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    )
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 53.3811, longitude: -1.4701),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )
    @State private var searchRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 53.3811, longitude: -1.4701),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )
    @State private var searchText = ""
    @State private var isSearchingCity = false
    @State private var showingFilters = false
    @State private var showingDetail = false
    @State private var hasStartedInitialLoad = false
    @State private var isChromeVisible = false
    @State private var pendingMapLoadTask: Task<Void, Never>?
    @State private var searchResultMessage: String?
    @FocusState private var isSearchFocused: Bool

    private let maximumQueryableLatitudeDelta = 1.6
    private let maximumQueryableLongitudeDelta = 1.9

    private var isMapRegionQueryable: Bool {
        isQueryable(mapRegion)
    }

    private var visibleCourts: [Court] {
        let filtered = store.filteredCourts
        let query = normalizedSearchText
        guard !query.isEmpty else { return filtered }
        let matches = matchingCourts(for: query, in: filtered)
        return matches.isEmpty ? filtered : matches
    }

    private var areaCourtCount: Int {
        guard isMapRegionQueryable else { return 0 }
        return visibleCourts.filter { mapRegion.contains($0.coordinate, padding: 0.18) }.count
    }

    private var areaCourtCountLabel: String {
        isMapRegionQueryable ? "\(areaCourtCount)" : "..."
    }

    private var shouldShowSearchAreaButton: Bool {
        false
    }

    private var countrySummaryPins: [CountryCourtSummary] {
        guard !isMapRegionQueryable else { return [] }
        return store.countrySummaries
            .filter { mapRegion.contains($0.coordinate, padding: 0.70) }
            .sorted { $0.courtCount > $1.courtCount }
            .prefix(48)
            .map(\.self)
    }

    private var mapCourts: [Court] {
        guard isMapRegionQueryable else {
            if let selectedCourt = store.selectedCourt, mapRegion.contains(selectedCourt.coordinate, padding: 0.18) {
                return [selectedCourt]
            }
            return []
        }

        let regionCourts = visibleCourts
            .filter { mapRegion.contains($0.coordinate, padding: 0.18) }
            .sorted {
                mapRegion.center.distance(to: $0.coordinate) < mapRegion.center.distance(to: $1.coordinate)
            }

        var courts = Array(regionCourts.prefix(360))
        if let selectedCourt = store.selectedCourt, !courts.contains(where: { $0.id == selectedCourt.id }) {
            courts.append(selectedCourt)
        }
        return courts
    }

    var body: some View {
        ZStack {
            Map(position: $cameraPosition, interactionModes: .all) {
                ForEach(countrySummaryPins) { summary in
                    Annotation("", coordinate: summary.coordinate) {
                        Button {
                            HLHaptics.selection()
                            focusMap(on: summary)
                        } label: {
                            CountrySummaryPin(summary: summary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                ForEach(mapCourts) { court in
                    Annotation("", coordinate: court.coordinate) {
                        Button {
                            HLHaptics.selection()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.84)) {
                                store.selectedCourt = court
                                focusMap(on: court)
                            }
                        } label: {
                            CourtPin(court: court, isSelected: store.selectedCourt?.id == court.id, isSaved: store.isSaved(court))
                        }
                        .buttonStyle(.plain)
                    }
                }

                UserAnnotation()
            }
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .including([.park, .publicTransport, .school])))
            .onMapCameraChange(frequency: .onEnd) { context in
                handleMapCameraEnd(context.region)
            }
            .ignoresSafeArea()

            LinearGradient(
                colors: [.black.opacity(0.32), .clear, .clear, .black.opacity(0.20)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                topControlStack
                Spacer()
                bottomSurface
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 88)
            .opacity(isChromeVisible ? 1 : 0)
            .offset(y: isChromeVisible ? 0 : -10)
            .animation(.smooth(duration: 0.42), value: isChromeVisible)
        }
        .sheet(isPresented: $showingFilters) {
            FilterSheetView()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingDetail) {
            if let court = store.selectedCourt {
                CourtDetailView(court: court)
            }
        }
        .onReceive(locationManager.$lastLocation.compactMap { $0 }) { coordinate in
            let region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
            )
            withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
                cameraPosition = .region(region)
                mapRegion = region
                searchRegion = region
            }
            Task {
                await store.loadRemoteCourts(in: region, force: true)
            }
        }
        .task {
            guard !hasStartedInitialLoad else { return }
            hasStartedInitialLoad = true
            try? await Task.sleep(for: .milliseconds(850))
            withAnimation(.smooth(duration: 0.42)) {
                isChromeVisible = true
            }
            Task {
                await store.loadCountrySummaries()
            }
            await loadRemoteCourtsIfQueryable(in: mapRegion, force: false)
        }
        .onDisappear {
            pendingMapLoadTask?.cancel()
        }
    }

    private var topControlStack: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                brandPill
                Spacer()
                Button {
                    locateUser()
                } label: {
                    Image(systemName: locationManager.isLocating ? "location.fill" : "location")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(locationManager.lastLocation == nil ? .white : HLColor.night)
                        .frame(width: 48, height: 48)
                        .background(locationManager.lastLocation == nil ? .black.opacity(0.54) : HLColor.freshGreen)
                        .clipShape(Circle())
                        .overlay {
                            Circle().stroke(.white.opacity(0.13), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(store.localized("Use current location", "定位到当前位置"))

                Button {
                    HLHaptics.light()
                    showingFilters = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(store.filters.isActive ? HLColor.night : .white)
                        .frame(width: 48, height: 48)
                        .background(store.filters.isActive ? HLColor.freshGreen : .black.opacity(0.54))
                        .clipShape(Circle())
                        .overlay {
                            Circle().stroke(.white.opacity(0.13), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(store.copy(.filters))
            }

            searchBar
            searchAreaButton
            searchResultPill
            mapScaleHintPill
            filterChips
        }
    }

    private var brandPill: some View {
        HStack(spacing: 8) {
            Image("BlacktopSplashMark")
                .resizable()
                .scaledToFill()
                .frame(width: 28, height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text("Blacktop")
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
            Text(areaCourtCountLabel)
                .font(.caption.weight(.black))
                .foregroundStyle(HLColor.night)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(HLColor.freshGreen)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(.black.opacity(0.58))
        .clipShape(Capsule())
        .overlay {
            Capsule().stroke(.white.opacity(0.13), lineWidth: 1)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.64))
            TextField(store.copy(.searchPlaceholder), text: $searchText)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .foregroundStyle(.white)
                .tint(HLColor.freshGreen)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit {
                    Task {
                        await submitSearch()
                    }
                }
            if isSearchingCity {
                ProgressView()
                    .tint(HLColor.freshGreen)
                    .controlSize(.small)
            }
            if !searchText.isEmpty {
                Button {
                    HLHaptics.light()
                    searchText = ""
                    searchResultMessage = nil
                    store.selectedCourt = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.72))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(store.localized("Close court card", "关闭球场卡片"))
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(.black.opacity(0.54))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.13), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var searchResultPill: some View {
        if let searchResultMessage {
            Label(searchResultMessage, systemImage: "scope")
                .font(.caption.weight(.black))
                .foregroundStyle(HLColor.night)
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background(HLColor.freshGreen)
                .clipShape(Capsule())
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                MapFilterChip(label: store.copy(.outdoor), isSelected: store.filters.outdoor) { toggleFilter { store.filters.outdoor.toggle() } }
                MapFilterChip(label: store.copy(.indoor), isSelected: store.filters.indoor) { toggleFilter { store.filters.indoor.toggle() } }
                MapFilterChip(label: store.copy(.free), isSelected: store.filters.free) { toggleFilter { store.filters.free.toggle() } }
                MapFilterChip(label: store.copy(.lights), isSelected: store.filters.lights) { toggleFilter { store.filters.lights.toggle() } }
                MapFilterChip(label: store.copy(.dry), isSelected: store.filters.dryAfterRain) { toggleFilter { store.filters.dryAfterRain.toggle() } }
                MapFilterChip(label: store.copy(.nets), isSelected: store.filters.nets) { toggleFilter { store.filters.nets.toggle() } }
                MapFilterChip(label: store.copy(.standardRim), isSelected: store.filters.standardRim) { toggleFilter { store.filters.standardRim.toggle() } }
            }
            .padding(.trailing, 20)
        }
    }

    @ViewBuilder
    private var searchAreaButton: some View {
        if shouldShowSearchAreaButton {
            Button {
                HLHaptics.selection()
                Task {
                    await loadCurrentMapArea(force: true)
                }
            } label: {
                HStack(spacing: 8) {
                    if store.isLoadingRemoteCourts {
                        ProgressView()
                            .tint(HLColor.night)
                            .controlSize(.small)
                    } else {
                        Image(systemName: "scope")
                    }
                    Text(store.copy(.searchThisArea))
                }
                .font(.caption.weight(.black))
                .foregroundStyle(HLColor.night)
                .padding(.horizontal, 14)
                .frame(height: 36)
                .background(HLColor.freshGreen)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(store.isLoadingRemoteCourts)
        }
    }

    @ViewBuilder
    private var mapScaleHintPill: some View {
        if !isMapRegionQueryable {
            Label(mapScaleHintText, systemImage: "plus.magnifyingglass")
                .font(.caption.weight(.black))
                .foregroundStyle(.white.opacity(0.84))
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background(.black.opacity(0.46))
                .clipShape(Capsule())
                .overlay {
                    Capsule().stroke(.white.opacity(0.12), lineWidth: 1)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
        }
    }

    private var bottomSurface: some View {
        Group {
            if let court = store.selectedCourt {
                selectedCourtCard(court)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.88), value: store.selectedCourt?.id)
    }

    private func selectedCourtCard(_ court: Court) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(court.name)
                        .font(.title2.weight(.black))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text(court.area)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.58))
                        .lineLimit(1)
                }
                Spacer()
                Button {
                    HLHaptics.light()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
                        store.selectedCourt = nil
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(.white.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            FlowLayout(spacing: 8) {
                ForEach(court.topFacts(language: store.appLanguage)) { fact in
                    FactChip(label: fact.label, tone: fact.tone)
                }
            }

            Text(warningText(for: court))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.70))

            Button(store.copy(.details)) {
                HLHaptics.light()
                showingDetail = true
            }
            .buttonStyle(DarkPrimaryButtonStyle())

            Button(store.copy(.directions)) {
                    HLHaptics.medium()
                    openDirections(to: court)
            }
            .buttonStyle(DarkSecondaryButtonStyle())
        }
        .padding(16)
        .background(.black.opacity(0.62))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.13), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.25), radius: 24, y: 10)
    }

    private func warningText(for court: Court) -> String {
        if court.drynessAfterRain == .slowToDry || court.drynessAfterRain == .puddlesCommon {
            return store.copy(.rainWarning)
        }
        if court.hasNets == .unknown || court.rimHeight == .unknown {
            return store.copy(.rimNetWarning)
        }
        return store.copy(.readyWarning)
    }

    private func openDirections(to court: Court) {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: court.coordinate))
        item.name = court.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }

    private func toggleFilter(_ update: () -> Void) {
        HLHaptics.selection()
        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            update()
            store.selectedCourt = nil
        }
    }

    @MainActor
    private func submitSearch() async {
        isSearchFocused = false
        let query = normalizedSearchText
        guard !query.isEmpty else { return }

        await store.loadCountrySummaries()
        if let summary = matchingCountrySummary(for: query) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                searchText = ""
                searchResultMessage = "\(summary.displayName) · \(summary.countLabel)"
                focusMap(on: summary)
            }
            await loadRemoteCourtsIfQueryable(in: mapRegion, force: true)
            return
        }

        let filtered = store.filteredCourts
        let matches = matchingCourts(for: query, in: filtered)
        let cityMatches = cityMatchingCourts(for: query, in: filtered)
        if let region = MKCoordinateRegion.enclosing(cityMatches.map(\.coordinate)) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                cameraPosition = .region(region)
                mapRegion = region
                searchRegion = region
                store.selectedCourt = nil
            }
            await loadRemoteCourtsIfQueryable(in: region, force: true)
            searchResultMessage = store.localized("\(cityMatches.count) courts found", "找到 \(cityMatches.count) 个球场")
            return
        }

        let exactMatches = exactCourtNameMatches(for: query, in: filtered)
        if let region = MKCoordinateRegion.enclosing(exactMatches.map(\.coordinate)) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                cameraPosition = .region(region)
                mapRegion = region
                searchRegion = region
                store.selectedCourt = exactMatches.count == 1 ? exactMatches[0] : nil
            }
            await loadRemoteCourtsIfQueryable(in: region, force: true)
            searchResultMessage = store.localized("\(exactMatches.count) court found", "找到 \(exactMatches.count) 个球场")
            return
        }

        isSearchingCity = true
        defer { isSearchingCity = false }

        if let region = await geocodeRegion(for: searchText) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                searchText = ""
                cameraPosition = .region(region)
                mapRegion = region
                searchRegion = region
                store.selectedCourt = nil
            }
            await loadRemoteCourtsIfQueryable(in: region, force: true)
            searchResultMessage = store.localized("Showing courts near \(query)", "正在显示 \(query) 附近球场")
            return
        }

        if let region = MKCoordinateRegion.enclosing(matches.map(\.coordinate)) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                cameraPosition = .region(region)
                mapRegion = region
                searchRegion = region
                store.selectedCourt = nil
            }
            await loadRemoteCourtsIfQueryable(in: region, force: true)
            searchResultMessage = store.localized("\(matches.count) courts found", "找到 \(matches.count) 个球场")
        } else {
            searchResultMessage = store.localized("No courts found nearby", "附近未找到球场")
        }
    }

    @MainActor
    private func loadCurrentMapArea(force: Bool) async {
        let region = mapRegion
        guard isQueryable(region) else { return }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            searchRegion = region
            searchText = ""
            searchResultMessage = store.localized("Showing this map area", "正在显示当前地图区域")
            store.selectedCourt = nil
        }
        await loadRemoteCourtsIfQueryable(in: region, force: force)
    }

    private func loadRemoteCourtsIfQueryable(in region: MKCoordinateRegion, force: Bool) async {
        guard isQueryable(region) else { return }
        await store.loadRemoteCourts(in: region, force: force)
    }

    private var mapScaleHintText: String {
        switch store.appLanguage {
        case .english: "Tap a country or zoom in"
        case .simplifiedChinese: "点击国家或放大地图"
        }
    }

    @MainActor
    private func handleMapCameraEnd(_ region: MKCoordinateRegion) {
        mapRegion = region
        guard isQueryable(region) else {
            pendingMapLoadTask?.cancel()
            searchResultMessage = nil
            return
        }
        scheduleAutomaticAreaLoad(for: region)
    }

    @MainActor
    private func scheduleAutomaticAreaLoad(for region: MKCoordinateRegion) {
        pendingMapLoadTask?.cancel()
        pendingMapLoadTask = Task {
            try? await Task.sleep(for: .milliseconds(650))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                searchRegion = region
            }
            await loadRemoteCourtsIfQueryable(in: region, force: false)
        }
    }

    private func isQueryable(_ region: MKCoordinateRegion) -> Bool {
        region.span.latitudeDelta <= maximumQueryableLatitudeDelta &&
            region.span.longitudeDelta <= maximumQueryableLongitudeDelta
    }

    private var normalizedSearchText: String {
        normalize(searchText)
    }

    private func matchingCourts(for query: String, in courts: [Court]) -> [Court] {
        let cityMatches = cityMatchingCourts(for: query, in: courts)
        if !cityMatches.isEmpty { return cityMatches }

        let areaMatches = courts.filter { normalize($0.area).contains(query) }
        if !areaMatches.isEmpty { return areaMatches }

        return courts.filter { normalize($0.name).contains(query) }
    }

    private func cityMatchingCourts(for query: String, in courts: [Court]) -> [Court] {
        let exactCityMatches = courts.filter { normalize($0.city) == query }
        if !exactCityMatches.isEmpty { return exactCityMatches }

        return courts.filter { normalize($0.city).contains(query) }
    }

    private func exactCourtNameMatches(for query: String, in courts: [Court]) -> [Court] {
        courts.filter { normalize($0.name) == query }
    }

    private func matchingCountrySummary(for query: String) -> CountryCourtSummary? {
        store.countrySummaries.first { summary in
            normalize(summary.countryCode) == query ||
                normalize(summary.displayName) == query ||
                normalize(summary.displayName).contains(query)
        }
    }

    private func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    private func geocodeRegion(for query: String) async -> MKCoordinateRegion? {
        let geocoder = CLGeocoder()
        let searchTerms = [
            query,
            "\(query), United Kingdom"
        ]

        for term in searchTerms {
            if let placemark = try? await geocoder.geocodeAddressString(term).first,
               let region = placemark.mapRegion {
                return region
            }
        }

        return nil
    }

    private func focusMap(on court: Court) {
        let region = MKCoordinateRegion(
            center: court.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.028, longitudeDelta: 0.028)
        )
        cameraPosition = .region(region)
        mapRegion = region
        searchRegion = region
    }

    private func focusMap(on summary: CountryCourtSummary) {
        let latitudeDelta = min(max((summary.maxLat - summary.minLat) * 0.35, 0.42), maximumQueryableLatitudeDelta * 0.92)
        let longitudeDelta = min(max((summary.maxLng - summary.minLng) * 0.35, 0.42), maximumQueryableLongitudeDelta * 0.92)
        let region = MKCoordinateRegion(
            center: summary.coordinate,
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        )

        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
            cameraPosition = .region(region)
            mapRegion = region
            searchRegion = region
            store.selectedCourt = nil
        }

        scheduleAutomaticAreaLoad(for: region)
    }

    private func locateUser() {
        HLHaptics.light()
        locationManager.requestLocation()
    }

}

final class BlacktopLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var lastLocation: CLLocationCoordinate2D?
    @Published var isLocating = false

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        isLocating = true
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            isLocating = false
        @unknown default:
            isLocating = false
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestLocation()
        } else if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            isLocating = false
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last?.coordinate
        isLocating = false
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLocating = false
    }
}

struct MapFilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.black))
                .foregroundStyle(isSelected ? HLColor.night : .white)
                .padding(.horizontal, 13)
                .frame(height: 34)
                .background(isSelected ? HLColor.freshGreen : .black.opacity(0.50))
                .clipShape(Capsule())
                .overlay {
                    Capsule().stroke(.white.opacity(isSelected ? 0 : 0.13), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

struct CourtPin: View {
    let court: Court
    let isSelected: Bool
    let isSaved: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? HLColor.basketballOrange : fill)
                .frame(width: isSelected ? 38 : isSaved ? 32 : 30, height: isSelected ? 38 : isSaved ? 32 : 30)
                .shadow(color: .black.opacity(0.30), radius: 10, y: 5)

            Image(systemName: isSaved ? "basketball.fill" : court.courtType == .indoor ? "building.2.fill" : "basketball.fill")
                .font(.system(size: isSelected ? 15 : isSaved ? 13 : 12, weight: .black))
                .foregroundStyle(.white)
        }
        .overlay {
            Circle()
                .stroke(isSaved ? HLColor.freshGreen : .white, lineWidth: isSelected ? 4 : 3)
        }
    }

    private var fill: Color {
        if isSaved {
            return HLColor.basketballOrange
        }
        return court.courtType == .indoor ? HLColor.electricBlue : HLColor.courtGreen
    }
}

struct CountrySummaryPin: View {
    let summary: CountryCourtSummary

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(HLColor.freshGreen)
                    .frame(width: 58, height: 58)
                    .shadow(color: .black.opacity(0.28), radius: 16, y: 8)

                VStack(spacing: 1) {
                    Text(summary.countryCode)
                        .font(.caption2.weight(.black))
                    Text(summary.countLabel)
                        .font(.caption.weight(.black))
                }
                .foregroundStyle(HLColor.night)
            }
            .overlay {
                Circle().stroke(.white, lineWidth: 4)
            }

            Text(summary.displayName)
                .font(.caption2.weight(.black))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .frame(height: 22)
                .background(.black.opacity(0.58))
                .clipShape(Capsule())
        }
    }
}

private extension MKCoordinateRegion {
    static func enclosing(_ coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion? {
        guard let first = coordinates.first else { return nil }

        let bounds = coordinates.reduce((minLat: first.latitude, maxLat: first.latitude, minLon: first.longitude, maxLon: first.longitude)) { result, coordinate in
            (
                minLat: min(result.minLat, coordinate.latitude),
                maxLat: max(result.maxLat, coordinate.latitude),
                minLon: min(result.minLon, coordinate.longitude),
                maxLon: max(result.maxLon, coordinate.longitude)
            )
        }

        let latitudeDelta = max((bounds.maxLat - bounds.minLat) * 1.45, 0.028)
        let longitudeDelta = max((bounds.maxLon - bounds.minLon) * 1.45, 0.028)

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (bounds.minLat + bounds.maxLat) / 2,
                longitude: (bounds.minLon + bounds.maxLon) / 2
            ),
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        )
    }

    func contains(_ coordinate: CLLocationCoordinate2D, padding: Double) -> Bool {
        let latitudePadding = span.latitudeDelta * padding
        let longitudePadding = span.longitudeDelta * padding
        let minLatitude = center.latitude - span.latitudeDelta / 2 - latitudePadding
        let maxLatitude = center.latitude + span.latitudeDelta / 2 + latitudePadding
        let minLongitude = center.longitude - span.longitudeDelta / 2 - longitudePadding
        let maxLongitude = center.longitude + span.longitudeDelta / 2 + longitudePadding

        return coordinate.latitude >= minLatitude &&
            coordinate.latitude <= maxLatitude &&
            coordinate.longitude >= minLongitude &&
            coordinate.longitude <= maxLongitude
    }

    func isSimilar(to region: MKCoordinateRegion) -> Bool {
        abs(center.latitude - region.center.latitude) < max(span.latitudeDelta, region.span.latitudeDelta) * 0.10 &&
            abs(center.longitude - region.center.longitude) < max(span.longitudeDelta, region.span.longitudeDelta) * 0.10 &&
            abs(span.latitudeDelta - region.span.latitudeDelta) < max(span.latitudeDelta, region.span.latitudeDelta) * 0.25 &&
            abs(span.longitudeDelta - region.span.longitudeDelta) < max(span.longitudeDelta, region.span.longitudeDelta) * 0.25
    }
}

private extension CLLocationCoordinate2D {
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: latitude, longitude: longitude)
            .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
    }
}

private extension CLPlacemark {
    var mapRegion: MKCoordinateRegion? {
        if let circularRegion = region as? CLCircularRegion {
            let meters = max(circularRegion.radius * 2.2, 12_000)
            return MKCoordinateRegion(
                center: circularRegion.center,
                latitudinalMeters: meters,
                longitudinalMeters: meters
            )
        }

        guard let coordinate = location?.coordinate else { return nil }
        return MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 36_000,
            longitudinalMeters: 36_000
        )
    }
}
