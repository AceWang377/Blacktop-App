import SwiftUI

struct SavedCourtsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedCourt: Court?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(store.localized("Saved courts", "收藏球场"))
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text(store.contributorSession == nil
                             ? store.localized("Quickly check your regular spots. Saved courts stay on this device.", "快速查看你常去的球场。收藏内容只保存在本机。")
                             : store.localized("Quickly check your regular spots. Saved courts sync with your account.", "快速查看你常去的球场。收藏内容会同步到你的账号。"))
                            .font(.body.weight(.medium))
                            .foregroundStyle(.white.opacity(0.66))
                    }

                    if store.savedCourts.isEmpty {
                        emptyState
                    } else {
                        ForEach(store.savedCourts) { court in
                            CourtCard(court: court, isSaved: true) {
                                store.toggleSaved(court)
                            }
                            .onTapGesture {
                                selectedCourt = court
                            }
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 110)
            }
            .pageBackground()
            .sheet(item: $selectedCourt) { court in
                CourtDetailView(court: court)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "bookmark")
                .font(.largeTitle)
                .foregroundStyle(HLColor.electricBlue)
            Text(store.localized("Save courts you want to check again.", "收藏你想再次查看的球场。"))
                .font(.title2.weight(.black))
                .foregroundStyle(.white)
            Text(store.contributorSession == nil
                 ? store.localized("No account needed. Your list is local to this device.", "无需账号。你的列表只保存在这台设备上。")
                 : store.localized("Saved courts will appear here and sync with your account.", "收藏球场会显示在这里，并同步到你的账号。"))
                .foregroundStyle(.white.opacity(0.62))
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(radius: 24)
    }
}
