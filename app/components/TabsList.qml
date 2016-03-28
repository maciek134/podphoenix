/*
 * Copyright 2015-2016 Podbird Team
 *
 * This file is part of Podbird.
 *
 * Podbird is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * Podbird is distributed in the hope that it will be useful,
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
            text: i18n.tr("Add New Podcasts")
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
