import WidgetKit
import SwiftUI

struct SiteListProvider<T: HomeWidgetData>: IntentTimelineProvider {

    let service: StatsWidgetsService
    let placeholderContent: T
    let widgetKind: StatsWidgetKind

    // refresh interval of the widget, in minutes
    let refreshInterval = 30
    // minimum elapsed time, in minutes, before new data are fetched from the backend.
    let minElapsedTimeToRefresh = 1

    private var defaultSiteID: Int? {

        UserDefaults(suiteName: WPAppGroupName)?.object(forKey: AppConfiguration.Widget.Stats.userDefaultsSiteIdKey) as? Int
    }

    func placeholder(in context: Context) -> StatsWidgetEntry {
        StatsWidgetEntry.siteSelected(placeholderContent, context)
    }

    func getSnapshot(for configuration: SelectSiteIntent, in context: Context, completion: @escaping (StatsWidgetEntry) -> Void) {
        if let widgetData = cachedWidgetData(configuration) {
            completion(.siteSelected(widgetData, context))
        } else {
            completion(.siteSelected(placeholderContent, context))
        }
    }

    func getTimeline(for configuration: SelectSiteIntent, in context: Context, completion: @escaping (Timeline<StatsWidgetEntry>) -> Void) {
        guard let defaults = UserDefaults(suiteName: WPAppGroupName) else {
            completion(Timeline(entries: [.noData(widgetKind)], policy: .never))
            return
        }
        guard !defaults.bool(forKey: AppConfiguration.Widget.Stats.userDefaultsJetpackFeaturesDisabledKey) else {
            completion(Timeline(entries: [.disabled(widgetKind)], policy: .never))
            return
        }
        guard defaultSiteID != nil else {
            let loggedIn = defaults.bool(forKey: AppConfiguration.Widget.Stats.userDefaultsLoggedInKey)

            if loggedIn {
                completion(Timeline(entries: [.noSite(widgetKind)], policy: .never))
            } else {
                completion(Timeline(entries: [.loggedOut(widgetKind)], policy: .never))
            }
            return
        }

        guard let widgetData = cachedWidgetData(configuration) else {
            completion(Timeline(entries: [.noData(widgetKind)], policy: .never))
            return
        }

        let date = Date()
        let nextRefreshDate = Calendar.current.date(byAdding: .minute, value: refreshInterval, to: date) ?? date
        let elapsedTime = abs(Calendar.current.dateComponents([.minute], from: widgetData.date, to: date).minute ?? 0)

        let privateCompletion = { (timelineEntry: StatsWidgetEntry) in
            let timeline = Timeline(entries: [timelineEntry], policy: .after(nextRefreshDate))
            completion(timeline)
        }

        // if cached data are "too old", refresh them from the backend, otherwise keep them
        guard elapsedTime > minElapsedTimeToRefresh else {

            privateCompletion(.siteSelected(widgetData, context))
            return
        }

        service.fetchStats(for: widgetData) { result in

            switch result {
            case .failure(let error):
                DDLogError("StatsWidgets: failed to fetch remote stats. Returned error: \(error.localizedDescription)")

                privateCompletion(.siteSelected(widgetData, context))

            case .success(let newWidgetData):

                privateCompletion(.siteSelected(newWidgetData, context))
            }
        }
    }
}

// MARK: - Widget Data

private extension SiteListProvider {
    /// Returns cached widget data based on the selected site when editing widget and the default site.
    /// Configuration.site is nil until IntentHandler is initialized.
    /// Configuration.site can have old value after logging in with a different account. No way to reset configuration when the user logs out.
    /// Using defaultSiteID if both of these cases.
    /// - Parameters:
    ///   - configuration: Configuration of the Widget Site Selection Intent
    /// - Returns: Widget data
    func cachedWidgetData(_ configuration: SelectSiteIntent) -> T? {
        var siteID: Int?

        if let siteIdentifier = configuration.site?.identifier, let siteIdentifierInt = Int(siteIdentifier) {
            /// - Note: If `config.site?.identifier` has value but there's no widget data,
            /// it means that this identifier comes from a previously logged in account
            siteID = siteIdentifierInt
        } else {
            if let defaultSiteID {
                siteID = defaultSiteID
            }
        }

        guard let data = T.read(), let siteID else {
            return nil
        }

        return data[siteID]
    }
}

enum StatsWidgetKind {
    case today
    case allTime
    case thisWeek
}
