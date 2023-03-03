import SwiftUI
import WidgetKit

struct LastUpdateIndicator: View {

    var lastUpdate: Date

    var body: some View {
        Text(lastUpdateText)
            .font(.caption2)
            .foregroundColor(.secondary)
    }

    private var lastUpdateText: String {
        /// - TODO: localize label later
        let label = "Updated"
        let value = lastUpdateFormatted
        return "\(label): \(value)"
    }

    private var lastUpdateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: lastUpdate)
    }
}

struct LastUpdateIndicator_Previews: PreviewProvider {
    static var previews: some View {
        LastUpdateIndicator(lastUpdate: .init())
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
