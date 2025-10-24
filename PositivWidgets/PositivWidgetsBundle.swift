import WidgetKit
import SwiftUI

@main
struct MyWidgetsBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        AffirmationsWidget()
        EventCountdownWidget()
    }
}
