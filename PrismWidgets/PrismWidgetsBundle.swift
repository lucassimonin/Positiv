import WidgetKit
import SwiftUI

@main
struct PrismWidgetsBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        AffirmationsWidget()
        EventCountdownWidget()
        ArtWidget()
    }
}
