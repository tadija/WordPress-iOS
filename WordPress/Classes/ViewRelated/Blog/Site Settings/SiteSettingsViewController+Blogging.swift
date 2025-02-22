
extension SiteSettingsViewController {

    @objc var bloggingSettingsRowCount: Int {
        bloggingSettingsRows.count
    }

    @objc func tableView(_ tableView: UITableView, cellForBloggingSettingsInRow row: Int) -> UITableViewCell {
        switch bloggingSettingsRows[row] {
        case .reminders:
            return remindersTableViewCell
        case .prompts:
            return promptsTableViewCell
        }
    }

    @objc func tableView(_ tableView: UITableView, didSelectInBloggingSettingsAt indexPath: IndexPath) {
        switch bloggingSettingsRows[indexPath.row] {
        case .reminders:
            presentBloggingRemindersFlow(indexPath: indexPath)
        default:
            break
        }
    }

}

// MARK: - Private methods

private extension SiteSettingsViewController {
    enum BloggingSettingsRows {
        case reminders
        case prompts
    }

    var bloggingSettingsRows: [BloggingSettingsRows] {
        var rows = [BloggingSettingsRows]()
        if blog.areBloggingRemindersAllowed() {
            rows.append(.reminders)
        }
        if blog.isAccessibleThroughWPCom() && FeatureFlag.bloggingPromptsEnhancements.enabled {
            rows.append(.prompts)
        }
        return rows
    }

    // MARK: - Reminders

    var remindersTableViewCell: SettingTableViewCell {
        let cell = SettingTableViewCell(label: Strings.remindersTitle,
                                        editable: true,
                                        reuseIdentifier: nil)
        cell?.detailTextLabel?.adjustsFontSizeToFitWidth = true
        cell?.detailTextLabel?.minimumScaleFactor = 0.75
        cell?.accessoryType = .none
        cell?.textValue = schedule(for: blog)
        return cell ?? SettingTableViewCell()
    }


    func schedule(for blog: Blog) -> String {
        guard let scheduler = try? ReminderScheduleCoordinator() else {
            return ""
        }

        let formatter = BloggingRemindersScheduleFormatter()
        return formatter.shortScheduleDescription(for: scheduler.schedule(for: blog),
                                                  time: scheduler.scheduledTime(for: blog).toLocalTime()).string
    }

    func presentBloggingRemindersFlow(indexPath: IndexPath) {
        BloggingRemindersFlow.present(from: self, for: blog, source: .blogSettings) { [weak self] in
            guard let self = self,
                  let cell = self.tableView.cellForRow(at: indexPath) as? SettingTableViewCell else {
                return
            }

            cell.textValue = self.schedule(for: self.blog)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - Prompts

    var promptsTableViewCell: SwitchTableViewCell {
        let cell = SwitchTableViewCell()
        cell.name = Strings.promptsTitle
        cell.on = isPromptsSwitchEnabled
        cell.onChange = promptsSwitchOnChange
        return cell
    }

    var isPromptsSwitchEnabled: Bool {
        guard let siteID = blog.dotComID?.stringValue else {
            return false
        }

        return UserPersistentStoreFactory.instance().promptsEnabledSettings[siteID] ?? false
    }

    var promptsSwitchOnChange: (Bool) -> () {
        return { [weak self] isPromptsEnabled in
            WPAnalytics.track(.promptsSettingsShowPromptsTapped, properties: ["enabled": isPromptsEnabled])
            guard let siteID = self?.blog.dotComID?.stringValue else {
                return
            }
            let repository = UserPersistentStoreFactory.instance()
            var promptsEnabledSettings = repository.promptsEnabledSettings
            promptsEnabledSettings[siteID] = isPromptsEnabled
            repository.promptsEnabledSettings = promptsEnabledSettings
        }
    }

    // MARK: - Constants

    struct Strings {
        static let remindersTitle = NSLocalizedString("sitesettings.reminders.title",
                                                      value: "Reminders",
                                                      comment: "Label for the blogging reminders setting")
        static let promptsTitle = NSLocalizedString("sitesettings.prompts.title",
                                                    value: "Show prompts",
                                                    comment: "Label for the blogging prompts setting")
    }
}
