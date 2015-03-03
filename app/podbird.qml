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
import QtQuick.LocalStorage 2.0
import Ubuntu.DownloadManager 0.1
import Ubuntu.Components 1.1
import Qt.labs.settings 1.0
import Podbird 1.0
import "ui"
import "themes" as Themes
import "podcasts.js" as Podcasts

MainView {
    id: podbird

    objectName: "mainView"
    applicationName: "com.mikeasoft.podbird"

    property string currentName
    property string currentArtist
    property string currentImage
    property string currentGuid

    useDeprecatedToolbar: false
    anchorToKeyboard: true

    width: units.gu(50)
    height: units.gu(75)

    FileManager {
        id: fileManager
    }

    property var theme: Themes.ThemeManager {
        id: theme
        name: settings.themeName
    }

    property var settings: Settings {
        property string themeName: "Light.qml"
    }

    backgroundColor: theme.background
    headerColor: theme.background

    Component.onDestruction: {
        console.log("Download cancelled");
        downloader.cancel();
    }

    SingleDownload {
        id: imageDownloader
        property string feed;
        onFinished: {
            var db = Podcasts.init();
            var finalLocation = fileManager.saveDownload(path);
            db.transaction(function (tx) {
                tx.executeSql("UPDATE Podcast SET image=? WHERE feed=?", [finalLocation, feed]);
            });
        }
    }

    SingleDownload {
        id: downloader
        property var queue: []
        property string downloadingGuid

        onFinished: {
            var db = Podcasts.init();
            var finalLocation = fileManager.saveDownload(path);
            db.transaction(function (tx) {
                tx.executeSql("UPDATE Episode SET downloadedfile=? WHERE guid=?", [finalLocation, downloadingGuid]);
                queue.shift();
                if (queue.length > 0) {
                    downloadingGuid = queue[0][0];
                    download(queue[0][1]);
                } else {
                    downloadingGuid = "";
                }
            });
        }

        function addDownload(guid, url) {
            queue.push([guid, url]);
            if (queue.length == 1) {
                downloadingGuid = guid;
                download(url);
            }
        }
    }

    MediaPlayer {
        id: player
        onPositionChanged: {
            if (currentGuid == "" || duration <= 0) {
                return;
            }

            var db = Podcasts.init();
            db.transaction(function (tx) {
                tx.executeSql("UPDATE Episode SET position=? WHERE guid=?", [position >= duration ? 120 : position, currentGuid]);
                if (position >= duration - 120) {
                    tx.executeSql("UPDATE Episode SET listened = 1 WHERE guid=?", [currentGuid]);
                }
            });
        }
    }

    PageStack {
        id: mainStack
        Component.onCompleted: push(tabs)
        Tabs {
            id: tabs

            PodcastsTab {
                id: podcastTab
                objectName: "podcastsTab"
            }

            SearchTab {
                id: searchTab
                objectName: "searchTab"
            }

            SettingsTab {
                id: settingsTab
                objectName: "settingsTab"
            }
        }
    }

    PlayerControls {
        id: playerControl

        visible: !Qt.inputMethod.visible
        anchors.bottom: parent.bottom

        state: "hidden"
        states: [
            State {
                name: "shown"
                when: player.source != "" && !mainStack.currentPage.isNowPlayingPage
                PropertyChanges { target: playerControl; height: units.gu(7) }
            },

            State {
                name: "hidden"
                when: player.source == ""
                PropertyChanges { target: playerControl; height: 0 }
            }
        ]

        Behavior on height {
            UbuntuNumberAnimation {
                duration: UbuntuAnimation.SlowDuration
            }
        }
    }
}

