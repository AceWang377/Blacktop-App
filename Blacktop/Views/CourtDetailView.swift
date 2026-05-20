import SwiftUI
import MapKit
import UIKit

struct CourtDetailView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let court: Court
    @State private var isShowingDirectionsMenu = false

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
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    Button {
                        store.toggleSaved(court)
                    } label: {
                        Label(store.isSaved(court) ? store.localized("Saved", "已收藏") : store.localized("Save", "收藏"), systemImage: store.isSaved(court) ? "bookmark.fill" : "bookmark")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button(store.copy(.directions)) {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.86)) {
                            isShowingDirectionsMenu.toggle()
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(20)
                .background(.black.opacity(0.72))
                .overlay(alignment: .topTrailing) {
                    if isShowingDirectionsMenu {
                        directionsMenu
                            .padding(.trailing, 20)
                            .offset(y: -112)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
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
        SectionCard(title: store.localized("Court facts", "球场事实")) {
            VStack(alignment: .leading, spacing: 14) {
                Text(store.localized("Tap a tag to vote. You can change your vote anytime. Counts show how many players chose each option.", "点击标签即可投票。你可以随时修改投票。数字代表有多少球员选择该选项。"))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.62))

                VStack(alignment: .leading, spacing: 16) {
                    ForEach(CommunityFactField.allCases) { field in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(field.title(store.appLanguage))
                                .font(.caption.weight(.black))
                                .foregroundStyle(.white.opacity(0.56))

                            FlowLayout(spacing: 8) {
                                ForEach(field.options(store.appLanguage)) { option in
                                    VoteTagButton(
                                        label: tagLabel(option.label(store.appLanguage), count: factVoteCount(field: field, value: option.value)),
                                        isSelected: isUserFactVoteSelected(field: field, value: option.value),
                                        isSubmitting: store.isSubmittingCommunityUpdate
                                    ) {
                                        submitFactVote(field: field, value: option.value)
                                    }
                                }
                            }
                        }
                    }
                }

                communityMessageView
            }
        }
    }

    private var courtVibe: some View {
        SectionCard(title: store.localized("Court vibe", "球场氛围")) {
            VStack(alignment: .leading, spacing: 14) {
                Text(store.localized("Community votes describe the usual run style here, not live occupancy. Counts show how many players chose each label.", "社区投票展示这里平时的打球氛围，不代表实时人数。数字代表选择该标签的球员人数。"))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.62))

                VStack(alignment: .leading, spacing: 16) {
                    ForEach(CourtVibeCategory.allCases) { category in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(category.title(store.appLanguage))
                                .font(.caption.weight(.black))
                                .foregroundStyle(.white.opacity(0.56))

                            FlowLayout(spacing: 8) {
                                ForEach(category.options) { option in
                                    VoteTagButton(
                                        label: tagLabel(option.label(store.appLanguage), count: vibeVoteCount(category: category, option: option)),
                                        isSelected: isUserVibeVoteSelected(category: category, option: option),
                                        isSubmitting: store.isSubmittingCommunityUpdate
                                    ) {
                                        submitVibeVote(category: category, option: option)
                                    }
                                }
                            }
                        }
                    }
                }
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

    private var directionsMenu: some View {
        VStack(spacing: 8) {
            Button {
                isShowingDirectionsMenu = false
                openAppleMaps()
            } label: {
                Label(store.localized("Apple Maps", "Apple 地图"), systemImage: "map.fill")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(DirectionMenuButtonStyle())

            Button {
                isShowingDirectionsMenu = false
                openGoogleMaps()
            } label: {
                Label(store.localized("Google Maps", "Google 地图"), systemImage: "g.circle.fill")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(DirectionMenuButtonStyle())
        }
        .padding(10)
        .frame(width: 220)
        .background(.black.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.30), radius: 18, y: 8)
    }

    @ViewBuilder
    private var communityMessageView: some View {
        if let message = store.communityMessage {
            Text(message)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.70))
                .padding(.top, 2)
        }
    }

    private func tagLabel(_ label: String, count: Int) -> String {
        "\(label) \(count)"
    }

    private func factVoteCount(field: CommunityFactField, value: String) -> Int {
        (store.factVoteSummariesByCourtID[court.id] ?? [])
            .first { $0.field == field && $0.value == value }?
            .voteCount ?? 0
    }

    private func vibeVoteCount(category: CourtVibeCategory, option: CourtVibeOption) -> Int {
        (store.vibeSummariesByCourtID[court.id] ?? [])
            .first { $0.category == category && $0.option == option }?
            .voteCount ?? 0
    }

    private func isUserFactVoteSelected(field: CommunityFactField, value: String) -> Bool {
        (store.userFactVotesByCourtID[court.id] ?? [])
            .contains { $0.field == field && $0.value == value }
    }

    private func isUserVibeVoteSelected(category: CourtVibeCategory, option: CourtVibeOption) -> Bool {
        (store.userVibeVotesByCourtID[court.id] ?? [])
            .contains { $0.category == category && $0.option == option }
    }

    private func submitFactVote(field: CommunityFactField, value: String) {
        guard store.contributorSession != nil else {
            store.communityMessage = store.localized("Sign in from Profile to vote.", "请先在我的页面使用 Apple 登录后再投票。")
            return
        }

        Task {
            await store.submitFactVote(for: court, draft: CourtFactUpdateDraft(field: field, value: value))
        }
    }

    private func submitVibeVote(category: CourtVibeCategory, option: CourtVibeOption) {
        guard store.contributorSession != nil else {
            store.communityMessage = store.localized("Sign in from Profile to vote.", "请先在我的页面使用 Apple 登录后再投票。")
            return
        }

        Task {
            await store.submitVibeVote(for: court, category: category, option: option)
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

private struct VoteTagButton: View {
    let label: String
    let isSelected: Bool
    let isSubmitting: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.black))
                .foregroundStyle(isSelected ? HLColor.night : .white.opacity(0.86))
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background(isSelected ? HLColor.freshGreen : .white.opacity(0.10))
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(isSelected ? .clear : .white.opacity(0.16), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .disabled(isSubmitting)
    }
}

private struct DirectionMenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(.white.opacity(configuration.isPressed ? 0.16 : 0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
