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
    id: cleanSettingPage

    visible: false
    title: i18n.tr("Delete older than")

    ListModel {
        id: cleanupModel
        Component.onCompleted: initialize()
        function initialize() {
            cleanupModel.append({ name: i18n.tr("Never"), value: -1 })
            cleanupModel.append({ name: i18n.tr("%1 day", "%1 days", 7).arg(7), value: 7 })
            cleanupModel.append({ name: i18n.tr("%1 month", "%1 months", 1).arg(1), value: 31 })
            cleanupModel.append({ name: i18n.tr("%1 month", "%1 months", 3).arg(3), value: 90 })
            cleanupModel.append({ name: i18n.tr("%1 month", "%1 months", 6).arg(6), value: 180 })
            cleanupModel.append({ name: i18n.tr("%1 year", "%1 years", 1).arg(1), value: 360 })
        }
    }

    UbuntuListView {
        id: cleanup

        model: cleanupModel
        anchors.fill: parent

        delegate: ListItem.Standard {
            text: model.name
            onClicked: {
                podbird.settings.retentionDays = model.value
            }

            Icon {
                width: units.gu(2)
                height: width
                name: "ok"
                visible: podbird.settings.retentionDays === model.value
                anchors.right: parent.right
                anchors.rightMargin: units.gu(3)
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
