import AuthenticationServices
import Foundation
import Security

enum SupabaseCommunityError: Error {
    case invalidIdentityToken
    case invalidURL
    case invalidResponse
    case requestFailed(statusCode: Int, message: String)
    case missingSession
}

struct SupabaseCommunityService {
    private let keychain = CommunitySessionKeychain()

    func restoreSession() -> ContributorSession? {
        keychain.load()
    }

    func clearSession() {
        keychain.clear()
    }

    func signInWithApple(identityToken: String, nonce: String) async throws -> ContributorSession {
        var components = URLComponents(
            url: SupabaseConfig.projectURL.appending(path: "/auth/v1/token"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "grant_type", value: "id_token")
        ]

        guard let url = components?.url else {
            throw SupabaseCommunityError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(SupabaseConfig.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 14
        request.httpBody = try JSONEncoder.snakeCase.encode(
            SignInWithIDTokenRequest(provider: "apple", idToken: identityToken, nonce: nonce)
        )

        let response: SupabaseAuthResponse = try await performDecodedRequest(request)
        let session = ContributorSession(
            userID: response.user.id,
            email: response.user.email,
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(response.expiresIn ?? 3600))
        )
        keychain.save(session)
        return session
    }

    func submitFactVote(courtID: String, draft: CourtFactUpdateDraft, session: ContributorSession?) async throws {
        guard let session else {
            throw SupabaseCommunityError.missingSession
        }
        guard let value = draft.value else {
            return
        }

        var components = URLComponents(
            url: SupabaseConfig.projectURL.appending(path: "/rest/v1/court_fact_votes"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "on_conflict", value: "court_id,user_id,field_key")
        ]
        guard let url = components?.url else {
            throw SupabaseCommunityError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyRESTHeaders(to: &request, accessToken: session.accessToken)
        request.setValue("resolution=merge-duplicates,return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONEncoder.snakeCase.encode(
            FactVoteRequest(courtId: courtID, fieldKey: draft.field.rawValue, voteValue: value)
        )

        try await performEmptyRequest(request)
    }

    func fetchFactVoteSummaries(courtID: String) async throws -> [CourtFactVoteSummary] {
        var components = URLComponents(
            url: SupabaseConfig.projectURL.appending(path: "/rest/v1/court_fact_vote_summaries"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "court_id", value: "eq.\(courtID)"),
            URLQueryItem(name: "order", value: "field_key.asc,percentage.desc")
        ]
        guard let url = components?.url else {
            throw SupabaseCommunityError.invalidURL
        }

        var request = URLRequest(url: url)
        applyRESTHeaders(to: &request, accessToken: SupabaseConfig.publishableKey)
        let rows: [CourtFactVoteSummaryDTO] = try await performDecodedRequest(request)
        return rows.compactMap(\.summary)
    }

    func fetchUserFactVotes(courtID: String, session: ContributorSession?) async throws -> [CourtFactUserVote] {
        guard let session else { return [] }
        var components = URLComponents(
            url: SupabaseConfig.projectURL.appending(path: "/rest/v1/court_fact_votes"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "select", value: "court_id,field_key,vote_value"),
            URLQueryItem(name: "court_id", value: "eq.\(courtID)"),
            URLQueryItem(name: "order", value: "field_key.asc")
        ]
        guard let url = components?.url else {
            throw SupabaseCommunityError.invalidURL
        }

        var request = URLRequest(url: url)
        applyRESTHeaders(to: &request, accessToken: session.accessToken)
        let rows: [CourtFactUserVoteDTO] = try await performDecodedRequest(request)
        return rows.compactMap(\.vote)
    }

    func fetchVibeSummaries(courtID: String) async throws -> [CourtVibeSummary] {
        var components = URLComponents(
            url: SupabaseConfig.projectURL.appending(path: "/rest/v1/court_vibe_summaries"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "court_id", value: "eq.\(courtID)"),
            URLQueryItem(name: "order", value: "category.asc,percentage.desc")
        ]
        guard let url = components?.url else {
            throw SupabaseCommunityError.invalidURL
        }

        var request = URLRequest(url: url)
        applyRESTHeaders(to: &request, accessToken: SupabaseConfig.publishableKey)
        let rows: [CourtVibeSummaryDTO] = try await performDecodedRequest(request)
        return rows.compactMap(\.summary)
    }

    func fetchUserVibeVotes(courtID: String, session: ContributorSession?) async throws -> [CourtVibeUserVote] {
        guard let session else { return [] }
        var components = URLComponents(
            url: SupabaseConfig.projectURL.appending(path: "/rest/v1/court_vibe_votes"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "select", value: "court_id,category,option"),
            URLQueryItem(name: "court_id", value: "eq.\(courtID)"),
            URLQueryItem(name: "order", value: "category.asc")
        ]
        guard let url = components?.url else {
            throw SupabaseCommunityError.invalidURL
        }

        var request = URLRequest(url: url)
        applyRESTHeaders(to: &request, accessToken: session.accessToken)
        let rows: [CourtVibeUserVoteDTO] = try await performDecodedRequest(request)
        return rows.compactMap(\.vote)
    }

    func submitVibeVote(courtID: String, category: CourtVibeCategory, option: CourtVibeOption, session: ContributorSession?) async throws {
        guard let session else {
            throw SupabaseCommunityError.missingSession
        }

        var components = URLComponents(
            url: SupabaseConfig.projectURL.appending(path: "/rest/v1/court_vibe_votes"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "on_conflict", value: "court_id,user_id,category")
        ]
        guard let url = components?.url else {
            throw SupabaseCommunityError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyRESTHeaders(to: &request, accessToken: session.accessToken)
        request.setValue("resolution=merge-duplicates,return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONEncoder.snakeCase.encode(
            VibeVoteRequest(courtId: courtID, category: category.rawValue, option: option.rawValue)
        )

        try await performEmptyRequest(request)
    }

    func fetchSavedCourtIDs(session: ContributorSession?) async throws -> Set<String> {
        guard let session else { return [] }
        var components = URLComponents(
            url: SupabaseConfig.projectURL.appending(path: "/rest/v1/saved_courts"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "select", value: "court_id"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ]
        guard let url = components?.url else {
            throw SupabaseCommunityError.invalidURL
        }

        var request = URLRequest(url: url)
        applyRESTHeaders(to: &request, accessToken: session.accessToken)
        let rows: [SavedCourtDTO] = try await performDecodedRequest(request)
        return Set(rows.map(\.courtId))
    }

    func saveCourt(courtID: String, session: ContributorSession?) async throws {
        guard let session else {
            throw SupabaseCommunityError.missingSession
        }

        var components = URLComponents(
            url: SupabaseConfig.projectURL.appending(path: "/rest/v1/saved_courts"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "on_conflict", value: "user_id,court_id")
        ]
        guard let url = components?.url else {
            throw SupabaseCommunityError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyRESTHeaders(to: &request, accessToken: session.accessToken)
        request.setValue("resolution=ignore-duplicates,return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONEncoder.snakeCase.encode(SavedCourtDTO(courtId: courtID))
        try await performEmptyRequest(request)
    }

    func removeSavedCourt(courtID: String, session: ContributorSession?) async throws {
        guard let session else {
            throw SupabaseCommunityError.missingSession
        }

        var components = URLComponents(
            url: SupabaseConfig.projectURL.appending(path: "/rest/v1/saved_courts"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "court_id", value: "eq.\(courtID)")
        ]
        guard let url = components?.url else {
            throw SupabaseCommunityError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        applyRESTHeaders(to: &request, accessToken: session.accessToken)
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        try await performEmptyRequest(request)
    }

    func syncSavedCourtIDs(_ courtIDs: Set<String>, session: ContributorSession?) async throws -> Set<String> {
        guard let session else { return courtIDs }
        for courtID in courtIDs {
            try await saveCourt(courtID: courtID, session: session)
        }
        return try await fetchSavedCourtIDs(session: session)
    }

    private func applyRESTHeaders(to request: inout URLRequest, accessToken: String) {
        request.setValue(SupabaseConfig.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 12
    }

    private func performDecodedRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseCommunityError.invalidResponse
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            let message = String(data: data, encoding: .utf8) ?? "No response body"
            throw SupabaseCommunityError.requestFailed(statusCode: httpResponse.statusCode, message: message)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }

    private func performEmptyRequest(_ request: URLRequest) async throws {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseCommunityError.invalidResponse
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            let message = String(data: data, encoding: .utf8) ?? "No response body"
            throw SupabaseCommunityError.requestFailed(statusCode: httpResponse.statusCode, message: message)
        }
    }
}

private struct SignInWithIDTokenRequest: Encodable {
    var provider: String
    var idToken: String
    var nonce: String
}

private struct SupabaseAuthResponse: Decodable {
    var accessToken: String
    var refreshToken: String?
    var expiresIn: Int?
    var user: SupabaseAuthUser
}

private struct SupabaseAuthUser: Decodable {
    var id: String
    var email: String?
}

private struct FactVoteRequest: Encodable {
    var courtId: String
    var fieldKey: String
    var voteValue: String
}

private struct VibeVoteRequest: Encodable {
    var courtId: String
    var category: String
    var option: String
}

private struct CourtVibeSummaryDTO: Decodable {
    var courtId: String
    var category: String
    var option: String
    var voteCount: Int
    var categoryTotal: Int
    var percentage: Int

    var summary: CourtVibeSummary? {
        guard let category = CourtVibeCategory(rawValue: category),
              let option = CourtVibeOption(rawValue: option) else {
            return nil
        }
        return CourtVibeSummary(
            courtID: courtId,
            category: category,
            option: option,
            voteCount: voteCount,
            categoryTotal: categoryTotal,
            percentage: percentage
        )
    }
}

private struct CourtFactVoteSummaryDTO: Decodable {
    var courtId: String
    var fieldKey: String
    var voteValue: String
    var voteCount: Int
    var fieldTotal: Int
    var percentage: Int

    var summary: CourtFactVoteSummary? {
        guard let field = CommunityFactField(rawValue: fieldKey) else {
            return nil
        }
        return CourtFactVoteSummary(
            courtID: courtId,
            field: field,
            value: voteValue,
            voteCount: voteCount,
            fieldTotal: fieldTotal,
            percentage: percentage
        )
    }
}

private struct CourtFactUserVoteDTO: Decodable {
    var courtId: String
    var fieldKey: String
    var voteValue: String

    var vote: CourtFactUserVote? {
        guard let field = CommunityFactField(rawValue: fieldKey) else {
            return nil
        }
        return CourtFactUserVote(courtID: courtId, field: field, value: voteValue)
    }
}

private struct CourtVibeUserVoteDTO: Decodable {
    var courtId: String
    var category: String
    var option: String

    var vote: CourtVibeUserVote? {
        guard let category = CourtVibeCategory(rawValue: category),
              let option = CourtVibeOption(rawValue: option) else {
            return nil
        }
        return CourtVibeUserVote(courtID: courtId, category: category, option: option)
    }
}

private struct SavedCourtDTO: Codable {
    var courtId: String
}

private struct CommunitySessionKeychain {
    private let service = "com.acewang.blacktop.community-session"
    private let account = "supabase-session"

    func load() -> ContributorSession? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        return try? JSONDecoder().decode(ContributorSession.self, from: data)
    }

    func save(_ session: ContributorSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        clear()

        var query = baseQuery
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(query as CFDictionary, nil)
    }

    func clear() {
        SecItemDelete(baseQuery as CFDictionary)
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

private extension JSONEncoder {
    static var snakeCase: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}
