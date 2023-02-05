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
import QtMultimedia 5.6
import Ubuntu.Components 1.3
import "../podcasts.js" as Podcasts
import "../components"

Item {
    id: nowPlayingItem
    
    property bool isLandscapeMode: width > height
    
    // Landscape rule
    states: [
        State {
            name: "landscape"
            when: nowPlayingItem.isLandscapeMode
            
            PropertyChanges {
                target: blurredBackground
                width: nowPlayingItem.width/2.2
                height: nowPlayingItem.height
            }
            
            AnchorChanges {
                target: blurredBackground
                anchors {
                    top: nowPlayingItem.top
                    left: parent.left
                    right: undefined
                }
            }
            
            AnchorChanges {
                target: dataContainer
                anchors {
                    top: nowPlayingItem.top
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
        anchors.top: nowPlayingItem.top
        anchors.right: parent.right
        height: title.lineCount === 1 ? nowPlayingItem.height/2.3 + units.gu(3)
                                      : nowPlayingItem.height/2.3
        art: currentImage
        
        Image {
            width: Math.min(nowPlayingItem.width/2, nowPlayingItem.height/2)
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
            bottomMargin: nowPlayingItem.isLandscapeMode ? units.gu(4) : units.gu(2)
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
            color: podphoenix.appTheme.baseText
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
            color: podphoenix.appTheme.baseSubText
        }
        
        Slider {
            id: scrubber
            
            anchors {
                left: parent.left
                right: parent.right
                bottom: controls.top
                bottomMargin: nowPlayingItem.isLandscapeMode && title.lineCount < 2 ? units.gu(4) : units.gu(2)
            }
            
            live: true
            minimumValue: 0
            maximumValue: player.duration
            value: player.position
            height: units.gu(2)

            property bool seeking: false
            property bool seeked: false

            onSeekingChanged: {
                if (seeking === false) {
                    startTime.text = Podcasts.formatTime(player.position / 1000)
                }
            }

            onPressedChanged: {
                seeking = pressed

                if (!pressed) {
                    seeked = true
                    player.seek(value)

                    startTime.text = Podcasts.formatTime(value / 1000)
                }
            }
            
            function formatValue(v) { return Podcasts.formatTime(v/1000); }
            StyleHints { foregroundColor: podphoenix.appTheme.focusText }
        }
        
        Connections {
            target: player
            onPositionChanged: {
                // seeked is a workaround for bug 1310706 as the first position after a seek is sometimes invalid (0)
                if (scrubber.seeking === false && !scrubber.seeked) {
                    startTime.text = Podcasts.formatTime(player.position / 1000)
                    endTime.text = Podcasts.formatTime(player.duration / 1000)

                    scrubber.value = player.position
                }
                scrubber.seeked = false;
            }
        }
        
        Label {
            id: startTime
            textSize: Label.Small
            anchors.left: scrubber.left
            anchors.top: scrubber.bottom
            color: podphoenix.appTheme.baseText
            text: Podcasts.formatTime(player.position / 1000)
        }
        
        Label {
            id: endTime
            textSize: Label.Small
            anchors.right: scrubber.right
            anchors.top: scrubber.bottom
            color: podphoenix.appTheme.baseText
            text: Podcasts.formatTime(player.duration / 1000)
        }
        
        Row {
            id: controls
            
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: units.gu(1)
            
            AbstractButton {
                id: mediaBackwardButton
                width: units.gu(6)
                height: width
                anchors.verticalCenter: parent.verticalCenter
                enabled: player.playlist.canGoPrevious
                opacity: enabled ? 1.0 : 0.4
                onClicked: {
                    player.savePosition()
                    player.playlist.previous()
                }
                
                Icon {
                    id: mediaBackwardIcon
                    width: units.gu(3)
                    height: width
                    anchors.centerIn: parent
                    color: podphoenix.appTheme.baseIcon
                    name: "media-skip-backward"
                }
            }
            
            AbstractButton {
                id: skipBackwardButton
                width: units.gu(6)
                height: width
                anchors.verticalCenter: parent.verticalCenter
                opacity: player.position === 0 ? 0.4 : 1.0
                onClicked: {
                    if (player.position > 0) {
                        player.seek(player.position - podphoenix.settings.skipBack * 1000);
                    }
                }
                
                Row {
                    spacing: units.gu(1)
                    anchors.centerIn: parent
                    
                    Label {
                        // TRANSLATORS: The string shown in the UI is -15s to denote the number of seconds that the podcast playback will skip backward.
                        // xgettext: no-c-format
                        text: i18n.tr("-%1s").arg(podphoenix.settings.skipBack)
                        textSize: Label.XxSmall
                        color: podphoenix.appTheme.baseText
                        anchors.verticalCenter: skipBackwardIcon.verticalCenter
                    }
                    
                    Icon {
                        id: skipBackwardIcon
                        width: units.gu(3)
                        height: width
                        name: "media-seek-backward"
                        color: podphoenix.appTheme.baseIcon
                    }
                }
            }
            
            AbstractButton {
                id: playButton
                width: units.gu(10)
                height: width
                opacity: playButton.pressed ? 0.4 : 1.0
                onClicked: player.toggle()
                
                Icon {
                    id: playIcon
                    width: units.gu(6)
                    height: width
                    anchors.centerIn: parent
                    color: podphoenix.appTheme.baseIcon
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
                        player.seek(player.position + podphoenix.settings.skipForward * 1000);
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
                        color: podphoenix.appTheme.baseIcon
                    }
                    
                    Label {
                        // TRANSLATORS: The string shown in the UI is +15s to denote the number of seconds that the podcast playback will skip forward.
                        // xgettext: no-c-format
                        text: i18n.tr("+%1s").arg(podphoenix.settings.skipForward)
                        textSize: Label.XxSmall
                        color: podphoenix.appTheme.baseText
                        anchors.verticalCenter: skipForwardIcon.verticalCenter
                    }
                }
            }
            
            AbstractButton {
                id: mediaForwardButton
                width: units.gu(6)
                height: width
                anchors.verticalCenter: parent.verticalCenter
                enabled: player.playlist.canGoNext
                opacity: enabled ? 1.0 : 0.4
                onClicked: {
                    player.savePosition()
                    player.playlist.next()
                }
                
                Icon {
                    id: mediaForwardIcon
                    width: units.gu(3)
                    height: width
                    anchors.centerIn: parent
                    color: podphoenix.appTheme.baseIcon
                    name: "media-skip-forward"
                }
            }
        }
    }
}
