/*
 * Copyright 2015 Michael Sheldon <mike@mikeasoft.com>
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
import QtMultimedia 5.0
import Ubuntu.Components 1.1
import "../podcasts.js" as Podcasts

Rectangle {
    id: controlRect

    height: 0
    color: podbird.theme.bottomBarBackground
    width: parent.width

    MouseArea {
        z: -1
        anchors.fill: parent
        onClicked: {
            mainStack.push(Qt.resolvedUrl("NowPlayingPage.qml"))
        }
    }

    Item {
        anchors.fill: parent
        visible: controlRect.height > 0

        Image {
            id: cover
            anchors.top: parent.top
            anchors.left: parent.left
            source: currentImage
            width: parent.height - units.gu(0.25)
            height: width
        }

        Rectangle {
            id: progressBarHint
            anchors.left: parent.left
            anchors.top: cover.bottom
            color: UbuntuColors.orange
            height: units.gu(0.25)
            width: player.duration > 0 ? (player.position / player.duration) * parent.width : 0
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: playButtonBackground.left
            anchors.left: cover.right
            anchors.leftMargin: units.gu(2)

            Label {
                font.weight: Font.Bold
                fontSize: "small"
                anchors.left: parent.left
                anchors.right: parent.right
                color: "white"
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.WrapAnywhere
                text: currentName
            }

            Label {
                font.weight: Font.Light
                fontSize: "small"
                anchors.left: parent.left
                anchors.right: parent.right
                color: "#999999"
                elide: Text.ElideRight
                text: currentArtist
            }
        }

        Rectangle {
            id: playButtonBackground
            width: units.gu(7)
            height: cover.height
            color: "#FFF"
            opacity: play.pressed ? 0.1 : 0
            visible: controlRect.height > 0
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right

            MouseArea {
                id: play
                anchors.fill: parent
                onClicked: player.playbackState === MediaPlayer.PlayingState ? player.pause()
                                                                             : player.play()
            }
        }

        Icon {
            color: "white"
            width: units.gu(3)
            height: width
            anchors.centerIn: playButtonBackground
            name: player.playbackState === MediaPlayer.PlayingState ? "media-playback-pause"
                                                                    : "media-playback-start"
            opacity: play.pressed ? 0.4 : 1.0
        }
    }
}
