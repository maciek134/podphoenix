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
import QtMultimedia 5.4
import Ubuntu.Components 1.3
import QtQuick.LocalStorage 2.0
import Ubuntu.DownloadManager 0.1
import Ubuntu.Components.Popups 1.3
import "../podcasts.js" as Podcasts
import "../components"

Tab {
    id: episodesTab

    property var today: new Date()
    property int dayToMs: 86400000
    property string tempGuid: "NULL"
    property bool episodesUpdating: false

    TabsList {
        id: tabsList
    }

    page: Page {
        id: episodesPage

        header: standardHeader

        PageHeader {
            id: standardHeader
            visible: episodesPage.header === standardHeader
            title: i18n.tr("Episodes")

            StyleHints {
                backgroundColor: podbird.appTheme.background
            }

            leadingActionBar {
                numberOfSlots: 0
                actions: tabsList.actions
            }

            trailingActionBar.actions: [
                Action {
                    iconName: "search"
                    text: i18n.tr("Search Episode")
                    onTriggered: {
                        episodesPage.header = searchHeader
                        searchField.item.forceActiveFocus()
                    }
                },

                Action {
                    iconName: "select"
                    visible: episodesPageHeaderSections.selectedIndex === 0
                    text: i18n.tr("Mark all listened")
                    onTriggered: {
                        var db = Podcasts.init();
                        db.transaction(function (tx) {
                            for (var i=0; i<episodesModel.count; i++) {
                                tx.executeSql("UPDATE Episode SET listened=1 WHERE guid=?", [episodesModel.get(i).guid]);
                            }
                            episodesModel.clear()
                        });
                    }
                },

                Action {
                    iconName: "save"
                    visible: episodesPageHeaderSections.selectedIndex === 0
                    text: i18n.tr("Download all")
                    onTriggered: {
                        var db = Podcasts.init();
                        db.transaction(function (tx) {
                            for (var i=0; i<episodesModel.count; i++) {
                                if (!episodesModel.get(i).downloadedfile) {
                                    episodesModel.setProperty(i, "queued", 1)
                                    tx.executeSql("UPDATE Episode SET queued=1 WHERE guid = ?", [episodesModel.get(i).guid]);
                                    downloader.addDownload(episodesModel.get(i).guid, episodesModel.get(i).audiourl);
                                }
                            }
                        });
                    }
                },

                Action {
                    iconName: "delete"
                    text: i18n.tr("Delete all")
                    visible: episodesPageHeaderSections.selectedIndex === 1
                    onTriggered: {
                        var db = Podcasts.init();
                        db.transaction(function (tx) {
                            for (var i=0; i<episodesModel.count; i++) {
                                if (episodesModel.get(i).downloadedfile) {
                                    fileManager.deleteFile(episodesModel.get(i).downloadedfile);
                                    tx.executeSql("UPDATE Episode SET downloadedfile = NULL WHERE guid = ?", [episodesModel.get(i).guid]);
                                    episodesModel.setProperty(i, "downloadedfile", "")
                                }
                            }
                        });
                        refreshModel();
                    }
                }
            ]

            extension: Sections {
                id: episodesPageHeaderSections

                anchors {
                    left: parent.left
                    leftMargin: units.gu(2)
                    bottom: parent.bottom
                }

                StyleHints {
                    selectedSectionColor: podbird.appTheme.focusText
                }

                model: [i18n.tr("New"), i18n.tr("Downloaded"), i18n.tr("Favourites")]
                onSelectedIndexChanged: {
                    refreshModel();
                }
            }
        }

        PageHeader {
            id: searchHeader
            visible: episodesPage.header === searchHeader

            StyleHints {
                backgroundColor: podbird.appTheme.background
            }

            contents: Loader {
                id: searchField
                sourceComponent: episodesPage.header === searchHeader ? searchFieldComponent : undefined
                anchors.left: parent ? parent.left : undefined
                anchors.right: parent ? parent.right : undefined
                anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            }

            leadingActionBar.actions: [
                Action {
                    iconName: "back"
                    onTriggered: {
                        episodeList.forceActiveFocus()
                        episodesPage.header = standardHeader
                    }
                }
            ]
        }

        Component {
            id: searchFieldComponent
            TextField {
                inputMethodHints: Qt.ImhNoPredictiveText
                placeholderText: i18n.tr("Search episode")
            }
        }

        Loader {
            id: emptyState

            anchors {
                left: parent.left
                right: parent.right
                margins: units.gu(2)
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: Qt.inputMethod.visible ? units.gu(4) : 0
            }

            sourceComponent: episodesModel.count === 0 || sortedEpisodeModel.count === 0 ? emptyStateComponent : undefined
        }

        Component {
            id: emptyStateComponent
            EmptyState {
                icon.source: episodesModel.count === 0 ? Qt.resolvedUrl("../graphics/owlSearch.svg") : Qt.resolvedUrl("../graphics/notFound.svg")
                title: {
                    if (episodesModel.count === 0 && episodesPage.header === standardHeader) {
                        if (episodesPageHeaderSections.selectedIndex === 0)
                            return i18n.tr("No New Episodes")
                        else if (episodesPageHeaderSections.selectedIndex === 1)
                            return i18n.tr("No Downloaded Episodes")
                        else if (episodesPageHeaderSections.selectedIndex === 2)
                            return i18n.tr("No Favourited Episodes")
                    } else {
                        return i18n.tr("No Episodes Found")
                    }
                }
                subTitle: {
                    if (episodesModel.count === 0 && episodesPage.header === standardHeader) {
                        if (episodesPageHeaderSections.selectedIndex === 0)
                            return i18n.tr("No more episodes to listen to!")
                        else if (episodesPageHeaderSections.selectedIndex === 1)
                            return i18n.tr("No episodes have been downloaded for offline listening")
                        else if (episodesPageHeaderSections.selectedIndex === 2)
                            return i18n.tr("No episodes have been favourited.")
                    } else {
                        return i18n.tr("No Episodes found matching the search term.")
                    }
                }
            }
        }

        ListModel {
            id: episodesModel
        }

        SortFilterModel {
            id: sortedEpisodeModel
            model: episodesModel
            filter.property: "name"
            filter.pattern: episodesPage.header === searchHeader && searchField.status == Loader.Ready ? RegExp(searchField.item.text, "gi")
                                                                                                       : RegExp("", "gi")
        }

        onVisibleChanged: {
            if (visible) {
                refreshModel()
                if (downloader.downloadingGuid != "")
                    tempGuid = downloader.downloadingGuid
            } else {
                episodesPage.header = standardHeader
            }
        }

        Connections {
            target: downloader
            onDownloadingGuidChanged: {
                var db = Podcasts.init();
                db.transaction(function (tx) {
                    /*
                     If tempGuid is NULL, then the episode currently being downloaded is not found within
                     this podcast. On the other hand, if it is within this podcast, then update the episodesModel
                     with the downloadedfile location we just received from the downloader.
                    */
                    if (tempGuid != "NULL") {
                        var rs2 = tx.executeSql("SELECT downloadedfile FROM Episode WHERE guid=?", [tempGuid]);
                        for (var i=0; i<episodesModel.count; i++) {
                            if (episodesModel.get(i).guid == tempGuid) {
                                console.log("[LOG]: Setting episode download URL to " + rs2.rows.item(0).downloadedfile)
                                episodesModel.setProperty(i, "downloadedfile", rs2.rows.item(0).downloadedfile)
                                episodesModel.setProperty(i, "queued", 0)
                                break
                            }
                        }
                        tempGuid = "NULL"
                    }

                    /*
                     Here it is checked if the currently downloaded episode belongs to the podcast
                     page being currently displayed. If it is, then the downloaded episode guid is
                     stored in the tempGuid variable to track it.
                    */
                    var rs = tx.executeSql("SELECT podcast FROM Episode WHERE guid=?", [downloader.downloadingGuid]);

                    if (downloader.downloadingGuid != "" && tempGuid == "NULL") {
                        tempGuid = downloader.downloadingGuid
                    }
                });
                refreshModel();
            }
        }

        /*
         Note (nik90): After the upgrade to Ubuntu.Components 1.2, it seems the new listitems don't have their trailing
         action width clamped. As a result when the list item expands and the user swipes left, it leads to a rather huge
         trailing edge action. This has been reported upstream at http://pad.lv/1465582. Until this is fixed, the
         episode description is shown in a dialog.
        */
        Component {
            id: episodeDescriptionDialog
            Dialog {
                id: dialogInternal

                property string description

                title: "<b>%1</b>".arg(i18n.tr("Episode Description"))

                Label {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    linkColor: "Blue"
                    text: dialogInternal.description
                    onLinkActivated: Qt.openUrlExternally(link)
                }

                Button {
                    text: i18n.tr("Close")
                    color: podbird.appTheme.positiveActionButton
                    onClicked: {
                        PopupUtils.close(dialogInternal)
                    }
                }
            }
        }

        ListView {
            id: episodeList

            Component.onCompleted: {
                // FIXME: workaround for qtubuntu not returning values depending on the grid unit definition
                // for Flickable.maximumFlickVelocity and Flickable.flickDeceleration
                var scaleFactor = units.gridUnit / 8;
                maximumFlickVelocity = maximumFlickVelocity * scaleFactor;
                flickDeceleration = flickDeceleration * scaleFactor;
            }

            anchors {
                top: episodesPage.header.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            clip: true
            model: sortedEpisodeModel
            section.property: "diff"
            section.labelPositioning: ViewSection.InlineLabels

            section.delegate: ListItem {
                height: headerText.title.text !== "" ? headerText.height + divider.height : units.gu(0)
                divider.anchors.leftMargin: units.gu(2)
                divider.anchors.rightMargin: units.gu(2)

                ListItemLayout {
                    id: headerText
                    title.text: {
                        if (section === "Today") {
                            return i18n.tr("Today")
                        }

                        else if (section === "Yesterday") {
                            return i18n.tr("Yesterday")
                        }

                        else if (section === "Older") {
                            return i18n.tr("Older")
                        }

                        else {
                            return ""
                        }
                    }
                    title.color: podbird.appTheme.baseText
                    title.font.weight: Font.DemiBold
                }
            }

            footer: Item {
                width: parent.width
                height: units.gu(8)
            }

            delegate: ListItem {
                id: listItem

                divider.visible: false
                highlightColor: "Transparent"
                height: downloader.downloadingGuid === model.guid ? listItemLayout.height + progressBarLoader.height + units.gu(1) : listItemLayout.height + units.gu(0.5)
                color: index % 2 === 0 ? podbird.appTheme.hightlightListView : "Transparent"

                ListItemLayout {
                    id: listItemLayout

                    title.text: model.name !== undefined ? model.name.trim() : "Undefined"
                    title.color: currentGuid === model.guid || downloader.downloadingGuid === model.guid ? podbird.appTheme.focusText
                                                                                                         : podbird.appTheme.baseText
                    // #FIXME: Change this 2 to prevent title eliding when UITK is updated to rev > 1800
                    title.maximumLineCount: 1

                    subtitle.text: model.duration === 0 || model.duration === undefined ? model.downloadedfile ? "📎 " + model.artist
                                                                                                               : model.artist
                                                                                        : model.downloadedfile ? "📎 " + Podcasts.formatEpisodeTime(model.duration) + " | " + model.artist
                                                                                                               : Podcasts.formatEpisodeTime(model.duration) + " | " + model.artist
                    subtitle.color: podbird.appTheme.baseSubText

                    Image {
                        height: width
                        width: units.gu(6)
                        source: model.image !== undefined ? model.image : Qt.resolvedUrl("../graphics/podbird.png")
                        SlotsLayout.position: SlotsLayout.Leading
                        sourceSize { width: width; height: height }
                    }

                    padding.top: units.gu(1)
                    padding.bottom: units.gu(0.5)
                }

                Loader {
                    id: progressBarLoader
                    anchors { top: listItemLayout.bottom; left: parent.left; right: parent.right; leftMargin: units.gu(2); rightMargin: units.gu(2) }
                    height: sourceComponent !== undefined ? units.dp(5) : 0
                    visible: sourceComponent !== undefined
                    sourceComponent: downloader.downloadingGuid === model.guid ? progressBar : undefined
                }

                Component {
                    id: progressBar
                    CustomProgressBar {
                        indeterminateProgress: downloader.progress < 0 || downloader.progress > 100 && downloader.downloadingGuid === model.guid
                        progress: downloader.progress
                    }
                }

                trailingActions: ListItemActions {
                    actions: [
                        Action {
                            iconName: model.downloadedfile ? "delete" : (model.queued && downloader.downloadingGuid !== model.guid ? "history" : "save")
                            onTriggered: {
                                var db = Podcasts.init();
                                if (model.downloadedfile) {
                                    fileManager.deleteFile(model.downloadedfile);
                                    db.transaction(function (tx) {
                                        tx.executeSql("UPDATE Episode SET downloadedfile = NULL WHERE guid = ?", [model.guid]);
                                    });
                                    episodesModel.setProperty(model.index, "downloadedfile", "")
                                    if (episodesPageHeaderSections.selectedIndex === 1) {
                                        episodesModel.remove(model.index, 1)
                                    }
                                } else {
                                    db.transaction(function (tx) {
                                        tx.executeSql("UPDATE Episode SET queued=1 WHERE guid = ?", [model.guid]);
                                    });
                                    episodesModel.setProperty(model.index, "queued", 1)
                                    downloader.addDownload(model.guid, model.audiourl);
                                }
                            }
                        },

                        Action {
                            iconName: model.listened ? "view-collapse" : "select"
                            onTriggered: {
                                var db = Podcasts.init();
                                db.transaction(function (tx) {
                                    if (model.listened) {
                                        tx.executeSql("UPDATE Episode SET listened=0 WHERE guid=?", [model.guid])
                                        episodesModel.setProperty(model.index, "listened", 0)
                                    }
                                    else {
                                        tx.executeSql("UPDATE Episode SET listened=1 WHERE guid=?", [model.guid])
                                        episodesModel.setProperty(model.index, "listened", 1)
                                        if (episodesPageHeaderSections.selectedIndex === 0) {
                                            episodesModel.remove(model.index, 1)
                                        }
                                    }
                                });
                            }
                        },

                        Action {
                            iconName: model.favourited ? "unlike" : "like"
                            onTriggered: {
                                var db = Podcasts.init();
                                db.transaction(function (tx) {
                                    if (model.favourited) {
                                        tx.executeSql("UPDATE Episode SET favourited=0 WHERE guid=?", [model.guid])
                                        episodesModel.setProperty(model.index, "favourited", 0)
                                        if (episodesPageHeaderSections.selectedIndex === 2) {
                                            episodesModel.remove(model.index, 1)
                                        }
                                    }
                                    else {
                                        tx.executeSql("UPDATE Episode SET favourited=1 WHERE guid=?", [model.guid])
                                        episodesModel.setProperty(model.index, "favourited", 1)
                                    }
                                });
                            }
                        },

                        Action {
                            iconName: "info"
                            onTriggered: {
                                var popup = PopupUtils.open(episodeDescriptionDialog, episodesTab);
                                popup.description = model.description
                            }
                        }
                    ]
                }

                onClicked: {
                    Haptics.play()
                    var db = Podcasts.init();
                    db.transaction(function (tx) {
                        if (currentGuid !== model.guid) {
                            currentGuid = "";
                            currentUrl = model.downloadedfile ? model.downloadedfile : model.audiourl;
                            var rs = tx.executeSql("SELECT position FROM Episode WHERE guid=?", [model.guid]);
                            playerLoader.item.play();
                            playerLoader.item.seek(rs.rows.item(0).position);
                            currentName = model.name;
                            currentArtist = model.artist;
                            currentImage = model.image;
                            currentGuid = model.guid;
                        }
                    });
                }
            }

            Scrollbar {
                flickableItem: episodeList
                align: Qt.AlignTrailing
                StyleHints { sliderColor: podbird.appTheme.focusText }
            }

            PullToRefresh {
                refreshing: episodesUpdating
                onRefresh: updateEpisodesDatabase();
            }
        }
    }

    function refreshModel() {
        var i, j, episode
        var db = Podcasts.init()

        episodesModel.clear()

        // Episode Model for the what's new view
        if (episodesPageHeaderSections.selectedIndex === 0) {
            var today = new Date()
            var dayToMs = 86400000; //1 * 24 * 60 * 60 * 1000
            var todayCount, yesterdayCount, diff

            todayCount = 0
            yesterdayCount = 0

            db.transaction(function (tx) {
                var rs = tx.executeSql("SELECT rowid, * FROM Podcast ORDER BY name ASC");
                for (i=0; i < rs.rows.length; i++) {
                    var podcast = rs.rows.item(i);
                    var rs2 = tx.executeSql("SELECT rowid, * FROM Episode WHERE podcast=? ORDER BY published DESC", [rs.rows.item(i).rowid]);
                    for (j=0; j < rs2.rows.length; j++) {
                        episode = rs2.rows.item(j)
                        diff = Math.floor((today - episode.published)/dayToMs)
                        if (diff < 7 && !episode.listened) {
                            if (diff < 1) {
                                episodesModel.insert(todayCount, {"guid" : episode.guid, "listened" : episode.listened, "published": episode.published, "name" : episode.name, "description" : episode.description, "duration" : episode.duration, "position" : episode.position, "downloadedfile" : episode.downloadedfile, "image" : podcast.image, "artist" : podcast.artist, "audiourl" : episode.audiourl, "queued": episode.queued, "favourited": episode.favourited, "diff": "Today"})
                                todayCount++;
                            } else if (diff < 2) {
                                episodesModel.insert(todayCount + yesterdayCount, {"guid" : episode.guid, "listened" : episode.listened, "published": episode.published, "name" : episode.name, "description" : episode.description, "duration" : episode.duration, "position" : episode.position, "downloadedfile" : episode.downloadedfile, "image" : podcast.image, "artist" : podcast.artist, "audiourl" : episode.audiourl, "queued": episode.queued, "favourited": episode.favourited, "diff": "Yesterday"})
                                yesterdayCount++;
                            } else {
                                episodesModel.append({"guid" : episode.guid, "listened" : episode.listened, "published": episode.published, "name" : episode.name, "description" : episode.description, "duration" : episode.duration, "position" : episode.position, "downloadedfile" : episode.downloadedfile, "image" : podcast.image, "artist" : podcast.artist, "audiourl" : episode.audiourl, "queued": episode.queued, "favourited": episode.favourited, "diff": "Older"})
                            }
                        } else if (diff >= 7){
                            break
                        }
                    }

                    if (podcast.lastupdate === null && !episodesUpdating) {
                        updateEpisodesDatabase();
                    }
                }
            });
        }

        // Episode Model for the downloaded view
        else if (episodesPageHeaderSections.selectedIndex === 1) {
            db.transaction(function (tx) {
                var rs = tx.executeSql("SELECT rowid, * FROM Podcast ORDER BY name ASC");
                for (i=0; i < rs.rows.length; i++) {
                    var podcast = rs.rows.item(i);
                    var rs2 = tx.executeSql("SELECT rowid, * FROM Episode WHERE podcast=? ORDER BY published DESC", [rs.rows.item(i).rowid]);
                    for (j=0; j < rs2.rows.length; j++) {
                        episode = rs2.rows.item(j)
                        if (episode.downloadedfile) {
                            episodesModel.append({"guid" : episode.guid, "listened" : episode.listened, "published": episode.published, "name" : episode.name, "description" : episode.description, "duration" : episode.duration, "position" : episode.position, "downloadedfile" : episode.downloadedfile, "image" : podcast.image, "artist" : podcast.artist, "audiourl" : episode.audiourl, "queued": episode.queued, "favourited": episode.favourited, "diff": "Null"})
                        }
                    }

                    if (podcast.lastupdate === null && !episodesUpdating) {
                        updateEpisodesDatabase();
                    }
                }
            });
        }

        // Episode Model for the favourites view
        else if (episodesPageHeaderSections.selectedIndex === 2) {
            db.transaction(function (tx) {
                var rs = tx.executeSql("SELECT rowid, * FROM Podcast ORDER BY name ASC");
                for (i=0; i < rs.rows.length; i++) {
                    var podcast = rs.rows.item(i);
                    var rs2 = tx.executeSql("SELECT rowid, * FROM Episode WHERE podcast=? ORDER BY published DESC", [rs.rows.item(i).rowid]);
                    for (j=0; j < rs2.rows.length; j++) {
                        episode = rs2.rows.item(j)
                        if (episode.favourited) {
                            episodesModel.append({"guid" : episode.guid, "listened" : episode.listened, "published": episode.published, "name" : episode.name, "description" : episode.description, "duration" : episode.duration, "position" : episode.position, "downloadedfile" : episode.downloadedfile, "image" : podcast.image, "artist" : podcast.artist, "audiourl" : episode.audiourl, "queued": episode.queued, "favourited": episode.favourited, "diff": "Null"})
                        }
                    }

                    if (podcast.lastupdate === null && !episodesUpdating) {
                        updateEpisodesDatabase();
                    }
                }
            });
        }

        episodesUpdating = false;
    }

    function updateEpisodesDatabase() {
        console.log("[LOG]: Checking for new episodes")
        episodesUpdating = true;
        Podcasts.updateEpisodes(refreshModel)
    }
}

