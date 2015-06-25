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
import Ubuntu.Components.Popups 1.0
import Ubuntu.Components.ListItems 1.0 as ListItem

Page {
    id: themeSettingPage

    visible: false
    title: i18n.tr("Theme")

    /*
     Note (nik90): After the upgrade to Ubuntu.Components 1.2, dynamic application theme switching is broken. This
     has been reported upstream at http://pad.lv/1462690. Until this is fixed, users will have to restart the app
     when switching application theme. This dialog explains that to the user.
    */
    Component {
        id: rebootAppDialog
        Dialog {
            id: dialogInternal
            title: i18n.tr("Restart %1").arg("Podbird")
            text: i18n.tr("You will need to restart %1 to change the application theme. \
This is necessary to avoid any strange behaviour in the app. We apologize for the inconvenience").arg("Podbird")
            Button {
                text: i18n.tr("Exit App")
                color: podbird.appTheme.positiveActionButton
                onClicked: {
                    Qt.quit()
                }
            }
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

    UbuntuListView {
        id: themes

        model: themeModel
        anchors.fill: parent

        // Required to accomodate the now playing bar being shown in landscape mode which
        // can hide a setting if not for this footer.
        footer: Item {
            width: parent.width
            height: units.gu(8)
        }

        delegate: ListItem.Standard {
            text: model.name
            onClicked: {
                podbird.settings.themeName = model.file
                PopupUtils.open(rebootAppDialog, themeSettingPage);
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
