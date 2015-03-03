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

import QtQuick 2.0
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 1.0 as ListItem

Tab {
    id: tab

    title: i18n.tr("Settings")

    page: Page {
        id: settingsPage

        ListModel {
            id: themeModel
            ListElement {
                name: "Light"
                file: "Light.qml"
            }

            ListElement {
                name: "Dark"
                file: "Dark.qml"
            }
        }

        ListItem.Expandable {
            id: themeSetting

            anchors {
                left: parent.left
                right: parent.right
            }

            collapseOnClick: true
            expandedHeight: _themeContentColumn.height + units.gu(1)

            Column {
                id: _themeContentColumn

                anchors {
                    left: parent.left
                    right: parent.right
                    margins: units.gu(-2)
                }

                Item {
                    width: parent.width
                    height: themeSetting.collapsedHeight

                    ListItem.Subtitled {
                        id: _themeHeader
                        text: i18n.tr("Theme")
                        subText: podbird.settings.themeName.split(".qml")[0]
                        onClicked: themeSetting.expanded = true

                        Icon {
                            id: _snoozeUpArrow

                            width: units.gu(2)
                            height: width
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter

                            name: "go-down"
                            color: "Grey"
                            rotation: themeSetting.expanded ? 180 : 0

                            Behavior on rotation {
                                UbuntuNumberAnimation {}
                            }
                        }
                    }
                }

                ListView {
                    id: themeSettingList

                    interactive: false
                    model: themeModel
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: units.gu(1)
                    height: units.gu(11)

                    delegate: ListItem.Standard {
                        text: model.name
                        showDivider: true
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
            }
        }
    }
}
