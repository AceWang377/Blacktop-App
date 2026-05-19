import Foundation

struct ContributorSession: Codable, Equatable {
    var userID: String
    var email: String?
    var accessToken: String
    var refreshToken: String?
    var expiresAt: Date?

    var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt <= Date().addingTimeInterval(60)
    }
}

struct CommunityFactOption: Identifiable, Hashable {
    var id: String { value }
    let value: String
    let english: String
    let chinese: String

    func label(_ language: AppLanguage) -> String {
        language == .simplifiedChinese ? chinese : english
    }
}

enum CommunityFactField: String, CaseIterable, Identifiable {
    case drynessAfterRain = "dryness_after_rain"
    case hasNets = "has_nets"
    case hasLights = "has_lights"
    case rimHeight = "rim_height"
    case rimType = "rim_type"
    case courtSpace = "court_space"
    case courtCleanliness = "court_cleanliness"
    case priceType = "price_type"
    case courtType = "court_type"
    case hasToilets = "has_toilets"
    case hasDrinkingWater = "has_drinking_water"
    case hasParking = "has_parking"

    var id: String { rawValue }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .drynessAfterRain: language == .simplifiedChinese ? "雨后状态" : "After rain"
        case .hasNets: language == .simplifiedChinese ? "篮网" : "Nets"
        case .hasLights: language == .simplifiedChinese ? "灯光" : "Lights"
        case .rimHeight: language == .simplifiedChinese ? "篮筐高度" : "Rim height"
        case .rimType: language == .simplifiedChinese ? "篮筐类型" : "Rim type"
        case .courtSpace: language == .simplifiedChinese ? "空间" : "Space"
        case .courtCleanliness: language == .simplifiedChinese ? "清洁度" : "Cleanliness"
        case .priceType: language == .simplifiedChinese ? "费用" : "Cost"
        case .courtType: language == .simplifiedChinese ? "场地类型" : "Court type"
        case .hasToilets: language == .simplifiedChinese ? "厕所" : "Toilets"
        case .hasDrinkingWater: language == .simplifiedChinese ? "饮水" : "Water"
        case .hasParking: language == .simplifiedChinese ? "停车" : "Parking"
        }
    }

    func currentValue(for court: Court, language: AppLanguage) -> String {
        switch self {
        case .drynessAfterRain: court.drynessAfterRain.displayName(language)
        case .hasNets: court.hasNets.displayName(language)
        case .hasLights: court.hasLights.displayName(language)
        case .rimHeight: court.rimHeight.displayName(language)
        case .rimType: court.rimType.displayName(language)
        case .courtSpace: court.courtSpace.displayName(language)
        case .courtCleanliness: court.courtCleanliness.displayName(language)
        case .priceType: court.priceType.displayName(language)
        case .courtType: court.courtType.displayName(language)
        case .hasToilets: court.hasToilets.displayName(language)
        case .hasDrinkingWater: court.hasDrinkingWater.displayName(language)
        case .hasParking: court.hasParking.displayName(language)
        }
    }

    func options(_ language: AppLanguage) -> [CommunityFactOption] {
        switch self {
        case .drynessAfterRain:
            return [
                CommunityFactOption(value: "driesFast", english: "Dries fast", chinese: "干得快"),
                CommunityFactOption(value: "slowToDry", english: "Slow to dry", chinese: "干得慢"),
                CommunityFactOption(value: "puddlesCommon", english: "Puddles common", chinese: "容易积水"),
                CommunityFactOption(value: "indoorUnaffected", english: "Indoor / no rain impact", chinese: "室内 / 雨天无影响")
            ]
        case .hasNets:
            return [
                CommunityFactOption(value: "all", english: "All hoops have nets", chinese: "所有篮筐有网"),
                CommunityFactOption(value: "some", english: "Some hoops have nets", chinese: "部分有网"),
                CommunityFactOption(value: "none", english: "No nets", chinese: "无篮网")
            ]
        case .hasLights, .hasToilets, .hasDrinkingWater, .hasParking:
            if self == .hasLights {
                return [
                    CommunityFactOption(value: "yes", english: "Yes", chinese: "有"),
                    CommunityFactOption(value: "no", english: "No", chinese: "没有"),
                    CommunityFactOption(value: "sometimes", english: "Sometimes", chinese: "有时")
                ]
            }
            return [
                CommunityFactOption(value: "yes", english: "Yes", chinese: "有"),
                CommunityFactOption(value: "no", english: "No", chinese: "没有"),
                CommunityFactOption(value: "nearby", english: "Nearby", chinese: "附近有")
            ]
        case .rimHeight:
            return [
                CommunityFactOption(value: "standard", english: "Standard height", chinese: "标准高度"),
                CommunityFactOption(value: "tooLow", english: "Too low", chinese: "偏低"),
                CommunityFactOption(value: "tooHigh", english: "Too high", chinese: "偏高"),
                CommunityFactOption(value: "mixed", english: "Mixed heights", chinese: "高度不一")
            ]
        case .rimType:
            return [
                CommunityFactOption(value: "singleRim", english: "Single rim", chinese: "单层篮筐"),
                CommunityFactOption(value: "doubleRim", english: "Double rim", chinese: "双层篮筐"),
                CommunityFactOption(value: "mixed", english: "Mixed rims", chinese: "篮筐类型不一")
            ]
        case .courtSpace:
            return [
                CommunityFactOption(value: "spacious", english: "Spacious", chinese: "空间充足"),
                CommunityFactOption(value: "tightEdges", english: "Tight edges", chinese: "边线较近"),
                CommunityFactOption(value: "fencedTight", english: "Fence is close", chinese: "围栏较近"),
                CommunityFactOption(value: "sharedSpace", english: "Shared space", chinese: "共享空间")
            ]
        case .courtCleanliness:
            return [
                CommunityFactOption(value: "clean", english: "Clean", chinese: "干净"),
                CommunityFactOption(value: "acceptable", english: "Acceptable", chinese: "可以接受"),
                CommunityFactOption(value: "littered", english: "Littered", chinese: "有垃圾"),
                CommunityFactOption(value: "poor", english: "Poor", chinese: "较差")
            ]
        case .priceType:
            return [
                CommunityFactOption(value: "free", english: "Free", chinese: "免费"),
                CommunityFactOption(value: "paid", english: "Paid", chinese: "收费"),
                CommunityFactOption(value: "mixed", english: "Mixed", chinese: "部分收费")
            ]
        case .courtType:
            return [
                CommunityFactOption(value: "outdoor", english: "Outdoor", chinese: "室外"),
                CommunityFactOption(value: "indoor", english: "Indoor", chinese: "室内"),
                CommunityFactOption(value: "mixed", english: "Mixed", chinese: "室内外混合")
            ]
        }
    }
}

struct CourtFactUpdateDraft: Equatable {
    var field: CommunityFactField = .drynessAfterRain
    var value: String?

    var isReady: Bool {
        value?.isEmpty == false
    }
}

enum CourtVibeCategory: String, CaseIterable, Identifiable, Codable {
    case usualIntensity = "usual_intensity"
    case bestFor = "best_for"
    case joinInFeel = "join_in_feel"

    var id: String { rawValue }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .usualIntensity: language == .simplifiedChinese ? "平时强度" : "Usual intensity"
        case .bestFor: language == .simplifiedChinese ? "适合什么局" : "Best for"
        case .joinInFeel: language == .simplifiedChinese ? "加入难度" : "Join-in feel"
        }
    }

    func subtitle(_ language: AppLanguage) -> String {
        switch self {
        case .usualIntensity:
            language == .simplifiedChinese ? "这个球场平时更偏轻松还是竞争？" : "Is this court usually relaxed or competitive?"
        case .bestFor:
            language == .simplifiedChinese ? "帮助新来的球员判断适不适合自己。" : "Help new players decide if the run fits them."
        case .joinInFeel:
            language == .simplifiedChinese ? "这里是否容易加入陌生人的局？" : "How easy is it to join a run here?"
        }
    }

    var options: [CourtVibeOption] {
        switch self {
        case .usualIntensity:
            [.calm, .balanced, .competitive]
        case .bestFor:
            [.soloShooting, .casualRuns, .seriousPickup, .beginners, .threeOnThree, .afterWork]
        case .joinInFeel:
            [.welcoming, .regularsFirst, .hardToJoin]
        }
    }
}

enum CourtVibeOption: String, CaseIterable, Identifiable, Codable {
    case calm
    case balanced
    case competitive
    case soloShooting = "solo_shooting"
    case casualRuns = "casual_runs"
    case seriousPickup = "serious_pickup"
    case beginners
    case threeOnThree = "three_on_three"
    case afterWork = "after_work"
    case welcoming
    case regularsFirst = "regulars_first"
    case hardToJoin = "hard_to_join"

    var id: String { rawValue }

    func label(_ language: AppLanguage) -> String {
        switch self {
        case .calm: language == .simplifiedChinese ? "轻松局" : "Calm"
        case .balanced: language == .simplifiedChinese ? "强度适中" : "Balanced"
        case .competitive: language == .simplifiedChinese ? "竞争强" : "Competitive"
        case .soloShooting: language == .simplifiedChinese ? "只练投篮" : "Solo shooting"
        case .casualRuns: language == .simplifiedChinese ? "休闲野球" : "Casual runs"
        case .seriousPickup: language == .simplifiedChinese ? "认真野球" : "Serious pickup"
        case .beginners: language == .simplifiedChinese ? "新手友好" : "Beginner friendly"
        case .threeOnThree: language == .simplifiedChinese ? "3v3" : "3v3"
        case .afterWork: language == .simplifiedChinese ? "下班后" : "After work"
        case .welcoming: language == .simplifiedChinese ? "容易加入" : "Welcoming"
        case .regularsFirst: language == .simplifiedChinese ? "熟人优先" : "Regulars first"
        case .hardToJoin: language == .simplifiedChinese ? "不太好加入" : "Hard to join"
        }
    }

    var tone: FactTone {
        switch self {
        case .calm, .soloShooting, .beginners, .welcoming: .positive
        case .competitive, .hardToJoin: .warning
        default: .neutral
        }
    }
}

struct CourtVibeSummary: Identifiable, Hashable, Decodable {
    var courtID: String
    var category: CourtVibeCategory
    var option: CourtVibeOption
    var voteCount: Int
    var categoryTotal: Int
    var percentage: Int

    var id: String {
        "\(courtID)-\(category.rawValue)-\(option.rawValue)"
    }
}
