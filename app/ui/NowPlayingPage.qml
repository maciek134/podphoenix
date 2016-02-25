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
import QtMultimedia 5.4
import Ubuntu.Components 1.3
import "../podcasts.js" as Podcasts
import "../components"

Page {
    id: nowPlayingPage

    visible: false
    title: i18n.tr("Now Playing")

    property bool isNowPlayingPage: true
    property bool isLandscapeMode: width > height

    // Landscape rule
    states: [
        State {
            name: "landscape"
            when: isLandscapeMode

            PropertyChanges {
                target: blurredBackground
                width: parent.width/2.2
                height: parent.height
            }

            AnchorChanges {
                target: blurredBackground
                anchors {
                    top: parent.top
                    left: parent.left
                    right: undefined
                }
            }

            AnchorChanges {
                target: dataContainer
                anchors {
                    top: parent.top
                    left: blurredBackground.right
                    right: parent.right
                    bottom: parent.bottom
                }
            }
        }
    ]

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
            asynchronous: true
            anchors.centerIn: parent
        }
    }

    Item {
        id: dataContainer

        anchors {
            top: blurredBackground.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: units.gu(2)
            bottomMargin: isLandscapeMode ? units.gu(4) : units.gu(2)
        }

        Label {
            id: title
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            text: currentName
            elide: Text.ElideRight
            textSize: Label.Large
            maximumLineCount: 2
            wrapMode: Text.WordWrap
            color: podbird.appTheme.baseText
        }

        Label {
            id: artist
            anchors.left: title.left
            anchors.right: title.right
            anchors.top: title.bottom
            anchors.topMargin: units.gu(1)
            text: currentArtist
            elide: Text.ElideRight
            textSize: Label.Small
            color: podbird.appTheme.baseSubText
        }

        Slider {
            id: scrubber

            anchors {
                left: parent.left
                right: parent.right
                bottom: controls.top
                bottomMargin: isLandscapeMode && title.lineCount < 2 ? units.gu(4) : units.gu(2)
            }

            live: true
            minimumValue: 0
            maximumValue: playerLoader.item.duration
            value: playerLoader.item.position
            height: units.gu(2)

            onValueChanged: {
                if (pressed) {
                    playerLoader.item.seek(value);
                }
            }

            function formatValue(v) { return Podcasts.formatTime(v/1000); }
            StyleHints { foregroundColor: podbird.appTheme.focusText }
        }

        Connections {
            target: playerLoader.item
            onPositionChanged: scrubber.value = playerLoader.item.position
        }

        Label {
            id: startTime
            textSize: Label.Small
            anchors.left: scrubber.left
            anchors.top: scrubber.bottom
            color: podbird.appTheme.baseText
            text: Podcasts.formatTime(playerLoader.item.position / 1000)
        }

        Label {
            id: endTime
            textSize: Label.Small
            anchors.right: scrubber.right
            anchors.top: scrubber.bottom
            color: podbird.appTheme.baseText
            text: Podcasts.formatTime(playerLoader.item.duration / 1000)
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
                opacity: playerLoader.item.position === 0 ? 0.4 : 1.0
                onClicked: {
                    if (playerLoader.item.position > 0) {
                        playerLoader.item.seek(playerLoader.item.position - podbird.settings.skipBack * 1000);
                    }
                }

                Row {
                    spacing: units.gu(1)
                    anchors.centerIn: parent

                    Label {
                        // TRANSLATORS: The string shown in the UI is -15s to denote the number of seconds that the podcast playback will skip backward.
                        // xgettext: no-c-format
                        text: i18n.tr("-%1s").arg(podbird.settings.skipBack)
                        textSize: Label.XxSmall
                        color: podbird.appTheme.baseText
                        anchors.verticalCenter: skipBackwardIcon.verticalCenter
                    }

                    Icon {
                        id: skipBackwardIcon
                        width: units.gu(3)
                        height: width
                        name: "media-seek-backward"
                        color: podbird.appTheme.baseIcon
                    }
                }
            }

            AbstractButton {
                id: playButton
                width: units.gu(10)
                height: width
                opacity: playButton.pressed ? 0.4 : 1.0
                onClicked: playerLoader.item.playbackState === MediaPlayer.PlayingState ? playerLoader.item.pause() : playerLoader.item.play()

                Icon {
                    id: playIcon
                    width: units.gu(6)
                    height: width
                    anchors.centerIn: parent
                    color: podbird.appTheme.baseIcon
                    name: playerLoader.item.playbackState === MediaPlayer.PlayingState ? "media-playback-pause"
                                                                                       : "media-playback-start"
                }
            }

            AbstractButton {
                id: skipForwardButton
                width: units.gu(6)
                height: width
                anchors.verticalCenter: parent.verticalCenter
                opacity: playerLoader.item.position === 0 ? 0.4 : 1.0
                onClicked: {
                    if (playerLoader.item.position > 0) {
                        playerLoader.item.seek(playerLoader.item.position + podbird.settings.skipForward * 1000);
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
                        color: podbird.appTheme.baseIcon
                    }

                    Label {
                        // TRANSLATORS: The string shown in the UI is +15s to denote the number of seconds that the podcast playback will skip forward.
                        // xgettext: no-c-format
                        text: i18n.tr("+%1s").arg(podbird.settings.skipForward)
                        textSize: Label.XxSmall
                        color: podbird.appTheme.baseText
                        anchors.verticalCenter: skipForwardIcon.verticalCenter
                    }
                }
            }
        }
    }
}
