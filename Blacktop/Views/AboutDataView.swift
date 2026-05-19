import SwiftUI

struct AboutDataView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(store.localized("About the data", "关于数据"))
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text(store.localized("Blacktop combines public map records and manual court checks.", "Blacktop 结合公开地图记录和人工球场检查。"))
                            .font(.body.weight(.medium))
                            .foregroundStyle(.white.opacity(0.66))
                    }

                    SectionCard(title: store.localized("What Blacktop tracks", "Blacktop 记录什么")) {
                        Text(store.localized("Court type, access, rain impact, rim quality, lighting, facilities, space, cleanliness, and peak times.", "球场类型、开放方式、雨天影响、篮筐质量、灯光、设施、空间、清洁度和高峰时间。"))
                            .foregroundStyle(.white.opacity(0.62))
                    }

                    SectionCard(title: store.localized("Sources", "来源")) {
                        VStack(alignment: .leading, spacing: 12) {
                            FactRow(title: "OSM", value: "OpenStreetMap contributors")
                            FactRow(title: store.localized("Map records", "地图记录"), value: store.localized("Public court candidates", "公开球场候选数据"))
                            FactRow(title: store.localized("Manual", "人工"), value: store.localized("Blacktop checks", "Blacktop 检查"))
                        }
                    }

                    SectionCard(title: store.localized("Current data stats", "当前数据统计")) {
                        FactRow(title: store.copy(.courts), value: "\(store.totalCourtCount)")
                    }
                }
                .padding(20)
                .padding(.bottom, 110)
            }
            .pageBackground()
        }
    }
}
