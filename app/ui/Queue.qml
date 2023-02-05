/*
 * Copyright 2016 Podphoenix Team
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
import "../podcasts.js" as Podcasts

ListView {
    id: queueList

    Component.onCompleted: {
        // FIXME: workaround for qtubuntu not returning values depending on the grid unit definition
        // for Flickable.maximumFlickVelocity and Flickable.flickDeceleration
        var scaleFactor = units.gridUnit / 8;
        maximumFlickVelocity = maximumFlickVelocity * scaleFactor;
        flickDeceleration = flickDeceleration * scaleFactor;
    }

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
            title.wrapMode: Text.WordWrap
            title.maximumLineCount: 2
            title.color: player.playlist.currentIndex === index ? podphoenix.appTheme.focusText
                                                                : podphoenix.appTheme.baseText

            subtitle.text: layout.metaModel.artist
            subtitle.color: podphoenix.appTheme.baseSubText
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
                player.savePosition()
                player.playlist.currentIndex = index
            }
        }

        onPressAndHold: {
            ListView.view.ViewItems.dragMode = !ListView.view.ViewItems.dragMode
        }
    }

    ViewItems.onDragUpdated: {
        // Only update the model when the listitem is dropped, not 'live'
        if (event.status === ListItemDrag.Moving) {
            event.accept = false
        } else if (event.status === ListItemDrag.Dropped) {
            player.playlist.moveItem(event.from, event.to)
        }
    }
}
