import QtQuick 2.4
import Ubuntu.Components 1.3

ActionList {
    id: tabsList

    property int currentTab: tabs.selectedTabIndex

    children: [
        Action {
            text: i18n.tr("What's New")
            visible: currentTab !== 0
            onTriggered: {
                tabs.selectedTabIndex = 0
            }
        },

        Action {
            text: i18n.tr("Podcasts")
            visible: currentTab !== 1
            onTriggered: {
                tabs.selectedTabIndex = 1
            }
        },

        Action {
            text: i18n.tr("Add new podcasts")
            visible: currentTab !== 2
            onTriggered: {
                tabs.selectedTabIndex = 2
            }
        },

        Action {
            text: i18n.tr("Settings")
            visible: currentTab !== 3
            onTriggered: {
                tabs.selectedTabIndex = 3
            }
        }
    ]
}
