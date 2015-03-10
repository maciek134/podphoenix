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
            ListElement { name: "Light"; file: "Light.qml" }
            ListElement { name: "Dark"; file: "Dark.qml" }
        }

        Column {
            id: settingsColumn

            anchors.fill: parent

            ExpandableListItem {
                id: themeSetting
                customModel: themeModel
                customDelegate: ListItem.Standard {
                    text: model.name
                    divider.anchors.leftMargin: units.gu(1)
                    divider.anchors.rightMargin: units.gu(1)

                    onClicked: {
                        var themeElement =   model.file
                        podbird.settings.themeName = themeElement
                        podbird.theme.name = themeElement
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

            ListItem.Subtitled {
                text: "Clean up"
                subText: "Delete Episodes older than 7 days"
            }
        }
    }
}
