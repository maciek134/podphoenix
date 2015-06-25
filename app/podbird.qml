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
import UserMetrics 0.1
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

    /*
     FIXME: Opening tabs in landscape mode causes apps to crash in the current vivid images.
     As such this is disabled until upstream bug https://pad.lv/1448017 is fixed and released
     to the production phones.
    */
    automaticOrientation: false

    width: units.gu(50)
    height: units.gu(75)

    backgroundColor: appTheme.background

    Component.onDestruction: {
        console.log("[LOG]: Download cancelled");
        downloader.cancel();
        var db = Podcasts.init()
        db.transaction(function (tx) {
            tx.executeSql('UPDATE Episode SET queued=0 WHERE queued=1');
        })
    }

    // RefreshModel function to call refreshModel() function of the tab currently
    // visible on application start.
    function refreshModels() {
        if (tabs.selectedTabIndex === 0) {
            whatsNewTab.refreshModel()
        } else if (tabs.selectedTabIndex === 1) {
            podcastPage.item.refreshModel()
        }
    }

    Component.onCompleted: {
        var db = Podcasts.init()
        db.transaction(function (tx) {
            tx.executeSql('UPDATE Episode SET queued=0 WHERE queued=1');
        })

        Podcasts.updateEpisodes(refreshModels)

        var today = new Date()
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
            Theme.palette.normal.backgroundText = UbuntuColors.lightGrey
        }
    }

    property alias appTheme: themeManager.theme
    property var themeManager: themeManager

    property var settings: Settings {
        // Set "Light.qml" as the default theme
        property string themeName: "Light.qml"
        property int retentionDays: -1
        property var lastCheck: new Date()
        property bool firstRun: true
        property int maxEpisodeDownload: -1
        property bool hideListened: false
        property bool showListView: true
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

    // UserMetrics to show Podbird stats on welcome screen
    Metric {
        id: podcastsMetric
        name: "podcast-metrics"
        // TRANSLATORS: this refers to a number of songs greater than one. The actual number will be prepended to the string automatically (plural forms are not yet fully supported in usermetrics, the library that displays that string)
        format: i18n.tr("Podcasts listened to today: <b>%1</b>")
        emptyFormat: i18n.tr("No podcasts listened to today")
        domain: "com.mikeasoft.podbird"
    }

    // Load the media player only when the user starts to play some media. This
    // should improve app-startup slightly.
    Loader {
        id: playerLoader
        sourceComponent: currentUrl != "" ? playerComponent : undefined
    }

    Component {
        id: playerComponent
        MediaPlayer {
            id: player

            property bool podcastCounted: false

            source: currentUrl

            onSourceChanged: {
                podcastCounted = false
            }

            onPositionChanged: {
                if (currentGuid == "" || duration <= 0) {
                    return;
                }

                if (position > 10000 && !podcastCounted) {
                    podcastCounted = true
                    podcastsMetric.increment()
                    console.log("[LOG]: Podcast User metric incremented")
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

            WhatsNewTab {
                id: whatsNewTab
                objectName: "whatsNewTab"
            }

            Tab {
                id: podcastTab

                title: i18n.tr("Podcasts")

                page: Loader {
                    id: podcastPage
                    parent: podcastTab
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                }
            }

            Tab {
                id: searchTab

                title: i18n.tr("Add New Podcasts")

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
                id: settingsTab

                title: i18n.tr("Settings")

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
                when: currentUrl != "" && !mainStack.currentPage.isNowPlayingPage
                PropertyChanges { target: playerControlLoader; anchors.bottomMargin: 0 }
            },

            State {
                name: "hidden"
                when: currentUrl == "" || mainStack.currentPage.isNowPlayingPage || !playerControl.visible
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
