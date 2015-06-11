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

import QtQuick 2.4
import Ubuntu.Components 1.2
import "../components"

Page {
    id: settingsPage

    Flickable {
        id: flickable

        anchors.fill: parent
        contentHeight: settingsColumn.height + units.gu(8)
        contentWidth: parent.width

        Column {
            id: settingsColumn

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }

            HeaderListItem {
                // TRANSLATORS: Shortened form of "Miscellaneous" which is shown to denote other setting options
                // that doesn't fit into any other category.
                title: i18n.tr("General Settings")
            }

            SingleValueListItem {
                divider.visible: false
                text: i18n.tr("Theme")
                value: podbird.settings.themeName.split(".qml")[0] === "Light" ? i18n.tr("Light") : i18n.tr("Dark")
                onClicked: mainStack.push(Qt.resolvedUrl("../settings/ThemeSetting.qml"))
            }

            HeaderListItem {
                title: i18n.tr("Podcast Episode Settings")
            }

            ListItem {
                height: control.implicitHeight + units.gu(2)
                divider.visible: false

                Label {
                    id: contentLabel
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(2)
                    anchors.right: control.left
                    anchors.rightMargin: units.gu(1)
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n.tr("Hide listened episodes")
                }

                Switch {
                    id: control
                    anchors.right: parent.right
                    anchors.rightMargin: units.gu(2)
                    anchors.verticalCenter: parent.verticalCenter
                    checked: podbird.settings.hideListened
                    onClicked: podbird.settings.hideListened = checked
                }

                onClicked: podbird.settings.hideListened = !podbird.settings.hideListened
            }

            SubtitledListItem {
                title: i18n.tr("Automatically delete old episodes")
                subtitle: i18n.tr("Delete episodes that are older than a given number of days for each podcast")
                onClicked: mainStack.push(Qt.resolvedUrl("../settings/CleanSetting.qml"))
            }

            SubtitledListItem {
                title: i18n.tr("Automatically download new episodes")
                subtitle: i18n.tr("Default number of new episodes to download for each podcast")
                onClicked: mainStack.push(Qt.resolvedUrl("../settings/DownloadSetting.qml"))
            }

            HeaderListItem {
                // TRANSLATORS: Shortened form of "Miscellaneous" which is shown to denote other setting options
                // that doesn't fit into any other category.
                title: i18n.tr("Misc.")
            }

            SubtitledListItem {
                // TRANSLATORS: About as in information about the app
                title: i18n.tr("About")
                onClicked: mainStack.push(Qt.resolvedUrl("../settings/About.qml"))
            }

            SubtitledListItem {
                // TRANSTORS: Credits as in the code and design contributors to the app
                title: i18n.tr("Credits")
                onClicked: mainStack.push(Qt.resolvedUrl("../settings/Credits.qml"))
            }

            SubtitledListItem {
                title: i18n.tr("Report Bug")
                onClicked: Qt.openUrlExternally("https://bugs.launchpad.net/podbird/+filebug")
            }
        }
    }
}


