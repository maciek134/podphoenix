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
import "../components"

Page {
    id: themeSettingPage

    visible: false

    header: PageHeader {
        title: i18n.tr("Theme")
        flickable: themes
        StyleHints {
            backgroundColor: podbird.appTheme.background
        }
    }

    ListModel {
        id: themeModel
        Component.onCompleted: initialize()
        function initialize() {
            // TRANSLATORS: Light Theme
            themeModel.append({ name: i18n.tr("Light"), file: "Light.qml" })
            // TRANSLATORS: Dark Theme
            themeModel.append({ name: i18n.tr("Dark"), file: "Dark.qml" })
        }
    }

    ListView {
        id: themes

        currentIndex: -1
        model: themeModel
        anchors.fill: parent

        // Required to accomodate the now playing bar being shown in landscape mode which
        // can hide a setting if not for this footer.
        footer: Item {
            width: parent.width
            height: units.gu(8)
        }

        delegate: ListItem {
            height: themeLayout.height + divider.height
            ListItemLayout {
                id: themeLayout

                title.text: model.name
                title.color: podbird.appTheme.baseText

                Icon {
                    width: units.gu(2)
                    height: width
                    name: "ok"
                    color: podbird.appTheme.baseText
                    visible: podbird.settings.themeName === model.file
                    SlotsLayout.position: SlotsLayout.Trailing
                }
            }

            onClicked: {
                podbird.settings.themeName = model.file
            }
        }
    }
}
