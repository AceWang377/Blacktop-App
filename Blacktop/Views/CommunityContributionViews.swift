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

                    SectionCard(title: store.localized("Update a court fact", "更新球场事实")) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text(store.localized("Pick one factual detail you know from playing here. Updates are reviewed before they change the public court page.", "选择一个你实际知道的球场事实。提交后会先审核，再更新到公开详情。"))
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

                            FactRow(
                                title: store.localized("Current", "当前"),
                                value: draft.field.currentValue(for: court, language: store.appLanguage),
                                tone: .unknown
                            )

                            FlowLayout(spacing: 8) {
                                ForEach(draft.field.options(store.appLanguage)) { option in
                                    SelectableChip(
                                        label: option.label(store.appLanguage),
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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(store.localized("Close", "关闭")) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(store.localized("Submit", "提交")) {
                        Task {
                            await store.submitFactUpdate(for: court, draft: draft)
                            if store.communityMessage?.contains("Thanks") == true || store.communityMessage?.contains("谢谢") == true {
                                dismiss()
                            }
                        }
                    }
                    .disabled(store.contributorSession == nil || !draft.isReady || store.isSubmittingCommunityUpdate)
                }
            }
        }
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
                            Text(store.localized("This is not live occupancy. It helps players understand the usual run style before they travel.", "这不是实时人数，而是帮助球员了解这个球场平时是什么类型的局。"))
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
                                        label: option.label(store.appLanguage),
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
}

struct CommunitySignInPanel: View {
    @EnvironmentObject private var store: AppStore
    @State private var currentNonce: String?

    var body: some View {
        SectionCard(title: store.localized("Contributor access", "贡献者权限")) {
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
                        Button(store.localized("Sign out", "退出")) {
                            store.signOutContributor()
                        }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.68))
                    }
                } else {
                    Text(store.localized("Sign in is only needed to vote or submit court facts. Browsing stays account-free.", "只有投票或提交球场事实时才需要登录。浏览地图仍然无需账号。"))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.64))

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
        }
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
