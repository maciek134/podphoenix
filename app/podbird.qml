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
import Podbird 1.0
import UserMetrics 0.1
import QtMultimedia 5.6
import Ubuntu.Connectivity 1.0
import Qt.labs.settings 1.0
import Ubuntu.Components 1.3
import QtQuick.LocalStorage 2.0
import Ubuntu.DownloadManager 0.1
import "ui"
import "themes" as Themes
import "podcasts.js" as Podcasts

MainView {
    id: podbird

    objectName: "mainView"
    applicationName: "com.mikeasoft.podbird"
    anchorToKeyboard: true

    width: units.gu(50)
    height: units.gu(75)

    backgroundColor: appTheme.background
    theme.name: settings.themeName == "Dark.qml" ? "Ubuntu.Components.Themes.SuruDark"
                                                 : "Ubuntu.Components.Themes.Ambiance"

    Component.onDestruction: {
        console.log("[LOG]: Download cancelled");
        downloader.cancel();
        var db = Podcasts.init()
        db.transaction(function (tx) {
            tx.executeSql('UPDATE Episode SET queued=0 WHERE queued=1');
        })
        Podcasts.clearQueue()
    }

    // RefreshModel function to call refreshModel() function of the tab currently
    // visible on application start.
    function refreshModels() {
        if (tabs.selectedTabIndex === 0) {
            episodesTab.refreshModel()
        } else if (tabs.selectedTabIndex === 1) {
            podcastPage.item.refreshModel()
        }
    }

    Component.onCompleted: {
        var db = Podcasts.init()
        db.transaction(function (tx) {
            tx.executeSql('UPDATE Episode SET queued=0 WHERE queued=1');
        })

        var today = new Date()
        // Only automatically check for podcasts on launch once every 12 hours
        if (Math.floor((today - settings.lastUpdate)/86400000) >= 0.5) {
            Podcasts.updateEpisodes(refreshModels)
        }
        loadingIndicator.opacity = 0
        // Only perform cleanup of old episodes once a day
        if (Math.floor((today - settings.lastCheck)/86400000) >= 1 && settings.retentionDays !== -1) {
            Podcasts.cleanUp(today, settings.retentionDays)
            settings.lastCheck = today
        }

        if (!NetworkingStatus.online || settings.maxEpisodeDownload === -1) {
            console.log("[LOG]: Skipped autodownloading of new episodes...")
            console.log("[LOG]: Online connectivity: " + NetworkingStatus.online)
            console.log("[LOG]: User settings (maxEpisodeDownload): " + settings.maxEpisodeDownload)
        } else {
            Podcasts.autoDownloadEpisodes(settings.maxEpisodeDownload)
        }
    }

    property string currentName
    property string currentArtist
    property string currentImage
    property string currentGuid
    property url currentUrl: ""

    Themes.ThemeManager {
        id: themeManager
        source: settings.themeName
        onSourceChanged: {
            theme.palette.normal.backgroundText = UbuntuColors.lightGrey
            theme.name = settings.themeName == "Dark.qml" ? "Ubuntu.Components.Themes.SuruDark"
                                                          : "Ubuntu.Components.Themes.Ambiance"
        }
    }

    property alias appTheme: themeManager.theme
    property var themeManager: themeManager

    property var settings: Settings {
        // Set "Light.qml" as the default theme
        property string themeName: "Light.qml"
        property int retentionDays: -1
        property var lastCheck: new Date()
        property var lastUpdate: new Date(0)
        property bool firstRun: true
        property int maxEpisodeDownload: -1
        property bool hideListened: false
        property bool showListView: true
        property int skipForward: 30
        property int skipBack: 10
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

        // Wrapper function around decodeURIComponent() to prevent exceptions
        // from bubbling up to the app.
        function decodeFileURI(filename)
        {
            var newFilename = "";
            try {
                newFilename = decodeURIComponent(filename);
            } catch (e) {
                newFilename = filename;
                console.log("Unicode decoding error:", filename, e.message)
            }

            return newFilename;
        }

        function metaForSource(source) {
            var blankMeta = {
                name: "",
                artist: "",
                image: "",
                guid: "",
            }

            source = source.toString()

            return Podcasts.lookup(decodeFileURI(source)) || blankMeta;
        }

        function toggle() {
            if (playbackState === MediaPlayer.PlayingState) {
                pause()
            } else {
                play()
            }
        }

        function playEpisode(guid, image, name, artist, url) {
            // Clear current queue
            player.playlist.clear()
            Podcasts.clearQueue()

            // Add episode to queue
            player.playlist.addItem(Qt.resolvedUrl(url))
            Podcasts.addItemToQueue(guid, image, name, artist, url)

            // Play episode
            player.play()
        }

        function addEpisodeToQueue(guid, image, name, artist, url) {
            player.playlist.addItem(Qt.resolvedUrl(url))
            Podcasts.addItemToQueue(guid, image, name, artist, url)

            // If added episode is the first one in the queue, then set the current metadata
            // so that the bottom player controls will be shown, allowing the user to play
            // the episode if he chooses to.
            if (player.playlist.itemCount === 0) {
                currentGuid = guid
                currentName = name
                currentArtist = artist
                currentImage = image
                currentUrl = url
            }
        }

        property bool endOfMedia: false
        property double progress: 0

        playlist: Playlist {
            playbackMode: Playlist.Sequential

            readonly property bool canGoPrevious: currentIndex !== 0
            readonly property bool canGoNext: currentIndex !== itemCount - 1

            onCurrentItemSourceChanged: {
                var meta = player.metaForSource(currentItemSource)
                currentGuid = "";
                currentName = meta.name
                currentArtist = meta.artist
                currentImage = meta.image
                currentGuid = meta.guid
            }
        }

        onStatusChanged: {
            if (status === MediaPlayer.EndOfMedia) {
                console.log("[LOG]: End of Media. Stopping.")
                endOfMedia = true
                stop()
            }
        }

        onStopped: {
            if (playlist.itemCount > 0) {
                if (endOfMedia) {
                    // We just ended media, so jump to start of playlist
                    playlist.currentIndex  = 0;

                    // Play then pause otherwise when we come from EndOfMedia
                    // it calls next() until EndOfMedia again.
                    play()
                }

                pause()
            }

            // Always reset endOfMedia
            endOfMedia = false
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

            // Ensure that the last used tab is restored when the app gets killed
            // and brought by the system.
            StateSaver.properties: "selectedTabIndex"

            onSelectedTabChanged: {
                // Load the Podcast page only when the user navigates to it. However
                // do not unload it when the user switches to another tab.
                if (selectedTab === podcastTab) {
                    podcastPage.source = Qt.resolvedUrl("ui/PodcastsTab.qml")
                }
            }

            EpisodesTab {
                id: episodesTab
                objectName: "episodesTab"
            }

            Tab {
                id: podcastTab

                page: Loader {
                    id: podcastPage
                    parent: podcastTab
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                }
            }

            Tab {
                id: settingsTab

                // Dynamically load/unload the settings tab as required
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

    Loader {
        id: playerControlLoader

        anchors.bottom: parent.bottom
        height: units.gu(7)
        width: parent.width
        visible: !Qt.inputMethod.visible

        state: "shown"
        states: [
            State {
                name: "shown"
                when: player.playlist.itemCount !== 0 && !mainStack.currentPage.isNowPlayingPage
                PropertyChanges { target: playerControlLoader; anchors.bottomMargin: 0 }
            },

            State {
                name: "hidden"
                when: player.playlist.itemCount === 0 || mainStack.currentPage.isNowPlayingPage || !playerControl.visible
                PropertyChanges { target: playerControlLoader; anchors.bottomMargin: -units.gu(7) }
            }
        ]

        transitions: [
            Transition {
                from: "hidden"; to: "shown"
                SequentialAnimation {
                    ScriptAction { script: playerControlLoader.source = Qt.resolvedUrl("ui/PlayerControls.qml") }
                    UbuntuNumberAnimation { target: playerControlLoader; property: "anchors.bottomMargin"; duration: UbuntuAnimation.SlowDuration }
                }
            },

            Transition {
                from: "shown"; to: "hidden"
                SequentialAnimation {
                    UbuntuNumberAnimation { target: playerControlLoader; property: "anchors.bottomMargin"; duration: UbuntuAnimation.SlowDuration }
                    ScriptAction { script: playerControlLoader.source = "" }
                }
            }
        ]
    }

    Rectangle {
        id: loadingIndicator
        color: podbird.appTheme.background
        anchors.fill: parent

        ActivityIndicator {
            anchors.centerIn: parent
            running: true
        }

        Behavior on opacity {
            UbuntuNumberAnimation {
            }
        }
    }

}
