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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    communityFactVotes
                    courtVibe
                    locationFacts
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

    private var communityFactVotes: some View {
        SectionCard(title: store.localized("Player fact votes", "球员事实投票")) {
            VStack(alignment: .leading, spacing: 14) {
                Text(store.localized("Facts here come from player votes. Each label shows how many signed-in players chose it.", "这里的事实来自玩家投票。每个标签数字代表有多少已登录球员选择它。"))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.62))

                let summaries = groupedFactVoteSummaries
                if summaries.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        FactChip(label: store.localized("No player fact votes yet", "暂无玩家事实投票"), tone: .unknown)
                        Text(store.localized("Be the first to vote on nets, lights, rain impact, rim height, facilities and more.", "你可以第一个投票补充篮网、灯光、雨后状态、篮筐高度、设施等信息。"))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.54))
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
                    Label(store.localized("Vote on any fact", "投票任意事实"), systemImage: "checklist")
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

        if let appURL = URL(string: "comgooglemaps://?daddr=\(latitude),\(longitude)&directionsmode=walking") {
            UIApplication.shared.open(appURL) { success in
                guard !success,
                      let webURL = URL(string: "https://www.google.com/maps/dir/?api=1&destination=\(latitude),\(longitude)&travelmode=walking") else {
                    return
                }
                UIApplication.shared.open(webURL)
            }
        }
    }
}
