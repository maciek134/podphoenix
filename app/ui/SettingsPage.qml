/*
 * Copyright 2015 Podbird Team
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

import QtQuick 2.3
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 1.0 as ListItem

Page {
    id: settingsPage

    Column {
        id: settingsColumn

        anchors.fill: parent

        ListItem.Header {
            text: i18n.tr("General Settings")
        }

        ListItem.SingleValue {
            progression: true
            text: i18n.tr("Theme")
            value: podbird.settings.themeName.split(".qml")[0]
            onClicked: mainStack.push(Qt.resolvedUrl("../settings/ThemeSetting.qml"))
        }

        ListItem.Header {
            text: i18n.tr("Podcast Episode Settings")
        }

        ListItem.Standard {
            text: i18n.tr("Hide listened episodes")
            control: Switch {
                checked: podbird.settings.hideListened
                onClicked: podbird.settings.hideListened = checked
            }
        }

        ListItem.Base {
            height: units.gu(10)
            progression: true
            onClicked: mainStack.push(Qt.resolvedUrl("../settings/CleanSetting.qml"))
            Column {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.left: parent.left
                Label {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: i18n.tr("Automatically delete old episodes")
                }

                Label {
                    fontSize: "small"
                    color: podbird.theme.baseSubText
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: i18n.tr("Delete episodes that are older than a given number of days for each podcast")
                }
            }
        }

        ListItem.Standard {
            text: i18n.tr("Auto download on WiFi only")
            control: Switch {
                checked: podbird.settings.onlyWifiDownload
                onClicked: {
                    podbird.settings.onlyWifiDownload = checked
                }
            }
        }

        ListItem.Base {
            height: units.gu(10)
            progression: true
            onClicked: mainStack.push(Qt.resolvedUrl("../settings/DownloadSetting.qml"))
            Column {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.left: parent.left
                Label {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: i18n.tr("Automatically download new episodes")
                }

                Label {
                    fontSize: "small"
                    color: podbird.theme.baseSubText
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: i18n.tr("Default number of new episodes to download for each podcast")
                }
            }
        }
    }
}


