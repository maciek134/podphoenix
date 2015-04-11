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
import Podbird 1.0
import QtMultimedia 5.0
import Ubuntu.Connectivity 1.0
import Qt.labs.settings 1.0
import Ubuntu.Components 1.1
import QtQuick.LocalStorage 2.0
import Ubuntu.DownloadManager 0.1
import "ui"
import "themes" as Themes
import "podcasts.js" as Podcasts

MainView {
    id: podbird

    objectName: "mainView"
    applicationName: "com.mikeasoft.podbird"
    useDeprecatedToolbar: false
    anchorToKeyboard: true

    width: units.gu(50)
    height: units.gu(75)

    backgroundColor: theme.background

    Component.onDestruction: {
        console.log("[LOG]: Download cancelled");
        downloader.cancel();
        var db = Podcasts.init()
        db.transaction(function (tx) {
            tx.executeSql('UPDATE Episode SET queued=0 WHERE queued=1');
        })
    }

    Component.onCompleted: {
        var db = Podcasts.init()
        db.transaction(function (tx) {
            tx.executeSql('UPDATE Episode SET queued=0 WHERE queued=1');
        })

        var today = new Date()
        // Only perform cleanup of old episodes once a day
        if (Math.floor((today - settings.lastCheck)/86400000) >= 1 && settings.retentionDays !== -1) {
            cleanUp(today, settings.retentionDays)
            settings.lastCheck = today
        }

        if (NetworkingStatus.limitedBandwith && settings.onlyWifiDownload || !NetworkingStatus.online || settings.maxEpisodeDownload === -1) {
            console.log("[LOG]: Skipped autodownloading due to missing wifi connectivity and only download on wifi preference.")
            console.log("[LOG]: Detecting limited bandwidth: " + NetworkingStatus.limitedBandwith)
            console.log("[LOG]: Detecting online connectivity: " + NetworkingStatus.online)
            console.log("[LOG]: User settings (onlywifidownload & maxEpisodeDownload): " + settings.onlyWifiDownload + ", " + settings.maxEpisodeDownload)
        } else {
            autoDownloadEpisodes(settings.maxEpisodeDownload)
        }
    }

    property string currentName
    property string currentArtist
    property string currentImage
    property string currentGuid

    Themes.ThemeManager {
        id: themeManager
        source: settings.themeName
    }

    property alias theme: themeManager.theme
    property var themeManager: themeManager

    property var settings: Settings {
        // Set "Light.qml" as the default theme
        property string themeName: "Light.qml"
        property int retentionDays: -1
        property var lastCheck: new Date()
        property bool firstRun: true
        property bool onlyWifiDownload: true
        property int maxEpisodeDownload: -1
        property bool hideListened: false
    }

    FileManager {
        id: fileManager
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
                tx.executeSql("UPDATE Episode SET downloadedfile=?, queued=0 WHERE guid=?", [finalLocation, downloadingGuid]);
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
        Component.onCompleted: {
            // Show the welcome wizard only when running the app for the first time
            if (settings.firstRun) {
                console.log("[LOG]: Detecting first time run by user. Starting welcome wizard.")
                push(Qt.resolvedUrl("welcomewizard/WelcomeWizard.qml"))
            } else {
                push(tabs)
            }
        }

        Tabs {
            id: tabs

            PodcastsTab {
                id: podcastTab
                objectName: "podcastsTab"
            }

            Tab {
                id: searchTab

                title: i18n.tr("Find New Podcasts")

                page: Loader {
                    parent: searchTab
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    source: (tabs.selectedTab === searchTab) ? Qt.resolvedUrl("ui/SearchPage.qml") : ""
                }
            }

            Tab {
                id: settingsTab

                title: i18n.tr("Settings")

                page: Loader {
                    parent: settingsTab
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    source: (tabs.selectedTab === settingsTab) ? Qt.resolvedUrl("ui/SettingsPage.qml") : ""
                }
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

    function cleanUp(today, retentionDays) {
        console.log("[LOG]: Cleaning up old episodes")
        var dayToMs = 86400000; //1 * 24 * 60 * 60 * 1000
        var db = Podcasts.init()
        db.transaction(function (tx) {
            var rs = tx.executeSql("SELECT rowid, * FROM Podcast ORDER BY name ASC");
            for(var i = 0; i < rs.rows.length; i++) {
                var podcast = rs.rows.item(i);
                var rs2 = tx.executeSql("SELECT rowid, * FROM Episode WHERE podcast=?", [rs.rows.item(i).rowid]);
                for (var j=0; j< rs2.rows.length; j++) {
                    var diff = Math.floor((today - rs2.rows.item(j).published)/dayToMs)
                    if (rs2.rows.item(j).downloadedfile && diff > retentionDays) {
                        fileManager.deleteFile(rs2.rows.item(j).downloadedfile)
                        tx.executeSql("UPDATE Episode SET downloadedfile = NULL WHERE guid = ?", [rs2.rows.item(j).guid]);
                    }
                }
            }
        });
    }

    function autoDownloadEpisodes(maxEpisodeDownload) {
        console.log("[LOG]: Auto-downloading new episodes")
        var db = Podcasts.init()
        db.transaction(function (tx) {
            var rs = tx.executeSql("SELECT rowid, * FROM Podcast ORDER BY name ASC");
            for (var i=0; i < rs.rows.length; i++) {
                var podcast = rs.rows.item(i);
                var rs2 = tx.executeSql("SELECT rowid, * FROM Episode WHERE podcast=? ORDER BY published DESC", [rs.rows.item(i).rowid]);
                var loopCount = maxEpisodeDownload > rs2.rows.length ? rs2.rows.length : maxEpisodeDownload
                for (var j=0; j < loopCount; j++) {
                    if (!rs2.rows.item(j).downloadedfile && !rs2.rows.item(j).listened) {
                        downloader.addDownload(rs2.rows.item(j).guid, rs2.rows.item(j).audiourl)
                    }
                }
            }
        });
    }
}
