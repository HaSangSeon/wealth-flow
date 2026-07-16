//
//  WealthWidgetLiveActivity.swift
//  WealthWidget
//
//  Created by Ha Sang Seon on 7/14/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct WealthWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct WealthWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WealthWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension WealthWidgetAttributes {
    fileprivate static var preview: WealthWidgetAttributes {
        WealthWidgetAttributes(name: "World")
    }
}

extension WealthWidgetAttributes.ContentState {
    fileprivate static var smiley: WealthWidgetAttributes.ContentState {
        WealthWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: WealthWidgetAttributes.ContentState {
         WealthWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: WealthWidgetAttributes.preview) {
   WealthWidgetLiveActivity()
} contentStates: {
    WealthWidgetAttributes.ContentState.smiley
    WealthWidgetAttributes.ContentState.starEyes
}
