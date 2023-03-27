/*
 * Copyright 2015-2016 Michael Sheldon <mike@mikeasoft.com>
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

import QtQuick 2.9
import Podphoenix 1.0
import QtMultimedia 5.9
import Ubuntu.Connectivity 1.0
import Qt.labs.settings 1.0
import Ubuntu.Components 1.3
import QtQuick.LocalStorage 2.0
import Ubuntu.DownloadManager 1.2
import QtSystemInfo 5.5
import Ubuntu.Content 1.3
import "ui"
import "themes" as Themes
import "podcasts.js" as Podcasts

MainView {
    id: podphoenix

    objectName: "mainView"
    applicationName: "soy.iko.podphoenix"
    anchorToKeyboard: true

    width: units.gu(50)
    height: units.gu(75)

    backgroundColor: appTheme.background
    theme.name: settings.themeName == "Dark.qml" ? "Ubuntu.Components.Themes.SuruDark"
                                                 : "Ubuntu.Components.Themes.Ambiance"

    property bool episodesUpdating: false;

    ScreenSaver {
        id: screenSaver
        screenSaverEnabled: !episodesUpdating
    }

    // RefreshModel function to call refreshModel() function of the tab currently
    // visible on application start.
    function refreshModels() {
        if (tabs.selectedTab === episodesTab) {
            episodesTab.refreshModel()
        } else if (tabs.selectedTab === podcastTab) {
            podcastPage.item.refreshModel()
        }
        episodesUpdating = false;
    }

    Component.onCompleted: {
        var db = Podcasts.init()

        var today = new Date()
        // Only automatically check for podcasts on launch once every 12 hours
        if (Math.floor((today - settings.lastUpdate)/86400000) >= settings.refreshEpisodes/24.0) {
            episodesUpdating = true;
            Podcasts.updateEpisodes(refreshModels)
        }
        // Only perform cleanup of old episodes once a day
        if (Math.floor((today - settings.lastCheck)/86400000) >= 1 && settings.retentionDays !== -1) {
            Podcasts.cleanUp(today, settings.retentionDays)
            settings.lastCheck = today
        }

        delayStartTimer.start();
    }

    Timer {
        id: delayStartTimer
        interval: 500
        repeat: false
        onTriggered: {
            if (!NetworkingStatus.online || podphoenix.settings.maxEpisodeDownload === -1) {
                console.log("[LOG]: Skipped autodownloading of new episodes...")
                console.log("[LOG]: Online connectivity: " + NetworkingStatus.online)
                console.log("[LOG]: User settings (maxEpisodeDownload): " + podphoenix.settings.maxEpisodeDownload)
            } else {
                Podcasts.autoDownloadEpisodes(podphoenix.settings.maxEpisodeDownload)
            }
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
            podphoenix.theme.name = settings.themeName == "Dark.qml" ? "Ubuntu.Components.Themes.SuruDark"
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
        property bool deleteListened: false
        property bool showListView: true
        property int skipForward: 30
        property int skipBack: 10
        property int refreshEpisodes: 12
        property bool continueWhereStopped: true
        property int playlistIndex: -1
        property bool downloadOverWifiOnly: true
    }

    FileManager {
        id: fileManager
    }

    SingleDownload {
        id: imageDownloader

        property string feed
        property var queue: []
        property int queueLength: 0

        onFinished: {
            var db = Podcasts.init();
            var finalLocation = fileManager.saveDownload(path);
            db.transaction(function (tx) {
                tx.executeSql("UPDATE Podcast SET image=? WHERE feed=?", [finalLocation, imageDownloader.feed]);
                queue.shift();
                queueLength--
                if (queue.length > 0) {
                    imageDownloader.feed = queue[0][0];
                    download(queue[0][1]);
                } else {
                    feed = "";
                }
            });
        }

        function addDownload(feed, url) {
            queue.push([feed, url]);
            queueLength++
            if (queue.length == 1) {
                imageDownloader.feed = feed;
                download(url);
            }
        }
    }

    Component {
        id: singleDownloadComponent
        SingleDownload {
            id: singleDownloadObject
            property string image
            property string title
            property string guid
            metadata: Metadata {
                showInIndicator: true
                title: singleDownloadObject.title
                custom: {"guid": singleDownloadObject.guid, "image" : singleDownloadObject.image}
            }
        }
    }

    function downloadEpisode(image, title, guid, url, disableMobileDownload) {
        if(downloader.isDownloadInQueue(guid)) {
            console.log("[LOG]: Download with GUID of :"+guid+ " is already in the download queue.")
            return false;
        }

        var singleDownload = singleDownloadComponent.createObject(podphoenix, {"image": image, "title": title, "guid": guid, allowMobileDownload : !disableMobileDownload })
        singleDownload.download(url)
    }

    DownloadManager {
        id: downloader

        property string downloadingGuid: downloads.length > 0 ? downloads[0].metadata.custom.guid : "NULL"
        property int progress: downloads.length > 0 ? downloads[0].progress : 0

        cleanDownloads: true

        function isDownloadInQueue ( guid ) {
            for( var i=0; i < downloads.length; i++) {
                if( downloads[i].metadata.custom.guid && guid === downloads[i].metadata.custom.guid) {
                    return true ;
                }
            }
            return false;
        }

        onDownloadFinished: {
            var db = Podcasts.init();
            var finalLocation = fileManager.saveDownload(path);
            db.transaction(function (tx) {
                tx.executeSql("UPDATE Episode SET downloadedfile=?, queued=0 WHERE guid=?", [finalLocation, download.metadata.custom.guid]);
            });
        }

        onErrorFound: {
            console.log("[ERROR]: " + download.errorMessage)
        }
    }

    // This reduces incidences of media-hub getting confused and
    // continuing to play the previous file when clearing a playlist
    // and starting a new episode
    Timer {
        id: playStarter
        interval: 500
        onTriggered: {
            // Ideally we'd check the buffer progress here and base it on that
            // but media-hub doesn't report it correctly
            console.log("Starting playback")
            player.play()
        }
    }

    MediaPlayer {
        id: player

        onPositionChanged: {
            restorePosition()
        }

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
                position: 0,
            }

            source = source.toString()

            return Podcasts.lookup(decodeFileURI(source)) || blankMeta;
        }

        function toggle() {
            if (playbackState === MediaPlayer.PlayingState) {
                pause()
                // Save the current position when we pause
                savePosition()
            } else {
                play()
            }
        }

        function savePosition() {
            podphoenix.settings.playlistIndex = playlist.currentIndex
            if (currentGuid) {
                var db = Podcasts.init()
                db.transaction(function (tx) {
                    tx.executeSql("UPDATE Episode SET position=? WHERE guid=?", [player.position, currentGuid])
                    tx.executeSql("UPDATE Queue SET position=? WHERE guid=?", [player.position, currentGuid])
                    if(player.position / player.duration > 0.90)
                        tx.executeSql("UPDATE Episode SET listened=1 WHERE guid=?", [currentGuid])
                })
            }
        }

        function restoreFromQueue() {
            var db = Podcasts.init()
            db.transaction(function (tx) {
                var rs = tx.executeSql("SELECT * FROM Queue")
                for (var i=0; i<rs.rows.length;i++) {
                    var episode = rs.rows.item(i)
                    player.playlist.addItem(episode.url)
                }
            })
            if(playlist.itemCount > podphoenix.settings.playlistIndex)
                playlist.currentIndex = podphoenix.settings.playlistIndex
        }

        function restorePosition() {
            if(playbackState === MediaPlayer.PlayingState && status === MediaPlayer.Loaded && pendingSeek){
                //ugly hack because seek function does not seems to work async
                var p = pendingSeek
                pendingSeek = 0
                player.seek(p)
            }
        }

        function clearPosition() {
            if (currentGuid) {
                var db = Podcasts.init()
                db.transaction(function (tx) {
                    tx.executeSql("UPDATE Episode SET position=NULL WHERE guid=?", [currentGuid])
                })
            }
        }

        function playEpisode(guid, image, name, artist, url, position) {
            player.pause()

            // Clear current queue
            player.playlist.clear()
            Podcasts.clearQueue()

            url = decodeFileURI(url)
            // Add episode to queue
            Podcasts.addItemToQueue(guid, image, name, artist, url, position)
            player.playlist.addItem(url)

            // Play episode
            pendingSeek = position
            playStarter.restart()
        }

        function addEpisodeToQueue(guid, image, name, artist, url, position) {
            url = decodeFileURI(url)
            Podcasts.addItemToQueue(guid, image, name, artist, url, position)
            player.playlist.addItem(url)

            // If added episode is the first one in the queue, then set the current metadata
            // so that the bottom player controls will be shown, allowing the user to play
            // the episode if he chooses to.
            if (player.playlist.itemCount === 0) {
                currentGuid = guid
                currentName = name
                currentArtist = artist
                currentImage = image
                currentUrl = url
                pendingSeek = position
            }
        }

        property bool endOfMedia: false
        property int pendingSeek: 0

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
                player.pendingSeek = podphoenix.settings.continueWhereStopped && meta.position > 5000 ? meta.position : 0
            }
        }

        onStatusChanged: {
            if (status === MediaPlayer.EndOfMedia) {
                console.log("[LOG]: End of Media. Stopping.")
                endOfMedia = true
                stop()

                Podcasts.init().transaction(function(tx) {
                    // Playlist finished, mark all playlist as played.
                    tx.executeSql("UPDATE Episode SET listened=1 WHERE guid in (SELECT guid FROM Queue)");
                    refreshModels();
                })
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
                    pause()
                }
            }

            // Always reset endOfMedia
            endOfMedia = false
        }

        Component.onDestruction: {
            savePosition()
        }

        Component.onCompleted: {
            restoreFromQueue()
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
                id: searchTab

                // Dynamically load/unload the search tab as required
                page: Loader {
                    parent: searchTab
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    source: (tabs.selectedTab === searchTab) ? Qt.resolvedUrl("ui/SearchPage.qml") : ""
                }
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
}
