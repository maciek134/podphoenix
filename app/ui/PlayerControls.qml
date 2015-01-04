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

import QtQuick 2.0
import QtMultimedia 5.0
import Ubuntu.Components 1.1
import "../podcasts.js" as Podcasts

Rectangle {
    id: controlRect
    color: "black"

    Item {
        anchors.fill: parent
        anchors.rightMargin: units.gu(2)

        Image {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            id: cover
            source: currentImage
            width: parent.height
            height: width
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 1
            anchors.right: controls.left
            anchors.left: cover.right
            anchors.leftMargin: units.gu(2)

            Label {
                font.weight: Font.Bold
                fontSize: "small"
                anchors.left: parent.left
                anchors.right: parent.right
                color: "white"
                elide: Text.ElideRight
                text: currentName
            }
            Label {
                font.weight: Font.Light
                fontSize: "small"
                anchors.left: parent.left
                anchors.right: parent.right
                color: "white"
                elide: Text.ElideRight
                text: currentArtist
            }

            Row {
                width: parent.width
                spacing: units.gu(0.5)

                Slider {
                    id: scrubber
                    minimumValue: 0
                    live: true
                    width: parent.width - time.width - units.gu(0.5)
                    height: units.gu(2)
                    onValueChanged: {
                        if (pressed) {
                            player.seek(value);
                        }
                    }
                    function formatValue(v) { return Podcasts.formatTime(v/1000); }
                }

                Label {
                    id: time
                    color: "white"
                    fontSize: "small"
                    horizontalAlignment: Text.AlignRight
                    text: Podcasts.formatTime(player.position / 1000) + " / " + Podcasts.formatTime(player.duration / 1000)
                }
            }
        }

        Connections {
            target: player
            onDurationChanged: {
                scrubber.maximumValue = player.duration
            }
            onPositionChanged: {
                scrubber.value = player.position
            }
        }

        Row {
            id: controls
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: -units.gu(2)

            Item {
                width: units.gu(5); height: units.gu(7)
                visible: controlRect.height > 0
                anchors.verticalCenter: parent.verticalCenter
                Icon {
                    anchors.centerIn: parent
                    color: "white"
                    width: units.gu(3)
                    height: width
                    name: player.playbackState === MediaPlayer.PlayingState ? "media-playback-pause"
                                                   : "media-playback-start"
                    opacity: play.pressed ? 0.4 : 1.0
                }
                MouseArea {
                    id: play
                    anchors.fill: parent
                    onClicked: player.playbackState === MediaPlayer.PlayingState ? player.pause() : player.play()
                }
            }

        }
    }
}
