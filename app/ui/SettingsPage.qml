/*
 * Copyright 2015-2016 Podphoenix Team
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
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import QtQuick.LocalStorage 2.0
import "../components"
import "../podcasts.js" as Podcasts

Page {
    id: settingsPage

    TabsList {
        id: tabsList
    }

    header: PageHeader {
        title: i18n.tr("Settings")

        StyleHints {
            backgroundColor: podphoenix.appTheme.background
        }

        leadingActionBar {
            numberOfSlots: 0
            actions: tabsList.actions
        }
    }

    Flickable {
        id: flickable

        anchors {
            top: settingsPage.header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        contentHeight: settingsColumn.height + units.gu(8)
        contentWidth: parent.width

        Component {
            id: skipForwardDialog
            Dialog {
                id: dialogInternal
                // TRANSLATORS: This strings refers to the seeking of the episode playback. Users can set how far they
                // want to seek forward when pressing on this button.
                title: i18n.tr("Skip forward")
                Slider {
                    id: slider
                    width: parent.width
                    minimumValue: 0
                    maximumValue: 60
                    value: podphoenix.settings.skipForward
                    function formatValue(v) { return i18n.tr("%1 seconds").arg(Math.round(v)) }
                    StyleHints { foregroundColor: podphoenix.appTheme.focusText }
                }

                Button {
                    text: i18n.tr("OK")
                    color: podphoenix.appTheme.positiveActionButton
                    onClicked: {
                        podphoenix.settings.skipForward = Math.round(slider.value)
                        PopupUtils.close(dialogInternal)
                    }
                }
                Button {
                    text: i18n.tr("Cancel")
                    color: podphoenix.appTheme.neutralActionButton
                    onClicked: {
                        PopupUtils.close(dialogInternal)
                    }
                }
            }
        }

        Component {
            id: skipBackDialog
            Dialog {
                id: dialogInternal
                // TRANSLATORS: This strings refers to the seeking of the episode playback. Users can set how far they
                // want to seek backward when pressing on this button.
                title: i18n.tr("Skip back")
                Slider {
                    id: slider
                    width: parent.width
                    minimumValue: 0
                    maximumValue: 60
                    value: podphoenix.settings.skipBack
                    function formatValue(v) { return i18n.tr("%1 seconds").arg(Math.round(v)) }
                    StyleHints { foregroundColor: podphoenix.appTheme.focusText }
                }

                Button {
                    text: i18n.tr("OK")
                    color: podphoenix.appTheme.positiveActionButton
                    onClicked: {
                        podphoenix.settings.skipBack = Math.round(slider.value)
                        PopupUtils.close(dialogInternal)
                    }
                }
                Button {
                    text: i18n.tr("Cancel")
                    color: podphoenix.appTheme.neutralActionButton
                    onClicked: {
                        PopupUtils.close(dialogInternal)
                    }
                }
            }
        }

        Component {
            id: refreshDialog
            Dialog {
                id: dialogInternal
                // TRANSLATORS: This strings refers to refreshing podcasts. Users can set how often they
                // want to check for new episodes.
                title: i18n.tr("Refresh podcasts after")
                Slider {
                    id: slider
                    width: parent.width
                    minimumValue: 0
                    maximumValue: 72
                    value: podphoenix.settings.refreshEpisodes
                    function formatValue(v) { return i18n.tr("%1 hours").arg(Math.round(v)) }
                    StyleHints { foregroundColor: podphoenix.appTheme.focusText }
                }

                Button {
                    text: i18n.tr("OK")
                    color: podphoenix.appTheme.positiveActionButton
                    onClicked: {
                        podphoenix.settings.refreshEpisodes = Math.round(slider.value)
                        PopupUtils.close(dialogInternal)
                    }
                }
                Button {
                    text: i18n.tr("Cancel")
                    color: podphoenix.appTheme.neutralActionButton
                    onClicked: {
                        PopupUtils.close(dialogInternal)
                    }
                }
            }
        }

        Column {
            id: settingsColumn

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }

            HeaderListItem {
                // TRANSLATORS: Shortened form of "Miscellaneous" which is shown to denote other setting options
                // that doesn't fit into any other category.
                title.text: i18n.tr("General Settings")
            }

            SingleValueListItem {
                divider.visible: false
                title.text: i18n.tr("Theme")
                value: podphoenix.settings.themeName.split(".qml")[0] === "Light" ? i18n.tr("Light") : i18n.tr("Dark")
                onClicked: mainStack.push(Qt.resolvedUrl("../settings/ThemeSetting.qml"))
            }

            ListItem {
                ListItemLayout {
                    id: gridViewLayout
                    title.text: i18n.tr("Displays podcasts in a list view")
                    Switch {
                        SlotsLayout.position: SlotsLayout.Last
                        checked: podphoenix.settings.showListView
                        onClicked: podphoenix.settings.showListView = checked
                    }
                }
                divider.visible: false
                height: gridViewLayout.height
            }

            HeaderListItem {
                title.text: i18n.tr("Playback Settings")
            }

            SingleValueListItem {
                divider.visible: false
                title.text: i18n.tr("Skip forward")
                value: i18n.tr("%1 seconds").arg(podphoenix.settings.skipForward)
                onClicked: PopupUtils.open(skipForwardDialog, settingsPage);
            }

            SingleValueListItem {
                divider.visible: false
                title.text: i18n.tr("Skip back")
                value: i18n.tr("%1 seconds").arg(podphoenix.settings.skipBack)
                onClicked: PopupUtils.open(skipBackDialog, settingsPage);
            }

            ListItem {
                ListItemLayout {
                    id: continueWhereStopped
                    title.text: i18n.tr("Continue where stopped")
                    Switch {
                        SlotsLayout.position: SlotsLayout.Last
                        checked: podphoenix.settings.continueWhereStopped
                        onClicked: podphoenix.settings.continueWhereStopped = checked
                    }
                }
                divider.visible: false
                height: gridViewLayout.height
            }

            HeaderListItem {
                title.text: i18n.tr("Podcast Episode Settings")
            }

            SingleValueListItem {
                divider.visible: false
                title.text: i18n.tr("Refresh podcasts after")
                value: i18n.tr("%1 hours").arg(podphoenix.settings.refreshEpisodes)
                onClicked: PopupUtils.open(refreshDialog, settingsPage);
            }

            ListItem {
                ListItemLayout {
                    id: deleteLayout
                    title.text: i18n.tr("Automatically delete old episodes")
                    title.color: podphoenix.appTheme.baseText
                    summary.text: i18n.tr("Delete episodes that are older than a given number of days for each podcast")
                    summary.color: podphoenix.appTheme.baseSubText
                    ProgressionSlot {}
                }
                divider.visible: false
                height: deleteLayout.height
                onClicked: mainStack.push(Qt.resolvedUrl("../settings/CleanSetting.qml"))
            }

            ListItem {
                ListItemLayout {
                    id: downloadLayout
                    title.text: i18n.tr("Automatically download new episodes")
                    title.color: podphoenix.appTheme.baseText
                    summary.text: i18n.tr("Default number of new episodes to download for each podcast")
                    summary.color: podphoenix.appTheme.baseSubText
                    ProgressionSlot{}
                }
                divider.visible: false
                height: downloadLayout.height
                onClicked: mainStack.push(Qt.resolvedUrl("../settings/DownloadSetting.qml"))
            }

 	ListItem {
                ListItemLayout {
                    id: downloadWifiOnlyLayout
                    title.text: i18n.tr("Only download over WiFi")
                    title.color: podphoenix.appTheme.baseText
                    summary.text: i18n.tr("Download episodes only when the device is using WiFi")
                    summary.color: podphoenix.appTheme.baseSubText
                    Switch {
                        SlotsLayout.position: SlotsLayout.Last
                        checked: podphoenix.settings.downloadOverWifiOnly
                        onClicked: podphoenix.settings.downloadOverWifiOnly = checked
                    }
                }
                divider.visible: false
                height: downloadWifiOnlyLayout.height
            }

            ListItem {
                id: refreshArtListItem

                property int numberOfPodcasts: 0
                property int queueLength: imageDownloader.queueLength

                ListItemLayout {
                    id: refreshArt
                    title.text: i18n.tr("Refresh podcast artwork")
                    title.color: podphoenix.appTheme.baseText
                    summary.text: i18n.tr("Update all podcasts artwork and fix missing ones")
                    summary.color: podphoenix.appTheme.baseSubText
                    summary.maximumLineCount: 3
                    ProgressionSlot{}
                }

                CustomProgressBar {
                    id: progressBar
                    anchors { top: refreshArt.bottom; left: parent.left; right: parent.right; leftMargin: units.gu(2); rightMargin: units.gu(2) }
                    progress: (refreshArtListItem.numberOfPodcasts - refreshArtListItem.queueLength) * (100 / refreshArtListItem.numberOfPodcasts)
                    height: progress > 0  && progress < 100 ? units.dp(5) : 0
                }

                divider.visible: false
                height: refreshArt.height + progressBar.height
                onClicked: {
                    var db = Podcasts.init()
                    db.transaction(function (tx) {
                        var rs = tx.executeSql("SELECT rowid, * FROM Podcast ORDER BY name ASC");
                        refreshArtListItem.numberOfPodcasts = rs.rows.length
                        for (var i=0; i < rs.rows.length; i++) {
                            var podcast = rs.rows.item(i);
                            settingsPage.getPodcastCoverArt(podcast.name, podcast.feed, podcast.image)
                        }
                    });
                }
            }

            HeaderListItem {
                title.text: i18n.tr("Storage Settings")
            }

            ListItem {
                id: orphanListItem

                property int fileCount: 0
                property int linkCount: 0

                ListItemLayout {
                    id: orphanLayout
                    title.text: i18n.tr("Delete orphaned files and links")
                    title.color: podphoenix.appTheme.baseText
                    summary.text: i18n.tr("Free space by removing orphaned downloaded files and links")
                    summary.color: podphoenix.appTheme.baseSubText
                    ProgressionSlot {}
                }

                CustomProgressBar {
                    id: orphanProgressBar
                    progress: 200
                    anchors { top: orphanLayout.bottom; left: parent.left; right: parent.right; leftMargin: units.gu(2); rightMargin: units.gu(2) }
                    height: indeterminateProgress ? units.dp(5) : 0
                }

                divider.visible: false
                height: orphanLayout.height + orphanProgressBar.height
                onClicked: {
                    orphanProgressBar.indeterminateProgress = true
                    settingsPage.removeOrphans()
                    orphanProgressBar.indeterminateProgress = false
                    var popup = PopupUtils.open(cleanUpDialog, settingsPage);
                    popup.orphanCount = orphanListItem.fileCount + orphanListItem.linkCount
                }
            }

            Component {
                id: cleanUpDialog
                Dialog {
                    id: dialogInternal

                    property int orphanCount: 0

                    title: orphanCount > 0 ? i18n.tr("Removed orphaned files and links") : i18n.tr("No orphans found!")
                    text: orphanCount > 0 ? i18n.tr("All orphaned files have been deleted to recover disk space. Orphaned links \
pointing at invalid files have also been cleaned up.")
                                          : i18n.tr("No orphaned files have been found to recover disk space. Podphoenix database is clean.")

                    Button {
                        text: i18n.tr("Close")
                        color: podphoenix.appTheme.positiveActionButton
                        onClicked: {
                            PopupUtils.close(dialogInternal)
                        }
                    }
                }
            }

            HeaderListItem {
                // TRANSLATORS: Shortened form of "Miscellaneous" which is shown to denote other setting options
                // that doesn't fit into any other category.
                title.text: i18n.tr("Misc.")
            }

            ListItem {
                ListItemLayout {
                    // TRANSLATORS: About as in information about the app
                    title.text: i18n.tr("About")
                    title.color: podphoenix.appTheme.baseText
                    ProgressionSlot {}
                }
                divider.visible: false
                onClicked: mainStack.push(Qt.resolvedUrl("../settings/About.qml"))
            }

            ListItem {
                ListItemLayout {
                    title.text: i18n.tr("Report Bug")
                    title.color: podphoenix.appTheme.baseText
                    ProgressionSlot {}
                }
                divider.visible: false
                onClicked: Qt.openUrlExternally("https://bugs.launchpad.net/podphoenix/+filebug")
            }
        }
    }

    function getPodcastCoverArt(name, feedUrl, image) {
        // Default first to iTunes to fetch cover art. Fallback to feed url if podcast cannot be
        // found in iTunes.
        getCoverArtItunes(name, feedUrl, image)
    }

    function getCoverArtItunes(name, feedUrl, image) {
        var coverArt = ""
        var url = "https://itunes.apple.com/search?term=" + name + "&media=podcast&entity=podcast"
        var xhr = new XMLHttpRequest;
        xhr.open("GET", url);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var json = JSON.parse(xhr.responseText);
                var db = Podcasts.init();

                for(var i in json.results) {
                    if (name == json.results[i].trackName) {
                        if (feedUrl == json.results[i].feedUrl) {
                            fileManager.deleteFile(image);
                            coverArt = json.results[i].artworkUrl600
                            if (coverArt) {
                                imageDownloader.addDownload(feedUrl, coverArt)
                            }
                        }
                    }
                }

                // If the podcast is not found on iTunes, fallback to its feed url for fetching cover art
                if (coverArt == "") {
                    getCoverArtFeedUrl(name, feedUrl, image)
                }
            }
        }
        xhr.send();
    }

    function getCoverArtFeedUrl(name, feedUrl, image) {
        console.log("Fetching cover art from feed")
        var coverArt
        var xhr = new XMLHttpRequest;
        xhr.open("GET", feedUrl)
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var e = xhr.responseXML.documentElement;

                for(var h = 0; h < e.childNodes.length; h++) {
                    if(e.childNodes[h].nodeName === "channel") {
                        var c = e.childNodes[h];
                        for(var j = 0; j < c.childNodes.length; j++) {
                            var nodeName = c.childNodes[j].nodeName;
                            if (nodeName === "image") {
                                var el = c.childNodes[j];
                                for (var l = 0; l < el.attributes.length; l++) {
                                    if(el.attributes[l].nodeName === "href") {
                                        coverArt = el.attributes[l].nodeValue;
                                        if (coverArt) {
                                            fileManager.deleteFile(image);
                                            imageDownloader.addDownload(feedUrl, coverArt)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        xhr.send()
    }

    function removeOrphans() {
        var filelist = fileManager.getDownloadedEpisodes()

        orphanListItem.fileCount = 0
        orphanListItem.linkCount = 0

        var db = Podcasts.init()
        db.transaction(function (tx) {
            var rs = tx.executeSql("SELECT rowid, * FROM Podcast ORDER BY name ASC");

            // Go through every downloaded file and check if they are orphaned
            for (var l = 0; l < filelist.length; l++) {
                var rs2 = tx.executeSql("SELECT rowid FROM Episode WHERE downloadedfile = ?", [fileManager.podcastDirectory + "/" + filelist[l]])

                if (rs2.rows.length == 0) {
                    orphanListItem.fileCount++
                    fileManager.deleteFile(fileManager.podcastDirectory + "/" + filelist[l])
                    console.log("[LOG]: Removed Orphan File: " + fileManager.podcastDirectory + "/" + filelist[l])
                }
            }

            // Filter all episode with downloadedfile links and check if they are orphaned links or not
            var rs2 = tx.executeSql("SELECT rowid, * FROM Episode WHERE downloadedfile IS NOT NULL")
            for (var i=0; i<rs2.rows.length; i++) {
                var isOrphanLink = true
                var episode = rs2.rows.item(i);

                for (var l = 0; l < filelist.length; l++) {
                    if(episode.downloadedfile === fileManager.podcastDirectory + "/" + filelist[l]) {
                        isOrphanLink = false
                        break
                    }
                }

                if (isOrphanLink) {
                    orphanListItem.linkCount++
                    tx.executeSql("UPDATE Episode SET downloadedfile = NULL WHERE guid = ?", [episode.guid]);
                    console.log("[LOG]: Removed Orphan Link: " + episode.downloadedfile)
                }
            }
        });
    }
}


