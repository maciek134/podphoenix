/*
 * Copyright 2015-2016 Podphoenix Team
 *
 * This file is part of Podphoenix.
 *
 * Podphoenix is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * Podphoenix is distributed in the hope that it will be useful,
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
    id: downloadSetting

    visible: false

    header: PageHeader {
        title: i18n.tr("Download at most")
        flickable: download
        StyleHints {
            backgroundColor: podphoenix.appTheme.background
        }
    }

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

        currentIndex: -1
        model: episodeDownloadNumber
        anchors.fill: parent

        // Required to accomodate the now playing bar being shown in landscape mode which
        // can hide a setting if not for this footer.
        footer: Item {
            width: parent.width
            height: units.gu(8)
        }

        delegate: ListItem {

            ListItemLayout {
                title.text: model.name
                title.color: podphoenix.appTheme.baseText

                Icon {
                    width: units.gu(2)
                    height: width
                    name: "ok"
                    color: podphoenix.appTheme.baseText
                    visible: podphoenix.settings.maxEpisodeDownload === model.value
                    SlotsLayout.position: SlotsLayout.Trailing
                }
            }

            onClicked: {
                podphoenix.settings.maxEpisodeDownload = model.value
            }
        }
    }
}
