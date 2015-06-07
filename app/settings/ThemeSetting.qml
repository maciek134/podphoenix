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
    id: themeSettingPage

    visible: false
    title: i18n.tr("Theme")

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

    UbuntuListView {
        id: themes

        model: themeModel
        anchors.fill: parent

        delegate: ListItem.Standard {
            text: model.name
            onClicked: {
                var themeElement = model.file
                podbird.settings.themeName = themeElement
                podbird.appThemeManager.source = themeElement
            }

            Icon {
                width: units.gu(2)
                height: width
                name: "ok"
                visible: podbird.settings.themeName === model.file
                anchors.right: parent.right
                anchors.rightMargin: units.gu(3)
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
