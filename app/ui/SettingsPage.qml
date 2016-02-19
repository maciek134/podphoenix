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
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import "../components"

Page {
    id: settingsPage

    Flickable {
        id: flickable

        anchors.fill: parent
        contentHeight: settingsColumn.height + units.gu(8)
        contentWidth: parent.width

        Component {
            id: skipForwardDialog
            Dialog {
                id: dialogInternal
                // TRANSLATORS: This strings refers to the seeking of the episode playback. Users can set how far they
                // want to seek forward when pressing on this button.
                title: i18n.tr("Skip forward")
                Slider {
                    id: slider
                    width: parent.width
                    minimumValue: 0
                    maximumValue: 60
                    value: podbird.settings.skipForward
                    function formatValue(v) { return i18n.tr("%1 seconds").arg(Math.round(v)) }
                }

                Button {
                    text: i18n.tr("Ok")
                    color: podbird.appTheme.positiveActionButton
                    onClicked: {
                        podbird.settings.skipForward = Math.round(slider.value)
                        PopupUtils.close(dialogInternal)
                    }
                }
                Button {
                    text: i18n.tr("Cancel")
                    color: podbird.appTheme.neutralActionButton
                    onClicked: {
                        PopupUtils.close(dialogInternal)
                    }
                }
            }
        }

        Component {
            id: skipBackDialog
            Dialog {
                id: dialogInternal
                // TRANSLATORS: This strings refers to the seeking of the episode playback. Users can set how far they
                // want to seek backward when pressing on this button.
                title: i18n.tr("Skip back")
                Slider {
                    id: slider
                    width: parent.width
                    minimumValue: 0
                    maximumValue: 60
                    value: podbird.settings.skipBack
                    function formatValue(v) { return i18n.tr("%1 seconds").arg(Math.round(v)) }
                }

                Button {
                    text: i18n.tr("Ok")
                    color: podbird.appTheme.positiveActionButton
                    onClicked: {
                        podbird.settings.skipBack = Math.round(slider.value)
                        PopupUtils.close(dialogInternal)
                    }
                }
                Button {
                    text: i18n.tr("Cancel")
                    color: podbird.appTheme.neutralActionButton
                    onClicked: {
                        PopupUtils.close(dialogInternal)
                    }
                }
            }
        }

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
                title.text: i18n.tr("Theme")
                value: podbird.settings.themeName.split(".qml")[0] === "Light" ? i18n.tr("Light") : i18n.tr("Dark")
                onClicked: mainStack.push(Qt.resolvedUrl("../settings/ThemeSetting.qml"))
            }

            HeaderListItem {
                title: i18n.tr("Playback Settings")
            }

            SingleValueListItem {
                divider.visible: false
                title.text: i18n.tr("Skip forward")
                value: i18n.tr("%1 seconds").arg(podbird.settings.skipForward)
                onClicked: PopupUtils.open(skipForwardDialog, settingsPage);
            }

            SingleValueListItem {
                divider.visible: false
                title.text: i18n.tr("Skip back")
                value: i18n.tr("%1 seconds").arg(podbird.settings.skipBack)
                onClicked: PopupUtils.open(skipBackDialog, settingsPage);
            }

            HeaderListItem {
                title: i18n.tr("Podcast Episode Settings")
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


