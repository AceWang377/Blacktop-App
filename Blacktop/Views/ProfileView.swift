import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore
    #if DEBUG
    @State private var passcode = ""
    @State private var adminError = false
    @State private var showingOwnerTools = false
    #endif

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    quickStats
                    accountSection
                    languageSection
                    librarySection
                    dataSection
                }
                .padding(20)
                .padding(.bottom, 150)
            }
            .pageBackground()
            .navigationBarTitleDisplayMode(.inline)
            #if DEBUG
            .sheet(isPresented: $showingOwnerTools) {
                NavigationStack {
                    ScrollView {
                        adminSection
                            .padding(20)
                            .padding(.bottom, 50)
                    }
                    .pageBackground()
                    .navigationTitle("Owner tools")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                showingOwnerTools = false
                            }
                        }
                    }
                }
            }
            #endif
        }
        .task {
            await store.loadCountrySummaries()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(store.copy(.profileTitle))
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(store.copy(.profileSubtitle))
                .font(.body.weight(.medium))
                .foregroundStyle(.white.opacity(0.66))
        }
        #if DEBUG
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 1.2) {
            HLHaptics.medium()
            showingOwnerTools = true
        }
        #endif
    }

    private var quickStats: some View {
        HStack {
            StatTile(value: formatCount(store.totalCourtCount), label: store.copy(.courts))
        }
    }

    private func formatCount(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private var librarySection: some View {
        SectionCard(title: store.localized("Your Blacktop", "你的 Blacktop")) {
            VStack(spacing: 10) {
                ProfileLink(title: store.localized("Saved courts", "收藏球场"), subtitle: savedCourtsSubtitle, icon: "bookmark.fill") {
                    SavedCourtsView()
                }
            }
        }
    }

    private var accountSection: some View {
        SectionCard(title: store.localized("Account", "账号")) {
            VStack(alignment: .leading, spacing: 12) {
                if let session = store.contributorSession {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(HLColor.night)
                            .frame(width: 38, height: 38)
                            .background(HLColor.freshGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(store.localized("Signed in with Apple", "已使用 Apple 登录"))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                            Text(session.email ?? store.localized("Private Apple relay", "Apple 隐私邮箱"))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.white.opacity(0.58))
                                .lineLimit(1)
                        }

                        Spacer()
                    }

                    Text(store.isSyncingSavedCourts ? store.localized("Syncing saved courts...", "正在同步收藏球场...") : store.localized("Your votes and saved courts can follow this Apple account.", "你的投票和收藏球场可以跟随这个 Apple 账号。"))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.62))

                    Button {
                        HLHaptics.light()
                        store.signOutContributor()
                    } label: {
                        Label(store.localized("Sign out", "退出登录"), systemImage: "rectangle.portrait.and.arrow.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                } else {
                    Text(store.localized("Browsing stays account-free. Sign in only when you want to vote on court facts or sync saved courts.", "浏览地图无需账号。只有投票球场事实或同步收藏球场时才需要登录。"))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.62))

                    BlacktopAppleSignInButton()
                }
            }
        }
    }

    private var savedCourtsSubtitle: String {
        if store.contributorSession == nil {
            return store.localized("Saved on this device", "保存在本机")
        }
        return store.isSyncingSavedCourts
            ? store.localized("Syncing with your account", "正在同步到账号")
            : store.localized("Synced with your account", "已同步到账号")
    }

    private var languageSection: some View {
        SectionCard(title: store.copy(.language)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(HLColor.night)
                        .frame(width: 38, height: 38)
                        .background(HLColor.freshGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(store.copy(.appLanguage))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                        Text(store.copy(.appLanguageSubtitle))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.58))
                    }

                    Spacer()
                }

                HStack(spacing: 10) {
                    ForEach(AppLanguage.allCases) { language in
                        Button {
                            HLHaptics.selection()
                            store.setLanguage(language)
                        } label: {
                            Text(language.nativeName)
                                .font(.subheadline.weight(.black))
                                .foregroundStyle(store.appLanguage == language ? HLColor.night : .white.opacity(0.78))
                                .frame(maxWidth: .infinity)
                                .frame(height: 42)
                                .background(store.appLanguage == language ? HLColor.freshGreen : .white.opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var dataSection: some View {
        SectionCard(title: store.localized("Data and app info", "数据与 App 信息")) {
            VStack(spacing: 10) {
                ProfileLink(title: store.localized("Data sources", "数据来源"), subtitle: store.localized("Where court records come from", "球场数据来自哪里"), icon: "chart.bar.doc.horizontal") {
                    AboutDataView()
                }
                ProfileLink(title: store.localized("Terms and privacy", "条款与隐私"), subtitle: store.localized("How Blacktop handles data", "Blacktop 如何处理数据"), icon: "doc.text.fill") {
                    TermsView()
                }
            }
        }
    }

    #if DEBUG
    private var adminSection: some View {
        SectionCard(title: "Admin") {
            VStack(alignment: .leading, spacing: 12) {
                if store.isAdminUnlocked {
                    ProfileLink(title: "Court database editor", subtitle: "Add or update court facts", icon: "slider.horizontal.3") {
                        AdminCourtEditorView()
                    }

                    Button {
                        HLHaptics.light()
                        store.lockAdmin()
                        passcode = ""
                    } label: {
                        Label("Lock admin mode", systemImage: "lock.fill")
                            .font(.subheadline.weight(.bold))
                    }
                    .buttonStyle(SecondaryButtonStyle())
                } else {
                    Text("Hidden owner tool for adding checked courts and updating court facts before a backend exists.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.62))

                    SecureField("Admin passcode", text: $passcode)
                        .textInputAutocapitalization(.characters)
                        .disableAutocorrection(true)
                        .padding(14)
                        .foregroundStyle(.white)
                        .background(.white.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(adminError ? HLColor.basketballOrange : HLColor.stroke, lineWidth: 1)
                        }

                    if adminError {
                        Text("Passcode not recognised.")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(HLColor.basketballOrange)
                    }

                    Button {
                        HLHaptics.medium()
                        adminError = !store.unlockAdmin(passcode: passcode)
                    } label: {
                        Label("Unlock admin", systemImage: "key.fill")
                            .font(.subheadline.weight(.bold))
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
    }
    #endif
}

struct StatTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.title.weight(.black))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.58))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardStyle(radius: 18)
    }
}

struct ProfileLink<Destination: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    @ViewBuilder var destination: Destination

    var body: some View {
        NavigationLink {
            destination
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(HLColor.night)
                    .frame(width: 38, height: 38)
                    .background(HLColor.freshGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.58))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white.opacity(0.42))
            }
            .padding(14)
            .background(.white.opacity(0.09))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct TermsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(store.localized("Terms and privacy", "条款与隐私"))
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                SectionCard(title: store.localized("Privacy promise", "隐私承诺")) {
                    Text(store.localized("Blacktop shows practical court facts without requiring an account. Saved courts stay on this device unless you sign in to sync them.", "Blacktop 展示实用球场信息，不需要账号。收藏球场会保存在本机，除非你登录后选择同步。"))
                        .foregroundStyle(.white.opacity(0.62))
                }

                SectionCard(title: store.localized("Court data", "球场数据")) {
                    Text(store.localized("Court records come from public map data, trusted datasets, and Blacktop checks. Details can change over time, so always use your judgement before travelling.", "球场记录来自公开地图数据、可信数据集和 Blacktop 检查。具体情况可能变化，出发前请自行判断。"))
                        .foregroundStyle(.white.opacity(0.62))
                }

                SectionCard(title: store.localized("OpenStreetMap attribution", "OpenStreetMap 署名")) {
                    Text(store.localized("Contains information from OpenStreetMap contributors, available under the Open Database License.", "包含来自 OpenStreetMap 贡献者的信息，数据遵循 Open Database License。"))
                        .foregroundStyle(.white.opacity(0.62))
                }

                SectionCard(title: store.localized("Data updates", "数据更新")) {
                    Text(store.localized("Blacktop updates court records over time from public map data, trusted datasets, and manual checks.", "Blacktop 会持续根据公开地图数据、可信数据集和人工检查更新球场记录。"))
                        .foregroundStyle(.white.opacity(0.62))
                }
            }
            .padding(20)
            .padding(.bottom, 110)
        }
        .pageBackground()
        .navigationTitle(store.localized("Terms", "条款"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
