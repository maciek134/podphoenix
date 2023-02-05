/*
 * Copyright 2015-2016 Podphoenix Team
 *
 * This file is part of Podphoenix.
 *
 * Podphoenix is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * Podphoenix is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3

ActionList {
    id: tabsList

    children: [
        Action {
            iconName: "slideshow"
            text: i18n.tr("Episodes")
            enabled: tabs.selectedTab !== episodesTab
            onTriggered: {
                tabs.selectedTabIndex = 0
            }
        },

        Action {
            iconName: "add"
            text: i18n.tr("Add New Podcasts")
            enabled: tabs.selectedTab !== searchTab
            onTriggered: {
                tabs.selectedTabIndex = 1
            }
        },

        Action {
            iconSource: Qt.resolvedUrl("../graphics/podcast-symbol.png")
            text: i18n.tr("Podcasts")
            enabled: tabs.selectedTab !== podcastTab
            onTriggered: {
                tabs.selectedTabIndex = 2
            }
        },

        Action {
            iconName: "settings"
            text: i18n.tr("Settings")
            enabled: tabs.selectedTab !== settingsTab
            onTriggered: {
                tabs.selectedTabIndex = 3
            }
        }
    ]
}
