/*
 * Copyright 2016 Podbird Team
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
import "../podcasts.js" as Podcasts
import "../components"

Item {
    id: queuePage

    ListView {
        id: queueList

        anchors.fill: parent
        model: player.playlist

        delegate: ListItem {
            id: listItem

            height: layout.height
            divider.visible: false

            ListItemLayout {
                id: layout

                // Grab the metaData for the current index using its unique source url
                property var metaModel: player.metaForSource(model.source)

                Image {
                    id: imgFrame
                    width: units.gu(6)
                    height: width
                    source: Qt.resolvedUrl(layout.metaModel.image)
                    sourceSize.height: width
                    sourceSize.width: width
                    SlotsLayout.position: SlotsLayout.First
                }

                title.text: layout.metaModel.name
                // #FIXME: Change this 2 to prevent title eliding when UITK is updated to rev > 1800
                title.maximumLineCount: 1
                title.color: player.playlist.currentIndex === index ? podbird.appTheme.focusText
                                                                    : podbird.appTheme.baseText

                subtitle.text: layout.metaModel.artist
                subtitle.color: podbird.appTheme.baseSubText
            }

            leadingActions: ListItemActions {
                actions: [
                    Action {
                        iconName: "delete"
                        onTriggered: {
                            player.playlist.removeItem(index)
                            var source = model.source
                            source = source.toString()
                            Podcasts.removeItemFromQueue(source)
                        }
                    }
                ]
            }

            onClicked: {
                if (player.playlist.currentIndex === index) {
                    player.toggle()
                } else {
                    player.playlist.currentIndex = index
                }
            }
        }
    }
}
