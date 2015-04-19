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
import QtMultimedia 5.0
import Ubuntu.Components 1.1
import "../podcasts.js" as Podcasts

Page {
    id: nowPlayingPage

    visible: false
    title: i18n.tr("Now Playing")

    property bool isNowPlayingPage: true

    BlurredBackground {
        id: blurredBackground

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.right: parent.right
        height: title.lineCount === 1 ? parent.height/2 + units.gu(3)
                                      : parent.height/2
        art: currentImage

        Image {
            width: Math.min(parent.width/2, parent.height)
            height: width
            sourceSize.height: width
            sourceSize.width: width
            source: currentImage
            anchors.centerIn: parent
        }
    }

    Label {
        id: title
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: blurredBackground.bottom
        anchors.margins: units.gu(2)
        text: currentName
        elide: Text.ElideRight
        fontSize: "large"
        maximumLineCount: 2
        wrapMode: Text.WordWrap
        color: podbird.theme.baseText
    }

    Label {
        id: artist
        anchors.left: title.left
        anchors.right: title.right
        anchors.top: title.bottom
        anchors.topMargin: units.gu(1)
        text: currentArtist
        elide: Text.ElideRight
        fontSize: "small"
        color: podbird.theme.baseSubText
    }

    Slider {
        id: scrubber

        anchors {
            left: parent.left
            right: parent.right
            margins: units.gu(2)
            bottom: controls.top
            bottomMargin: units.gu(2)
        }

        live: true
        minimumValue: 0
        maximumValue: player.duration
        value: player.position
        height: units.gu(2)

        onValueChanged: {
            if (pressed) {
                player.seek(value);
            }
        }

        function formatValue(v) { return Podcasts.formatTime(v/1000); }
    }

    Connections {
        target: player
        onPositionChanged: scrubber.value = player.position
    }

    Label {
        id: startTime
        fontSize: "small"
        anchors.left: scrubber.left
        anchors.top: scrubber.bottom
        color: podbird.theme.baseText
        text: Podcasts.formatTime(player.position / 1000)
    }

    Label {
        id: endTime
        fontSize: "small"
        anchors.right: scrubber.right
        anchors.top: scrubber.bottom
        color: podbird.theme.baseText
        text: Podcasts.formatTime(player.duration / 1000)
    }

    Row {
        id: controls
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: units.gu(2)

        AbstractButton {
            id: skipBackwardButton
            width: units.gu(6)
            height: width
            anchors.verticalCenter: parent.verticalCenter
            opacity: player.position === 0 ? 0.4 : 1.0
            onClicked: {
                if (player.position > 0) {
                    player.seek(player.position - 15 * 1000);
                }
            }

            Row {
                spacing: units.gu(1)
                anchors.centerIn: parent

                Label {
                    text: i18n.tr("-15s")
                    fontSize: "xx-small"
                    color: podbird.theme.baseText
                    anchors.verticalCenter: skipBackwardIcon.verticalCenter
                }

                Icon {
                    id: skipBackwardIcon
                    width: units.gu(3)
                    height: width
                    name: "media-seek-backward"
                    color: podbird.theme.baseIcon
                }
            }
        }

        AbstractButton {
            id: playButton
            width: units.gu(10)
            height: width
            opacity: playButton.pressed ? 0.4 : 1.0
            onClicked: player.playbackState === MediaPlayer.PlayingState ? player.pause() : player.play()

            Icon {
                id: playIcon
                width: units.gu(6)
                height: width
                anchors.centerIn: parent
                color: podbird.theme.baseIcon
                name: player.playbackState === MediaPlayer.PlayingState ? "media-playback-pause"
                                                                        : "media-playback-start"
            }
        }

        AbstractButton {
            id: skipForwardButton
            width: units.gu(6)
            height: width
            anchors.verticalCenter: parent.verticalCenter
            opacity: player.position === 0 ? 0.4 : 1.0
            onClicked: {
                if (player.position > 0) {
                    player.seek(player.position + 15 * 1000);
                }
            }

            Row {
                spacing: units.gu(1)
                anchors.centerIn: parent

                Icon {
                    id: skipForwardIcon
                    width: units.gu(3)
                    height: width
                    name: "media-seek-forward"
                    color: podbird.theme.baseIcon
                }

                Label {
                    text: i18n.tr("+15s")
                    fontSize: "xx-small"
                    color: podbird.theme.baseText
                    anchors.verticalCenter: skipForwardIcon.verticalCenter
                }
            }
        }
    }
}
