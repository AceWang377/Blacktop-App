import SwiftUI
import MapKit
import UIKit

struct CourtDetailView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let court: Court
    @State private var isShowingFactUpdateSheet = false
    @State private var isShowingVibeVoteSheet = false
    @State private var isShowingDirectionsDialog = false
    @State private var copiedDirectionsMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    quickFacts
                    communityFactVotes
                    courtVibe
                    bestFor
                    communityUpdate
                    locationFacts
                    playingConditions
                    rimAndHoop
                    accessAndTiming
                    facilities
                }
                .padding(20)
            }
            .pageBackground()
            .navigationTitle(store.localized("Court details", "球场详情"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(store.localized("Close", "关闭")) { dismiss() }
                }
            }
            .task(id: court.id) {
                async let vibeLoad: Void = store.loadVibeSummaries(for: court)
                async let factLoad: Void = store.loadFactVotes(for: court)
                _ = await (vibeLoad, factLoad)
            }
            .sheet(isPresented: $isShowingFactUpdateSheet) {
                CourtFactUpdateSheetView(court: court)
                    .environmentObject(store)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $isShowingVibeVoteSheet) {
                CourtVibeVoteSheetView(court: court)
                    .environmentObject(store)
                    .presentationDetents([.medium, .large])
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    Button {
                        store.toggleSaved(court)
                    } label: {
                        Label(store.isSaved(court) ? store.localized("Saved", "已收藏") : store.localized("Save", "收藏"), systemImage: store.isSaved(court) ? "bookmark.fill" : "bookmark")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button(store.copy(.directions)) {
                        isShowingDirectionsDialog = true
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(20)
                .background(.black.opacity(0.72))
            }
            .confirmationDialog(store.copy(.directions), isPresented: $isShowingDirectionsDialog, titleVisibility: .visible) {
                Button(store.localized("Open in Apple Maps", "使用 Apple 地图打开")) {
                    openAppleMaps()
                }
                Button(store.localized("Open in Google Maps", "使用 Google 地图打开")) {
                    openGoogleMaps()
                }
                Button(store.localized("Copy address", "复制地址")) {
                    copyAddress()
                }
                Button(store.localized("Copy coordinates", "复制坐标")) {
                    copyCoordinates()
                }
                Button(store.localized("Cancel", "取消"), role: .cancel) {}
            } message: {
                Text(court.name)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(court.displayPhotoAssetName)
                .resizable()
                .scaledToFill()
                .frame(height: 210)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .overlay(alignment: .topTrailing) {
                    Label(court.photoAssetName == nil ? store.localized("Default image", "默认图片") : store.localized("Court photo", "球场照片"), systemImage: "photo.fill")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.46))
                        .clipShape(Capsule())
                        .padding(14)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(.white.opacity(0.34), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.14), radius: 24, y: 12)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(court.name)
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text(court.area)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white.opacity(0.62))
                }
                Spacer()
                Button {
                    store.toggleSaved(court)
                } label: {
                    Image(systemName: store.isSaved(court) ? "bookmark.fill" : "bookmark")
                        .font(.title3)
                        .foregroundStyle(store.isSaved(court) ? HLColor.basketballOrange : HLColor.secondaryText)
                        .padding(10)
                        .background(.white.opacity(0.12))
                        .clipShape(Circle())
                }
            }
        }
    }

    private var quickFacts: some View {
        SectionCard(title: store.localized("Quick facts", "快速信息")) {
            FlowLayout(spacing: 8) {
                ForEach(court.topFacts(language: store.appLanguage)) { fact in
                    FactChip(label: fact.label, tone: fact.tone)
                }
                FactChip(label: court.rimHeight.displayName(store.appLanguage), tone: court.rimHeight == .standard ? .positive : court.rimHeight == .unknown ? .unknown : .warning)
            }
        }
    }

    private var communityFactVotes: some View {
        SectionCard(title: store.localized("Player fact votes", "球员事实投票")) {
            VStack(alignment: .leading, spacing: 14) {
                Text(store.localized("Labels show how many signed-in players chose each fact. Use the counts as confidence, not a formal rating.", "标签数字代表有多少已登录球员选择了这个事实。请把数字当作参考信心，而不是正式评分。"))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.62))

                let summaries = groupedFactVoteSummaries
                if summaries.isEmpty {
                    FlowLayout(spacing: 8) {
                        FactChip(label: store.localized("No votes yet", "暂无投票"), tone: .unknown)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 13) {
                        ForEach(summaries, id: \.field) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(group.field.title(store.appLanguage))
                                    .font(.caption.weight(.black))
                                    .foregroundStyle(.white.opacity(0.56))

                                FlowLayout(spacing: 8) {
                                    ForEach(group.summaries) { summary in
                                        FactChip(label: summary.label(store.appLanguage), tone: factVoteTone(summary))
                                    }
                                }
                            }
                        }
                    }
                }

                let userVotes = store.userFactVotesByCourtID[court.id] ?? []
                if !userVotes.isEmpty {
                    Text(store.localized("Your votes: \(userVotes.map { $0.label(store.appLanguage) }.joined(separator: ", "))", "你的投票：\(userVotes.map { $0.label(store.appLanguage) }.joined(separator: "，"))"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(HLColor.freshGreen.opacity(0.88))
                }

                Button {
                    isShowingFactUpdateSheet = true
                } label: {
                    Label(store.localized("Vote on facts", "投票球场事实"), systemImage: "checklist")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }

    private var courtVibe: some View {
        SectionCard(title: store.localized("Court vibe", "球场氛围")) {
            VStack(alignment: .leading, spacing: 14) {
                Text(store.localized("Community votes describe the usual run style here, not live occupancy. Counts show how many players chose each label.", "社区投票展示这里平时的打球氛围，不代表实时人数。数字代表选择该标签的球员人数。"))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.62))

                let summaries = store.vibeSummariesByCourtID[court.id] ?? []
                if summaries.isEmpty {
                    FactChip(label: store.localized("Waiting for votes", "等待投票"), tone: .unknown)
                } else {
                    VStack(spacing: 12) {
                        ForEach(CourtVibeCategory.allCases) { category in
                            if let summary = topVibeSummary(for: category, from: summaries) {
                                vibeSummaryRow(summary)
                            }
                        }
                    }
                }

                let userVotes = store.userVibeVotesByCourtID[court.id] ?? []
                if !userVotes.isEmpty {
                    Text(store.localized("Your vibe votes: \(userVotes.map { $0.option.label(store.appLanguage) }.joined(separator: ", "))", "你的氛围投票：\(userVotes.map { $0.option.label(store.appLanguage) }.joined(separator: "，"))"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(HLColor.freshGreen.opacity(0.88))
                }

                Button {
                    isShowingVibeVoteSheet = true
                } label: {
                    Label(store.localized("Vote court vibe", "投票球场氛围"), systemImage: "slider.horizontal.3")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }

    private var bestFor: some View {
        SectionCard(title: store.localized("Best for", "适合用途")) {
            FlowLayout(spacing: 8) {
                ForEach(bestForSignals, id: \.label) { fact in
                    FactChip(label: fact.label, tone: fact.tone)
                }
            }
        }
    }

    private var communityUpdate: some View {
        SectionCard(title: store.localized("Know this court?", "熟悉这个球场？")) {
            VStack(alignment: .leading, spacing: 12) {
                Text(store.localized("Help complete practical facts like nets, lights, rain impact, rim height and facilities. Sign in is only required when you vote.", "帮助补全篮网、灯光、雨后状态、篮筐高度和设施等实用信息。只有投票时需要登录。"))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.62))

                HStack(spacing: 10) {
                    FactChip(label: missingFactsLabel, tone: missingFactsCount == 0 ? .positive : .unknown)
                    Spacer()
                }

                Button {
                    isShowingFactUpdateSheet = true
                } label: {
                    Label(store.localized("Vote on a fact", "投票一个事实"), systemImage: "checklist")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }

    private var locationFacts: some View {
        SectionCard(title: store.localized("Location", "位置")) {
            FactRow(title: store.localized("Area", "区域"), value: court.area)
            FactRow(title: store.localized("City", "城市"), value: court.city)
            FactRow(title: store.localized("Postcode", "邮编"), value: court.postcode ?? store.localized("Not available", "暂无"), tone: court.postcode == nil ? .unknown : .neutral)
            if let addressLine = court.addressLine {
                FactRow(title: store.localized("Address", "地址"), value: addressLine)
            }
        }
    }

    private var playingConditions: some View {
        SectionCard(title: store.localized("Playing conditions", "场地状态")) {
            FactRow(title: store.localized("Surface", "地面"), value: court.surfaceType.displayName(store.appLanguage))
            FactRow(title: store.localized("Dryness", "干燥情况"), value: court.drynessAfterRain.displayName(store.appLanguage), tone: court.drynessAfterRain.tone)
            FactRow(title: store.localized("Slippery", "湿滑"), value: court.slipperyWhenWet.displayName(store.appLanguage), tone: court.slipperyWhenWet == .yes ? .warning : court.slipperyWhenWet == .no ? .positive : .unknown)
            FactRow(title: store.localized("Rain", "雨天"), value: court.rainPlayable.displayName(store.appLanguage), tone: court.rainPlayable == .indoorUnaffected || court.rainPlayable == .yes ? .positive : court.rainPlayable == .no ? .warning : .unknown)
            FactRow(title: store.localized("Space", "空间"), value: court.courtSpace.displayName(store.appLanguage), tone: court.courtSpace == .spacious ? .positive : court.courtSpace == .unknown ? .unknown : .warning)
            FactRow(title: store.localized("Clean", "清洁度"), value: court.courtCleanliness.displayName(store.appLanguage), tone: court.courtCleanliness == .clean ? .positive : court.courtCleanliness == .unknown ? .unknown : .neutral)
        }
    }

    private var rimAndHoop: some View {
        SectionCard(title: store.localized("Rim and hoop", "篮筐与篮网")) {
            FactRow(title: store.localized("Hoops", "篮筐数量"), value: court.hoopCount.map(String.init) ?? store.localized("Unknown", "未知"))
            FactRow(title: store.localized("Nets", "篮网"), value: court.hasNets.displayName(store.appLanguage), tone: court.hasNets.tone)
            FactRow(title: store.localized("Height", "高度"), value: court.rimHeight.displayName(store.appLanguage), tone: court.rimHeight == .standard ? .positive : court.rimHeight == .unknown ? .unknown : .warning)
            FactRow(title: store.localized("Rim", "篮筐"), value: court.rimType.displayName(store.appLanguage), tone: court.rimType == .doubleRim ? .warning : court.rimType == .unknown ? .unknown : .neutral)
            FactRow(title: store.localized("Backboard", "篮板"), value: court.backboardCondition.displayName(store.appLanguage))
            FactRow(title: store.localized("Rim condition", "篮筐状态"), value: court.rimCondition.displayName(store.appLanguage))
        }
    }

    private var accessAndTiming: some View {
        SectionCard(title: store.localized("Access and timing", "开放与时间")) {
            FactRow(title: store.localized("Access", "开放方式"), value: court.accessType.displayName(store.appLanguage))
            FactRow(title: store.localized("Cost", "费用"), value: court.priceType.displayName(store.appLanguage), tone: court.priceType == .free ? .positive : court.priceType == .unknown ? .unknown : .neutral)
            FactRow(title: store.localized("Hours", "开放时间"), value: court.openingHours)
            FactRow(title: store.localized("Evening", "晚上"), value: court.eveningAccess.displayName(store.appLanguage))
            FactRow(title: store.localized("Peak", "高峰"), value: court.peakTimes.map { $0.displayName(store.appLanguage) }.joined(separator: ", "))
        }
    }

    private var facilities: some View {
        SectionCard(title: store.localized("Facilities", "配套设施")) {
            FactRow(title: store.localized("Toilets", "厕所"), value: court.hasToilets.displayName(store.appLanguage))
            FactRow(title: store.localized("Water", "饮水"), value: court.hasDrinkingWater.displayName(store.appLanguage))
            FactRow(title: store.localized("Parking", "停车"), value: court.hasParking.displayName(store.appLanguage))
            FactRow(title: store.localized("Changing", "更衣"), value: court.hasChangingRooms.displayName(store.appLanguage))
        }
    }

    private var bestForSignals: [CourtFact] {
        var facts: [CourtFact] = []
        if court.goodForSolo == .yes {
            facts.append(CourtFact(label: store.localized("Solo shooting", "适合投篮"), tone: .positive))
        }
        if court.goodForPickup == .yes {
            facts.append(CourtFact(label: store.localized("Pickup runs", "适合野球"), tone: .positive))
        }
        if court.goodForTraining == .yes {
            facts.append(CourtFact(label: store.localized("Training", "训练"), tone: .positive))
        }
        if court.beginnerFriendly == .yes {
            facts.append(CourtFact(label: store.localized("Beginner friendly", "新手友好"), tone: .positive))
        }
        if court.courtSpace == .spacious {
            facts.append(CourtFact(label: store.localized("Good space", "空间充足"), tone: .positive))
        }
        if facts.isEmpty {
            facts.append(CourtFact(label: store.localized("Use facts pending", "用途信息待补充"), tone: .unknown))
        }
        return facts
    }

    private var missingFactsCount: Int {
        [
            court.hasLights == .unknown,
            court.drynessAfterRain == .unknown,
            court.rainPlayable == .unknown,
            court.surfaceType == .unknown,
            court.courtSpace == .unknown,
            court.hasNets == .unknown,
            court.rimHeight == .unknown,
            court.hasToilets == .unknown,
            court.hasDrinkingWater == .unknown,
            court.hasParking == .unknown
        ].filter { $0 }.count
    }

    private var missingFactsLabel: String {
        missingFactsCount == 0
            ? store.localized("Core facts complete", "核心信息已补全")
            : store.localized("\(missingFactsCount) facts need help", "\(missingFactsCount) 项信息待补充")
    }

    private var groupedFactVoteSummaries: [(field: CommunityFactField, summaries: [CourtFactVoteSummary])] {
        let summaries = store.factVoteSummariesByCourtID[court.id] ?? []
        return CommunityFactField.allCases.compactMap { field in
            let fieldSummaries = summaries
                .filter { $0.field == field }
                .sorted {
                    if $0.voteCount == $1.voteCount { return $0.value < $1.value }
                    return $0.voteCount > $1.voteCount
                }
                .prefix(3)
            guard !fieldSummaries.isEmpty else { return nil }
            return (field: field, summaries: Array(fieldSummaries))
        }
    }

    private func factVoteTone(_ summary: CourtFactVoteSummary) -> FactTone {
        if summary.fieldTotal < 3 { return .unknown }
        return summary.percentage >= 60 ? .positive : .neutral
    }

    private func topVibeSummary(for category: CourtVibeCategory, from summaries: [CourtVibeSummary]) -> CourtVibeSummary? {
        summaries
            .filter { $0.category == category }
            .sorted {
                if $0.voteCount == $1.voteCount { return $0.option.rawValue < $1.option.rawValue }
                return $0.voteCount > $1.voteCount
            }
            .first
    }

    private func vibeSummaryRow(_ summary: CourtVibeSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(summary.category.title(store.appLanguage))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))
                Spacer()
                Text(summary.label(store.appLanguage))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
            }

            ProgressView(value: Double(summary.percentage), total: 100)
                .tint(summary.option.tone == .warning ? HLColor.basketballOrange : HLColor.freshGreen)

            Text(store.localized("\(summary.voteCount) of \(summary.categoryTotal) votes", "\(summary.categoryTotal) 票中的 \(summary.voteCount) 票"))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.50))
        }
    }

    private func openAppleMaps() {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: court.coordinate))
        item.name = court.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }

    private func openGoogleMaps() {
        let latitude = court.coordinate.latitude
        let longitude = court.coordinate.longitude
        let encodedName = court.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Court"

        if let appURL = URL(string: "comgooglemaps://?daddr=\(latitude),\(longitude)&directionsmode=walking") {
            UIApplication.shared.open(appURL) { success in
                guard !success,
                      let webURL = URL(string: "https://www.google.com/maps/dir/?api=1&destination=\(latitude),\(longitude)&destination_place_id=\(encodedName)&travelmode=walking") else {
                    return
                }
                UIApplication.shared.open(webURL)
            }
        }
    }

    private func copyAddress() {
        UIPasteboard.general.string = court.addressLine ?? "\(court.name), \(court.area), \(court.city)"
        copiedDirectionsMessage = store.localized("Address copied", "地址已复制")
    }

    private func copyCoordinates() {
        UIPasteboard.general.string = "\(court.coordinate.latitude), \(court.coordinate.longitude)"
        copiedDirectionsMessage = store.localized("Coordinates copied", "坐标已复制")
    }
}
