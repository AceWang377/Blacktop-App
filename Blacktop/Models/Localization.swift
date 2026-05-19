import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"

    var id: String { rawValue }

    var displayName: String {
        return switch self {
        case .english: "English"
        case .simplifiedChinese: "Simplified Chinese"
        }
    }

    var nativeName: String {
        return switch self {
        case .english: "English"
        case .simplifiedChinese: "简体中文"
        }
    }

    var shortName: String {
        return switch self {
        case .english: "EN"
        case .simplifiedChinese: "中"
        }
    }

    static var preferred: AppLanguage {
        Locale.preferredLanguages.first?.hasPrefix("zh") == true ? .simplifiedChinese : .english
    }
}

enum HLCopy {
    case languageTitle
    case languageSubtitle
    case languageContinue
    case introTitle
    case introSubtitle
    case introMapTitle
    case introMapSubtitle
    case introFactsTitle
    case introFactsSubtitle
    case introNoLoginTitle
    case introNoLoginSubtitle
    case startMap
    case chooseFacts
    case preferencesTitle
    case preferencesSubtitle
    case showCourtMap
    case skipFilters
    case courts
    case login
    case map
    case searchPlaceholder
    case searchThisArea
    case details
    case directions
    case outdoor
    case indoor
    case free
    case lights
    case dry
    case dryAfterRain
    case nets
    case standardRim
    case soloShooting
    case pickup
    case filters
    case filterSubtitle
    case courtType
    case conditions
    case rimAndHoop
    case use
    case reset
    case done
    case applyFilters
    case mapTab
    case profileTab
    case profileTitle
    case profileSubtitle
    case saved
    case verified
    case language
    case appLanguage
    case appLanguageSubtitle
    case importedWarning
    case incompleteWarning
    case rainWarning
    case rimNetWarning
    case readyWarning
    case refreshFailedCached

    func text(_ language: AppLanguage) -> String {
        switch language {
        case .english:
            english
        case .simplifiedChinese:
            chinese
        }
    }

    private var english: String {
        return switch self {
        case .languageTitle: "Choose your language"
        case .languageSubtitle: "Blacktop can start in English or Simplified Chinese. You can change this later from Profile."
        case .languageContinue: "Continue"
        case .introTitle: "Court facts before pickup."
        case .introSubtitle: "Blacktop helps you check real basketball court facts before you leave: surface, rain, nets, rim, lights, space and access."
        case .introMapTitle: "Find nearby courts"
        case .introMapSubtitle: "Browse courts on a live map and search by city, area or court name."
        case .introFactsTitle: "Check practical facts"
        case .introFactsSubtitle: "See useful details instead of ratings: dry surface, nets, rim height, lights and whether it is free."
        case .introNoLoginTitle: "No account needed"
        case .introNoLoginSubtitle: "Read the map immediately. Sign in later only if you want to vote or sync saved courts."
        case .startMap: "Start with map"
        case .chooseFacts: "Choose court facts"
        case .preferencesTitle: "What should the map surface first?"
        case .preferencesSubtitle: "Pick the factual court signals that matter for your next run."
        case .showCourtMap: "Show court map"
        case .skipFilters: "Skip filters"
        case .courts: "courts"
        case .login: "login"
        case .map: "map"
        case .searchPlaceholder: "Search city, court or area"
        case .searchThisArea: "Search this area"
        case .details: "Details"
        case .directions: "Directions"
        case .outdoor: "Outdoor"
        case .indoor: "Indoor"
        case .free: "Free"
        case .lights: "Lights"
        case .dry: "Dry"
        case .dryAfterRain: "Dry after rain"
        case .nets: "Nets"
        case .standardRim: "Standard rim"
        case .soloShooting: "Solo shooting"
        case .pickup: "Pickup"
        case .filters: "Filters"
        case .filterSubtitle: "Choose the court facts that matter."
        case .courtType: "Court type"
        case .conditions: "Conditions"
        case .rimAndHoop: "Rim and hoop"
        case .use: "Use"
        case .reset: "Reset"
        case .done: "Done"
        case .applyFilters: "Apply filters"
        case .mapTab: "Map"
        case .profileTab: "Profile"
        case .profileTitle: "Profile"
        case .profileSubtitle: "Browse courts without an account. Sign in only to vote or sync saved courts."
        case .saved: "saved"
        case .verified: "checked"
        case .language: "Language"
        case .appLanguage: "App language"
        case .appLanguageSubtitle: "Change the Blacktop interface language."
        case .importedWarning: "Court details come from public and partner datasets."
        case .incompleteWarning: "Some court details may be incomplete."
        case .rainWarning: "May be slippery after rain. Check before travelling."
        case .rimNetWarning: "Rim and net details can vary by court."
        case .readyWarning: "Key court facts are ready to check."
        case .refreshFailedCached: "Couldn't refresh courts. Showing cached data."
        }
    }

    private var chinese: String {
        return switch self {
        case .languageTitle: "选择语言"
        case .languageSubtitle: "Blacktop 支持英文和简体中文。之后也可以在 Profile 中修改。"
        case .languageContinue: "继续"
        case .introTitle: "出门前，先看清球场事实。"
        case .introSubtitle: "Blacktop 帮你在出发前查看真实篮球场信息：地面、雨后情况、篮网、篮筐、灯光、空间和开放方式。"
        case .introMapTitle: "在地图上找球场"
        case .introMapSubtitle: "查看附近球场，也可以按城市、区域或球场名称搜索。"
        case .introFactsTitle: "只看实用事实"
        case .introFactsSubtitle: "不做星级评分，重点展示干不干、有没有网、篮筐高度、灯光、是否免费。"
        case .introNoLoginTitle: "无需注册"
        case .introNoLoginSubtitle: "打开就能看地图。之后只有投票或同步收藏时才需要登录。"
        case .startMap: "进入地图"
        case .chooseFacts: "选择关注信息"
        case .preferencesTitle: "你最关心哪些球场信息？"
        case .preferencesSubtitle: "选择后，地图会优先显示符合这些事实条件的球场。"
        case .showCourtMap: "显示球场地图"
        case .skipFilters: "跳过筛选"
        case .courts: "球场"
        case .login: "登录"
        case .map: "地图"
        case .searchPlaceholder: "搜索城市、球场或区域"
        case .searchThisArea: "搜索此区域"
        case .details: "查看详情"
        case .directions: "导航"
        case .outdoor: "室外"
        case .indoor: "室内"
        case .free: "免费"
        case .lights: "有灯"
        case .dry: "干燥"
        case .dryAfterRain: "雨后可打"
        case .nets: "有篮网"
        case .standardRim: "标准篮筐"
        case .soloShooting: "适合投篮"
        case .pickup: "适合野球"
        case .filters: "筛选"
        case .filterSubtitle: "选择你关心的球场事实。"
        case .courtType: "球场类型"
        case .conditions: "场地状态"
        case .rimAndHoop: "篮筐与篮网"
        case .use: "使用方式"
        case .reset: "重置"
        case .done: "完成"
        case .applyFilters: "应用筛选"
        case .mapTab: "地图"
        case .profileTab: "我的"
        case .profileTitle: "我的"
        case .profileSubtitle: "无需账号即可浏览球场。只有投票或同步收藏时才需要登录。"
        case .saved: "收藏"
        case .verified: "已确认"
        case .language: "语言"
        case .appLanguage: "App 语言"
        case .appLanguageSubtitle: "切换 Blacktop 的界面语言。"
        case .importedWarning: "球场信息来自公开和合作数据。"
        case .incompleteWarning: "部分球场信息可能不完整。"
        case .rainWarning: "雨后可能湿滑，出发前建议再确认。"
        case .rimNetWarning: "篮筐和篮网情况可能因球场而异。"
        case .readyWarning: "关键球场事实已可查看。"
        case .refreshFailedCached: "暂时无法刷新球场，正在显示缓存数据。"
        }
    }
}

extension AppStore {
    func copy(_ key: HLCopy) -> String {
        key.text(appLanguage)
    }

    func localized(_ english: String, _ chinese: String) -> String {
        appLanguage == .simplifiedChinese ? chinese : english
    }
}

extension Court {
    func topFacts(language: AppLanguage) -> [CourtFact] {
        [
            CourtFact(label: courtType.displayName(language), tone: .neutral),
            CourtFact(label: priceType.displayName(language), tone: priceType == .free ? .positive : .neutral),
            CourtFact(label: drynessAfterRain.shortLabel(language), tone: drynessAfterRain.tone),
            CourtFact(label: hasNets.shortLabel(language), tone: hasNets.tone),
            CourtFact(label: hasLights.shortLightLabel(language), tone: hasLights == .yes ? .positive : hasLights == .no ? .warning : .unknown)
        ]
    }
}

extension CourtType {
    func displayName(_ language: AppLanguage) -> String {
        guard language == .simplifiedChinese else { return displayName }
        return switch self {
        case .indoor: "室内"
        case .outdoor: "室外"
        case .mixed: "室内外混合"
        case .unknown: "类型未知"
        }
    }
}

extension AccessType {
    func displayName(_ language: AppLanguage) -> String {
        guard language == .simplifiedChinese else { return displayName }
        return switch self {
        case .public: "公共开放"
        case .private: "私人场地"
        case .membersOnly: "会员限定"
        case .school: "学校场地"
        case .bookingRequired: "需要预约"
        case .unknown: "开放情况未知"
        }
    }
}

extension PriceType {
    func displayName(_ language: AppLanguage) -> String {
        guard language == .simplifiedChinese else { return displayName }
        return switch self {
        case .free: "免费"
        case .paid: "收费"
        case .mixed: "部分收费"
        case .unknown: "费用未知"
        }
    }
}

extension FactStatus {
    func displayName(_ language: AppLanguage) -> String {
        guard language == .simplifiedChinese else { return displayName }
        return switch self {
        case .yes: "是"
        case .no: "否"
        case .sometimes: "有时"
        case .unknown: "未知"
        }
    }

    func shortLightLabel(_ language: AppLanguage) -> String {
        guard language == .simplifiedChinese else { return shortLightLabel }
        return switch self {
        case .yes: "有灯"
        case .no: "无灯"
        case .sometimes: "灯光不稳定"
        case .unknown: "灯光未知"
        }
    }
}

extension DrynessAfterRain {
    func displayName(_ language: AppLanguage) -> String {
        guard language == .simplifiedChinese else { return displayName }
        return switch self {
        case .driesFast: "干得快"
        case .slowToDry: "干得慢"
        case .puddlesCommon: "容易积水"
        case .indoorUnaffected: "室内，雨天无影响"
        case .unknown: "干燥情况未知"
        }
    }

    func shortLabel(_ language: AppLanguage) -> String {
        guard language == .simplifiedChinese else { return shortLabel }
        return switch self {
        case .driesFast: "雨后可打"
        case .slowToDry: "干得慢"
        case .puddlesCommon: "易积水"
        case .indoorUnaffected: "雨天无影响"
        case .unknown: "雨后未知"
        }
    }
}

extension RainPlayable {
    func displayName(_ language: AppLanguage) -> String {
        guard language == .simplifiedChinese else { return displayName }
        return switch self {
        case .yes: "雨后可打"
        case .no: "雨后不可打"
        case .partially: "部分区域可打"
        case .indoorUnaffected: "雨天无影响"
        case .unknown: "雨天影响未知"
        }
    }
}

extension SurfaceType {
    func displayName(_ language: AppLanguage) -> String {
        guard language == .simplifiedChinese else { return displayName }
        return switch self {
        case .concrete: "水泥"
        case .asphalt: "沥青"
        case .rubber: "塑胶"
        case .wood: "木地板"
        case .synthetic: "合成地面"
        case .unknown: "地面未知"
        }
    }
}

extension CourtCleanliness {
    func displayName(_ language: AppLanguage) -> String {
        guard language == .simplifiedChinese else { return displayName }
        return switch self {
        case .clean: "干净"
        case .acceptable: "可以接受"
        case .littered: "有垃圾"
        case .poor: "较差"
        case .unknown: "清洁度未知"
        }
    }
}

extension CourtSpace {
    func displayName(_ language: AppLanguage) -> String {
        guard language == .simplifiedChinese else { return displayName }
        return switch self {
        case .spacious: "空间充足"
        case .tightEdges: "边线较近"
        case .fencedTight: "围栏较近"
        case .sharedSpace: "共享空间"
        case .unknown: "空间未知"
        }
    }
}

extension PeakTime {
    func displayName(_ language: AppLanguage) -> String {
        guard language == .simplifiedChinese else { return displayName }
        return switch self {
        case .weekdayEvening: "工作日晚上"
        case .weekendMorning: "周末上午"
        case .weekendAfternoon: "周末下午"
        case .lunchTime: "午间"
        case .unknown: "高峰未知"
        }
    }
}

extension NetsStatus {
    func displayName(_ language: AppLanguage) -> String {
        guard language == .simplifiedChinese else { return displayName }
        return switch self {
        case .all: "所有篮筐有网"
        case .some: "部分篮筐有网"
        case .none: "无篮网"
        case .unknown: "篮网未知"
        }
    }

    func shortLabel(_ language: AppLanguage) -> String {
        guard language == .simplifiedChinese else { return shortLabel }
        return switch self {
        case .all: "有篮网"
        case .some: "部分有网"
        case .none: "无篮网"
        case .unknown: "篮网未知"
        }
    }
}

extension RimHeight {
    func displayName(_ language: AppLanguage) -> String {
        guard language == .simplifiedChinese else { return displayName }
        return switch self {
        case .standard: "标准高度"
        case .tooLow: "偏低"
        case .tooHigh: "偏高"
        case .mixed: "高度不一"
        case .unknown: "高度未知"
        }
    }
}

extension RimType {
    func displayName(_ language: AppLanguage) -> String {
        guard language == .simplifiedChinese else { return displayName }
        return switch self {
        case .singleRim: "单层篮筐"
        case .doubleRim: "双层篮筐"
        case .mixed: "篮筐类型混合"
        case .unknown: "篮筐类型未知"
        }
    }
}

extension HardwareCondition {
    func displayName(_ language: AppLanguage) -> String {
        guard language == .simplifiedChinese else { return displayName }
        return switch self {
        case .good: "良好"
        case .worn: "磨损"
        case .damaged: "损坏"
        case .missing: "缺失"
        case .bent: "弯曲"
        case .loose: "松动"
        case .unknown: "未知"
        }
    }
}

extension EveningAccess {
    func displayName(_ language: AppLanguage) -> String {
        guard language == .simplifiedChinese else { return displayName }
        return switch self {
        case .yes: "晚上可用"
        case .no: "晚上不可用"
        case .seasonal: "季节性晚上开放"
        case .unknown: "晚上开放未知"
        }
    }
}

extension FacilityStatus {
    func displayName(_ language: AppLanguage) -> String {
        guard language == .simplifiedChinese else { return displayName }
        return switch self {
        case .yes: "有"
        case .no: "无"
        case .nearby: "附近有"
        case .unknown: "未知"
        }
    }
}
