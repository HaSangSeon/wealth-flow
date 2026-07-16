//
//  WealthWidgetBundle.swift
//  WealthWidget
//
//  Created by Ha Sang Seon on 7/14/26.
//

import WidgetKit
import SwiftUI

@main
struct WealthWidgetBundle: WidgetBundle {
    var body: some Widget {
        WealthWidget()
        WealthWidgetControl()
        WealthWidgetLiveActivity()
    }
}
