import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), totalWealth: "₩ 204,513,888", progressPercent: "은퇴 달성률 45.2%")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(getEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let timeline = Timeline(entries: [getEntry()], policy: .atEnd)
        completion(timeline)
    }
    
    private func getEntry() -> SimpleEntry {
        let userDefaults = UserDefaults(suiteName: "group.com.hadoseo.wealthflow")
        let totalWealth = userDefaults?.string(forKey: "total_wealth") ?? "₩ 0"
        let progressPercent = userDefaults?.string(forKey: "progress_percent") ?? "은퇴 달성률 0.0%"
        return SimpleEntry(date: Date(), totalWealth: totalWealth, progressPercent: progressPercent)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let totalWealth: String
    let progressPercent: String
}

struct WealthWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("내 자산 현황")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(red: 133/255, green: 163/255, blue: 155/255))
            
            Text(entry.totalWealth)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            
            Text(entry.progressPercent)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(red: 52/255, green: 211/255, blue: 153/255))
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

let widgetGradient = LinearGradient(
    gradient: Gradient(colors: [
        Color(red: 30/255, green: 51/255, blue: 46/255),
        Color(red: 11/255, green: 20/255, blue: 18/255)
    ]),
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

struct WealthWidget: Widget {
    let kind: String = "WealthWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                WealthWidgetEntryView(entry: entry)
                    .containerBackground(widgetGradient, for: .widget)
            } else {
                WealthWidgetEntryView(entry: entry)
                    .padding()
                    .background(widgetGradient)
            }
        }
        .configurationDisplayName("내 자산 위젯")
        .description("현재 총 자산과 은퇴 목표 달성률을 실시간으로 확인하세요.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
