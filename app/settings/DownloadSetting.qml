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
    id: downloadSetting

    visible: false
    title: i18n.tr("Download at most")

    ListModel {
        id: episodeDownloadNumber
        Component.onCompleted: initialize()
        function initialize() {
            episodeDownloadNumber.append({ name: i18n.tr("Never"), value: -1 })
            episodeDownloadNumber.append({ name: i18n.tr("%1 episode", "%1 episodes", 1).arg(1), value: 1 })
            episodeDownloadNumber.append({ name: i18n.tr("%1 episode", "%1 episodes", 3).arg(3), value: 3 })
            episodeDownloadNumber.append({ name: i18n.tr("%1 episode", "%1 episodes", 5).arg(5), value: 5 })
            episodeDownloadNumber.append({ name: i18n.tr("%1 episode", "%1 episodes", 10).arg(10), value: 10 })
        }
    }

    ListView {
        id: download

        model: episodeDownloadNumber
        anchors.fill: parent

        // Required to accomodate the now playing bar being shown in landscape mode which
        // can hide a setting if not for this footer.
        footer: Item {
            width: parent.width
            height: units.gu(8)
        }

        delegate: SubtitledListItem {
            title: model.name
            progression: false
            divider.visible: true

            onClicked: {
                podbird.settings.maxEpisodeDownload = model.value
            }

            Icon {
                width: units.gu(2)
                height: width
                name: "ok"
                visible: podbird.settings.maxEpisodeDownload === model.value
                anchors.right: parent.right
                anchors.rightMargin: units.gu(3)
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
