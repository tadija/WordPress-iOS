import SwiftUI

struct SingleStatView: View {

    let viewData: GroupedViewData

    var body: some View {
        VStack(alignment: .leading) {
            FlexibleCard(axis: .vertical, title: viewData.widgetTitle, value: .description(viewData.siteName), lineLimit: 2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
            VerticalCard(title: viewData.upperLeftTitle, value: viewData.upperLeftValue, largeText: true)
            Spacer()

            LastUpdateIndicator(lastUpdate: viewData.lastUpdate)
        }
    }
}
