import AuthenticationServices
import CryptoKit
import Security
import SwiftUI

struct CourtFactUpdateSheetView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let court: Court
    @State private var draft = CourtFactUpdateDraft()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    CommunitySignInPanel()

                    SectionCard(title: store.localized("Vote on court facts", "投票球场事实")) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text(store.localized("Pick one practical detail you know from playing here. Your vote appears as a count so other players can judge confidence.", "选择一个你实际知道的球场细节。你的投票会以数字显示，方便其他球员判断可信度。"))
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.64))

                            Menu {
                                ForEach(CommunityFactField.allCases) { field in
                                    Button(field.title(store.appLanguage)) {
                                        draft.field = field
                                        draft.value = nil
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(draft.field.title(store.appLanguage))
                                        .font(.headline.weight(.semibold))
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                }
                                .foregroundStyle(.white)
                                .padding(14)
                                .background(.white.opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }

                            FlowLayout(spacing: 8) {
                                ForEach(draft.field.options(store.appLanguage)) { option in
                                    SelectableChip(
                                        label: factOptionLabel(option),
                                        isSelected: draft.value == option.value
                                    ) {
                                        draft.value = option.value
                                    }
                                }
                            }
                        }
                    }

                    messageView
                }
                .padding(20)
            }
            .pageBackground()
            .navigationTitle(store.localized("Contribute", "贡献信息"))
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await store.loadFactVotes(for: court)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(store.localized("Close", "关闭")) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(store.localized("Save vote", "保存投票")) {
                        Task {
                            await store.submitFactVote(for: court, draft: draft)
                            if store.communityMessage?.contains("Vote saved") == true || store.communityMessage?.contains("投票已保存") == true {
                                dismiss()
                            }
                        }
                    }
                    .disabled(store.contributorSession == nil || !draft.isReady || store.isSubmittingCommunityUpdate)
                }
            }
        }
    }

    private func factOptionLabel(_ option: CommunityFactOption) -> String {
        "\(option.label(store.appLanguage)) · \(voteCount(for: option.value))"
    }

    private func voteCount(for value: String) -> Int {
        (store.factVoteSummariesByCourtID[court.id] ?? [])
            .first { $0.field == draft.field && $0.value == value }?
            .voteCount ?? 0
    }

    @ViewBuilder
    private var messageView: some View {
        if let message = store.communityMessage {
            Text(message)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

struct CourtVibeVoteSheetView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let court: Court
    @State private var selectedCategory: CourtVibeCategory = .usualIntensity
    @State private var selectedOption: CourtVibeOption?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    CommunitySignInPanel()

                    SectionCard(title: store.localized("Vote court vibe", "投票球场氛围")) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(store.localized("This is not live occupancy. It helps players understand the usual run style before they travel. Each label shows how many players chose it.", "这不是实时人数，而是帮助球员了解这个球场平时是什么类型的局。每个标签会显示选择它的人数。"))
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.64))

                            FlowLayout(spacing: 8) {
                                ForEach(CourtVibeCategory.allCases) { category in
                                    SelectableChip(
                                        label: category.title(store.appLanguage),
                                        isSelected: selectedCategory == category
                                    ) {
                                        selectedCategory = category
                                        selectedOption = nil
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text(selectedCategory.title(store.appLanguage))
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text(selectedCategory.subtitle(store.appLanguage))
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.58))
                            }

                            FlowLayout(spacing: 8) {
                                ForEach(selectedCategory.options) { option in
                                    SelectableChip(
                                        label: vibeOptionLabel(option),
                                        isSelected: selectedOption == option
                                    ) {
                                        selectedOption = option
                                    }
                                }
                            }
                        }
                    }

                    if let message = store.communityMessage {
                        Text(message)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.72))
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.white.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(20)
            }
            .pageBackground()
            .navigationTitle(store.localized("Court vibe", "球场氛围"))
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await store.loadVibeSummaries(for: court)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(store.localized("Close", "关闭")) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(store.localized("Save vote", "保存投票")) {
                        guard let selectedOption else { return }
                        Task {
                            await store.submitVibeVote(for: court, category: selectedCategory, option: selectedOption)
                            if store.communityMessage?.contains("Vote saved") == true || store.communityMessage?.contains("投票已保存") == true {
                                dismiss()
                            }
                        }
                    }
                    .disabled(store.contributorSession == nil || selectedOption == nil || store.isSubmittingCommunityUpdate)
                }
            }
        }
    }

    private func vibeOptionLabel(_ option: CourtVibeOption) -> String {
        "\(option.label(store.appLanguage)) · \(voteCount(for: option))"
    }

    private func voteCount(for option: CourtVibeOption) -> Int {
        (store.vibeSummariesByCourtID[court.id] ?? [])
            .first { $0.category == selectedCategory && $0.option == option }?
            .voteCount ?? 0
    }
}

struct CommunitySignInPanel: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        SectionCard(title: store.localized("Account", "账号")) {
            VStack(alignment: .leading, spacing: 12) {
                if let session = store.contributorSession {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(HLColor.freshGreen)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.localized("Signed in with Apple", "已使用 Apple 登录"))
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)
                            Text(session.email ?? store.localized("Private Apple relay", "Apple 隐私邮箱"))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.54))
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                } else {
                    Text(store.localized("Sign in with Apple to vote. Browsing stays account-free.", "使用 Apple 登录后即可投票。浏览地图仍然无需账号。"))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.64))

                    BlacktopAppleSignInButton()
                }
            }
        }
    }
}

struct BlacktopAppleSignInButton: View {
    @EnvironmentObject private var store: AppStore
    @State private var currentNonce: String?

    var body: some View {
        SignInWithAppleButton(.signIn) { request in
            let nonce = AppleSignInNonce.random()
            currentNonce = nonce
            request.requestedScopes = [.email]
            request.nonce = AppleSignInNonce.sha256(nonce)
        } onCompletion: { result in
            switch result {
            case .success(let authorization):
                guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                      let tokenData = credential.identityToken,
                      let token = String(data: tokenData, encoding: .utf8),
                      let nonce = currentNonce else {
                    store.communityMessage = store.localized("Apple did not return a valid sign-in token.", "Apple 未返回有效登录凭证。")
                    return
                }
                Task {
                    await store.signInWithApple(identityToken: token, nonce: nonce)
                }
            case .failure:
                store.communityMessage = store.localized("Apple sign in was cancelled or failed.", "Apple 登录已取消或失败。")
            }
        }
        .signInWithAppleButtonStyle(.white)
        .frame(height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private enum AppleSignInNonce {
    static func random(length: Int = 32) -> String {
        precondition(length > 0)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var random: UInt8 = 0
            let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            guard status == errSecSuccess else { continue }

            if random < UInt8(charset.count) {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }

        return result
    }

    static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}
