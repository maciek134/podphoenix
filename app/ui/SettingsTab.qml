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

Tab {
    id: tab

    title: i18n.tr("Settings")

    page: Page {
        id: settingsPage

        ListModel {
            id: themeModel
            Component.onCompleted: initialize()
            function initialize() {
                themeModel.append({ name: i18n.tr("Light"), file: "Light.qml" })
                themeModel.append({ name: i18n.tr("Dark"), file: "Dark.qml" })
            }
        }

        ListModel {
            id: cleanupModel
            Component.onCompleted: initialize()
            function initialize() {
                cleanupModel.append({ name: i18n.tr("Never"), value: -1 })
                cleanupModel.append({ name: i18n.tr("7 days"), value: 7 })
                cleanupModel.append({ name: i18n.tr("31 days"), value: 31 })
                cleanupModel.append({ name: i18n.tr("90 days"), value: 90 })
                cleanupModel.append({ name: i18n.tr("180 days"), value: 180 })
                cleanupModel.append({ name: i18n.tr("360 days"), value: 360 })
            }
        }

        Column {
            id: settingsColumn

            anchors.fill: parent

            ExpandableListItem {
                id: themeSetting

                model: themeModel
                text: i18n.tr("Theme")
                subText: podbird.settings.themeName.split(".qml")[0]

                delegate: ListItem.Standard {
                    text: model.name

                    onClicked: {
                        var themeElement = model.file
                        podbird.settings.themeName = themeElement
                        podbird.themeManager.source = themeElement
                        themeSetting.expanded = false
                    }

                    Icon {
                        width: units.gu(2)
                        height: width
                        name: "ok"
                        visible: podbird.settings.themeName === model.file
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(2)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            ExpandableListItem {
                id: cleanupSetting

                listViewHeight: units.gu(36)
                model: cleanupModel
                text: i18n.tr("Remove episodes older than")
                subText: podbird.settings.retentionDays === -1 ? i18n.tr("Never")
                                                                : i18n.tr("%1 days").arg(podbird.settings.retentionDays)

                delegate: ListItem.Standard {
                    text: model.name

                    onClicked: {
                        podbird.settings.retentionDays = model.value
                        cleanupSetting.expanded = false
                    }

                    Icon {
                        width: units.gu(2)
                        height: width
                        name: "ok"
                        visible: podbird.settings.retentionDays === model.value
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(2)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}
