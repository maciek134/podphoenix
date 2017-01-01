/*
 * Copyright 2015-2016 Michael Sheldon <mike@mikeasoft.com>
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
import QtMultimedia 5.6
import Ubuntu.Components 1.3

Rectangle {
    id: controlRect

    color: podbird.appTheme.bottomBarBackground

    MouseArea {
        z: -1
        anchors.fill: parent
        onClicked: {
            mainStack.push(Qt.resolvedUrl("NowPlayingPage.qml"))
        }
    }

    Image {
        id: cover
        anchors.top: parent.top
        anchors.left: parent.left
        source: currentImage
        width: parent.height - units.gu(0.25)
        height: width
        asynchronous: true
    }

    Rectangle {
        id: progressBarHint
        anchors.left: parent.left
        anchors.top: cover.bottom
        color: podbird.appTheme.focusText
        height: units.gu(0.25)
        width: player.duration > 0 ? (player.position / player.duration) * parent.width : 0
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: playButton.left
        anchors.left: cover.right
        anchors.leftMargin: units.gu(2)

        Label {
            textSize: Label.Small
            font.weight: Font.Bold
            anchors.left: parent.left
            anchors.right: parent.right
            color: "white"
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.WordWrap
            text: currentName
        }

        Label {
            textSize: Label.Small
            color: "#999999"
            text: currentArtist
            elide: Text.ElideRight
            font.weight: Font.Light
            anchors.left: parent.left
            anchors.right: parent.right
        }
    }

    AbstractButton {
        id: playButton

        width: units.gu(7)
        height: cover.height
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right

        Rectangle {
            id: playButtonBackground
            anchors.fill: parent
            color: "#FFF"
            opacity: 0.1
            visible: playButton.pressed
        }

        onClicked: player.toggle()

        Icon {
            color: "white"
            width: units.gu(3)
            height: width
            anchors.centerIn: playButtonBackground
            name: player.playbackState === MediaPlayer.PlayingState ? "media-playback-pause"
                                                                    : "media-playback-start"
            opacity: playButton.pressed ? 0.4 : 1.0
        }
    }
}
