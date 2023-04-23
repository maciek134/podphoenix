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
import QtMultimedia 5.6
import Ubuntu.Components 1.3
import QtQuick.LocalStorage 2.0
import Ubuntu.DownloadManager 1.2
import Ubuntu.Components.Popups 1.3
import "../podcasts.js" as Podcasts
import "../components"

Page {
    id: episodesPage

    visible: false

    property string episodeName
    property string episodeId
    property string episodeArtist
    property string episodeImage
    property string tempGuid: "NULL"
    property string mode: "listened"

    Component.onCompleted: {
        loadEpisodes(episodeId, episodeArtist, episodeImage)
        if (downloader.downloadingGuid != "")
            tempGuid = downloader.downloadingGuid
    }

    header: standardHeader

    PageHeader {
        id: standardHeader
        title: i18n.tr("Podcast")
        flickable: null

        StyleHints {
            backgroundColor: podphoenix.appTheme.background
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
                text: i18n.tr("Unsubscribe")
                iconName: "delete"
                onTriggered: {
                    PopupUtils.open(confirmDeleteDialog, episodesPage);
                }
            }
        ]
    }

    PageHeader {
        id: searchHeader
        visible: episodesPage.header === searchHeader
        flickable: null

        leadingActionBar.actions: Action {
            iconName: "back"
            onTriggered: {
                episodeList.forceActiveFocus()
                episodesPage.header = standardHeader
                episodeList.positionViewAtBeginning()
            }
        }

        StyleHints {
            backgroundColor: podphoenix.appTheme.background
        }

        contents: Loader {
            id: searchField
            sourceComponent: episodesPage.header === searchHeader ? searchFieldComponent : undefined
            anchors.left: parent ? parent.left : undefined
            anchors.right: parent ? parent.right : undefined
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        }
    }

    PageHeader {
        id: selectionHeader
        visible: episodeList.ViewItems.selectMode
        // TRANSLATORS: This is the page title. Keep it short. Otherwise it will just be elided.
        title: i18n.tr("%1 item selected", "%1 items selected", episodeList.ViewItems.selectedIndices.length).arg(episodeList.ViewItems.selectedIndices.length)

        onVisibleChanged: {
            if (visible) {
                episodesPage.header = selectionHeader
            }
        }

        StyleHints {
            backgroundColor: podphoenix.appTheme.background
        }

        leadingActionBar.actions: [
            Action {
                iconName: "back"
                text: i18n.tr("Back")
                onTriggered: {
                    episodeList.closeSelection()
                }
            }
        ]

        trailingActionBar {
            numberOfSlots: 6
            actions: [
                Action {
                    iconName: "select"
                    text: i18n.tr("Mark Listened")
                    enabled: episodeList.ViewItems.selectedIndices.length !== 0
                    visible: episodesPage.mode !== "listened"
                    onTriggered: {
                        var db = Podcasts.init();
                        db.transaction(function (tx) {
                            for (var i=0; i<episodeList.ViewItems.selectedIndices.length; i++) {
                                var index = episodeList.ViewItems.selectedIndices[i]
                                tx.executeSql("UPDATE Episode SET listened=1 WHERE guid=?", [episodeModel.get(index).guid]);
                            }
                        });

                        refreshModel();
                        episodeList.closeSelection()
                    }
                },

                Action {
                    iconName: "save"
                    text: i18n.tr("Download episode(s)")
                    enabled: episodeList.ViewItems.selectedIndices.length !== 0
                    visible: episodesPage.mode !== "downloaded"

                    onTriggered: {
                        var db = Podcasts.init();
                        db.transaction(function (tx) {
                            for (var i=0; i<episodeList.ViewItems.selectedIndices.length; i++) {
                                var index = episodeList.ViewItems.selectedIndices[i]
                                if (!episodeModel.get(index).downloadedfile) {
                                    episodeModel.setProperty(index, "queued", 1)
                                    tx.executeSql("UPDATE Episode SET queued=1 WHERE guid = ?", [episodeModel.get(index).guid]);
                                    if (episodeModel.get(index).audiourl) {
                                        podphoenix.downloadEpisode(episodeModel.get(index).image, episodeModel.get(index).name, episodeModel.get(index).guid, episodeModel.get(index).audiourl, false)
                                    } else {
                                        console.log("[ERROR]: Invalid download url: " + episodeModel.get(index).audiourl)
                                    }
                                }
                            }
                        });

                        refreshModel();
                        episodeList.closeSelection()
                    }
                },

                Action {
                    iconName: "delete"
                    text: i18n.tr("Delete episode(s)")
                    enabled: episodeList.ViewItems.selectedIndices.length !== 0

                    onTriggered: {
                        var db = Podcasts.init();
                        db.transaction(function (tx) {
                            for (var i=0; i<episodeList.ViewItems.selectedIndices.length; i++) {
                                var index = episodeList.ViewItems.selectedIndices[i]
                                if (episodeModel.get(index).downloadedfile) {
                                    fileManager.deleteFile(episodeModel.get(index).downloadedfile);
                                    tx.executeSql("UPDATE Episode SET downloadedfile = NULL WHERE guid = ?", [episodeModel.get(index).guid]);
                                    episodeModel.setProperty(index, "downloadedfile", "")
                                }
                            }
                        });

                        refreshModel();
                        episodeList.closeSelection()
                    }
                },

                Action {
                    iconName: "like"
                    text: i18n.tr("Favourite episode(s)")
                    enabled: episodeList.ViewItems.selectedIndices.length !== 0

                    onTriggered: {
                        var db = Podcasts.init();
                        db.transaction(function (tx) {
                            for (var i=0; i<episodeList.ViewItems.selectedIndices.length; i++) {
                                var index = episodeList.ViewItems.selectedIndices[i]
                                if (!episodeModel.get(index).favourited) {
                                    tx.executeSql("UPDATE Episode SET favourited=1 WHERE guid=?", [episodeModel.get(index).guid])
                                    episodeModel.setProperty(index, "favourited", 1)
                                }
                            }
                        });

                        refreshModel();
                        episodeList.closeSelection()
                    }
                },

                Action {
                    iconName: "add-to-playlist"
                    text: i18n.tr("Add to queue")
                    enabled: episodeList.ViewItems.selectedIndices.length !== 0

                    onTriggered: {
                        for (var i=0; i<episodeList.ViewItems.selectedIndices.length; i++) {
                            var index = episodeList.ViewItems.selectedIndices[i]
                            if (episodeModel.get(index).audiourl) {
                                var url = episodeModel.get(index).downloadedfile ? "file://" + episodeModel.get(index).downloadedfile : episodeModel.get(index).audiourl
                                player.addEpisodeToQueue(episodeModel.get(index).guid, episodeModel.get(index).image, episodeModel.get(index).name, episodeModel.get(index).artist, url, episodeModel.get(index).position)
                            }
                        }

                        episodeList.closeSelection()
                    }
                }
            ]
        }
    }

    onVisibleChanged: {
        if (!visible) {
            state = "default";
        }
    }

    Component {
        id: searchFieldComponent
        TextField {
            inputMethodHints: Qt.ImhNoPredictiveText
            placeholderText: i18n.tr("Search episode")
        }
    }

    Connections {
        target: downloader
        onDownloadingGuidChanged: {
            var db = Podcasts.init();
            db.transaction(function (tx) {
                /*
                 If tempGuid is NULL, then the episode currently being downloaded is not found within
                 this podcast. On the other hand, if it is within this podcast, then update the episodeModel
                 with the downloadedfile location we just received from the downloader.
                */
                if (tempGuid != "NULL") {
                    var rs2 = tx.executeSql("SELECT downloadedfile, podcast FROM Episode WHERE guid=?", [tempGuid]);
                    for (var i=0; i<episodeModel.count; i++) {
                        if (episodeModel.get(i).guid == tempGuid) {
                            console.log("[LOG]: Setting episode download URL to " + rs2.rows.item(0).downloadedfile)
                            episodeModel.setProperty(i, "downloadedfile", rs2.rows.item(0).downloadedfile)
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

                if (downloader.downloadingGuid != "" && rs.rows.item(0).podcast == episodeId && tempGuid == "NULL") {
                    tempGuid = downloader.downloadingGuid
                }
            });
            refreshModel();
        }
    }

    Component {
        id: confirmDeleteDialog
        Dialog {
            id: dialogInternal
            title: i18n.tr("Unsubscribe Confirmation")
            text: i18n.tr("Are you sure you want to unsubscribe from <b>%1</b>?").arg(episodesPage.episodeName)
            Button {
                text: i18n.tr("Unsubscribe")
                color: podphoenix.appTheme.negativeActionButton
                onClicked: {
                    var db = Podcasts.init();
                    db.transaction(function (tx) {
                        var rs = tx.executeSql("SELECT downloadedfile FROM Episode WHERE downloadedfile NOT NULL AND podcast=?", [episodeId]);
                        for(var i = 0; i < rs.rows.length; i++) {
                            fileManager.deleteFile(rs.rows.item(i).downloadedfile);
                        }
                        tx.executeSql("DELETE FROM Episode WHERE podcast=?", [episodeId]);
                        tx.executeSql("DELETE FROM Podcast WHERE rowid=?", [episodeId]);
                        mainStack.pop()
                        PopupUtils.close(dialogInternal)
                    });
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
                color: podphoenix.appTheme.positiveActionButton
                onClicked: {
                    PopupUtils.close(dialogInternal)
                }
            }
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

        sourceComponent: (episodesPage.header === searchHeader && sortedEpisodeModel.count === 0) ? emptyStateComponent
                                                                                                  : undefined
    }

    Component {
        id: emptyStateComponent
        EmptyState {
            icon.source: Qt.resolvedUrl("../graphics/notFound.svg")
            title: i18n.tr("No episodes found")
            subTitle: i18n.tr("No episodes found matching the search term.")
        }
    }

    ListModel {
        id: episodeModel
    }

    SortFilterModel {
        id: sortedEpisodeModel
        model: episodeModel
        filter.property: "name"
        filter.pattern: episodesPage.header === searchHeader && searchField.status == Loader.Ready ? RegExp(searchField.item.text, "gi")
                                                                                                   : RegExp("", "gi")
    }

    ListView {
        id: episodeList

        signal clearSelection()
        signal closeSelection()

        Component.onCompleted: {
            // FIXME: workaround for qtubuntu not returning values depending on the grid unit definition
            // for Flickable.maximumFlickVelocity and Flickable.flickDeceleration
            var scaleFactor = units.gridUnit / 8;
            maximumFlickVelocity = maximumFlickVelocity * scaleFactor;
            flickDeceleration = flickDeceleration * scaleFactor;
        }

        anchors { fill: parent; topMargin: episodesPage.header.height }
        model: sortedEpisodeModel
        clip: true

        header: Column {
            height: coverArtContainer.height + modeTabs.height + units.gu(2)
            Item {
                id: coverArtContainer

                width: episodesPage.width
                visible: episodesPage.header !== searchHeader && sortedEpisodeModel.count !== 0
                height: episodesPage.header !== searchHeader && sortedEpisodeModel.count !== 0 ? cover.height + units.gu(6) : 0

                Image {
                    id:cover
                    width: units.gu(18)
                    height: width
                    sourceSize.height: width
                    sourceSize.width: width
                    source: episodeImage
                    asynchronous: true
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                        margins: units.gu(2)
                    }
                }

                Label {
                    text: episodeName
                    width: parent.width
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    color: podphoenix.appTheme.baseText
                    anchors.top: cover.bottom
                    anchors.topMargin: units.gu(2)
                }
            }

            Item {
                width: parent.width
                height: units.gu(2)
            }

            Item {
                id: modeTabs
                height: unheardTab.implicitHeight + units.gu(2.25)
                width: episodesPage.width

                Rectangle {
                    id: sliderContainer
                    anchors.top: unheardTab.bottom
                    anchors.topMargin: units.gu(1)
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: units.gu(2)
                    height: units.gu(0.25)
                    radius: width/3
                    color: UbuntuColors.lightGrey
                }

                Rectangle {
                    id: slider
                    anchors.top: unheardTab.bottom
                    anchors.topMargin: units.gu(1)
                    height: units.gu(0.25)
                    radius: width/3
                    width: sliderContainer.width/3
                    color: podphoenix.appTheme.focusText
                    x: {
                        if (episodesPage.mode === "unheard")
                            return units.gu(2)
                        else if (episodesPage.mode === "listened")
                            return width + units.gu(2)
                        else
                            return 2 * width + units.gu(2)
                    }

                    Behavior on x {
                        UbuntuNumberAnimation {}
                    }
                }

                Label {
                    id: unheardTab
                    text: i18n.tr("Unheard")
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(2)
                    width: sliderContainer.width/3
                    horizontalAlignment: Text.AlignHCenter
                    font.weight: Font.DemiBold
                    color: episodesPage.mode == "unheard" ? podphoenix.appTheme.focusText : podphoenix.appTheme.baseText

                    AbstractButton {
                        anchors.fill: parent
                        onClicked: episodesPage.mode = "unheard"
                    }
                }

                Label {
                    id: listenedTab
                    anchors.left: unheardTab.right
                    text: i18n.tr("Listened")
                    width: sliderContainer.width/3
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    color: episodesPage.mode == "listened" ? podphoenix.appTheme.focusText : podphoenix.appTheme.baseText

                    AbstractButton {
                        anchors.fill: parent
                        onClicked: episodesPage.mode = "listened"
                    }
                }

                Label {
                    id: downloadedTab
                    anchors.right: parent.right
                    anchors.rightMargin: units.gu(2)
                    width: sliderContainer.width/3
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    text: i18n.tr("Downloaded")
                    color: episodesPage.mode == "downloaded" ? podphoenix.appTheme.focusText : podphoenix.appTheme.baseText

                    AbstractButton {
                        anchors.fill: parent
                        onClicked: episodesPage.mode = "downloaded"
                    }
                }
            }

        }

        footer: Item {
            width: parent.width
            height: units.gu(8)
        }

        delegate: ListItem {
            id: listItem

            divider.visible: false
            highlightColor: podphoenix.appTheme.hightlightListView
            height: visible ? listItemLayout.height + progressBarLoader.height + units.gu(1) : 0

            visible: episodesPage.mode == "listened" ? model.listened
                                                     : (episodesPage.mode == "unheard" ? !model.listened
                                                                                       : model.downloadedfile ? true : false)

            ListItemLayout {
                id: listItemLayout

                title.text: model.name !== undefined ? model.name.trim() : "Undefined"
                title.color: downloader.downloadingGuid === model.guid ? podphoenix.appTheme.focusText
                                                                       : podphoenix.appTheme.baseText
                title.wrapMode: Text.WordWrap
                title.maximumLineCount: 2

                subtitle.text: model.duration === 0 || model.duration === undefined ? model.downloadedfile ? "📎 " + Qt.formatDate(new Date(model.published), "MMM d, yyyy")
                                                                                                           : Qt.formatDate(new Date(model.published), "MMM d, yyyy")
                : model.downloadedfile ? "📎 " + (model.position ? Podcasts.formatEpisodeTime(model.position/1000) + "/" : "") + Podcasts.formatEpisodeTime(model.duration) + " | " + Qt.formatDate(new Date(model.published), "MMM d, yyyy")
                : (model.position ? Podcasts.formatEpisodeTime(model.position/1000) + "/" : "") + Podcasts.formatEpisodeTime(model.duration) + " | " + Qt.formatDate(new Date(model.published), "MMM d, yyyy")
                subtitle.color: podphoenix.appTheme.baseSubText

                padding.top: units.gu(1)
                padding.bottom: units.gu(0.5)
            }

            Loader {
                id: progressBarLoader
                anchors { top: listItemLayout.bottom; left: parent.left; right: parent.right; leftMargin: units.gu(2); rightMargin: units.gu(2) }
                height: downloader.downloadingGuid === model.guid ? units.dp(5) : 0
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
                        iconName: model.listened ? "view-collapse" : "select"
                        text: model.listened ? i18n.tr("Mark as unheard") : i18n.tr("Mark as listened")
                        onTriggered: {
                            var db = Podcasts.init();
                            db.transaction(function (tx) {
                                if (model.listened)
                                    tx.executeSql("UPDATE Episode SET listened=0 WHERE guid=?", [model.guid])
                                else
                                    tx.executeSql("UPDATE Episode SET listened=1 WHERE guid=?", [model.guid])
                                refreshModel();
                            });
                        }
                    },

                    Action {
                        enabled: downloader.downloadingGuid !== model.guid
                        iconName: model.downloadedfile ? "delete" : (model.queued && downloader.downloadingGuid !== model.guid ? "history" : "save")
                        text: model.downloadedfile ? i18n.tr("Delete downloaded file") : (model.queued && downloader.downloadingGuid !== model.guid ? i18n.tr("Queued") : i18n.tr("Download"))
                        onTriggered: {
                            var db = Podcasts.init();
                            if (model.downloadedfile) {
                                fileManager.deleteFile(model.downloadedfile);
                                db.transaction(function (tx) {
                                    tx.executeSql("UPDATE Episode SET downloadedfile = NULL WHERE guid = ?", [model.guid]);
                                });
                                episodeModel.setProperty(model.index, "downloadedfile", "")
                            } else {
                                db.transaction(function (tx) {
                                    tx.executeSql("UPDATE Episode SET queued=1 WHERE guid = ?", [model.guid]);
                                });
                                episodeModel.setProperty(model.index, "queued", 1)
                                if (model.audiourl) {
                                    podphoenix.downloadEpisode(model.image, model.name, model.guid, model.audiourl, false)
                                } else {
                                    console.log("[ERROR]: Invalid download url: " + model.audiourl)
                                }
                            }
                        }
                    },

                    Action {
                        iconName: "add-to-playlist"
                        text: i18n.tr("Add to playlist")
                        onTriggered: {
                            var url = model.downloadedfile ? "file://" + model.downloadedfile : model.audiourl
                            player.addEpisodeToQueue(model.guid, model.image, model.name, model.artist, url, model.position)
                        }
                    },

                    Action {
                        iconName: model.favourited ? "unlike" : "like"
                        text: model.favourited ? i18n.tr("Unfavourite") : i18n.tr("Favourite")
                        onTriggered: {
                            var db = Podcasts.init();
                            db.transaction(function (tx) {
                                if (model.favourited)
                                    tx.executeSql("UPDATE Episode SET favourited=0 WHERE guid=?", [model.guid])
                                else
                                    tx.executeSql("UPDATE Episode SET favourited=1 WHERE guid=?", [model.guid])
                                refreshModel();
                            });
                        }
                    },

                    Action {
                        iconName: "info"
                        text: i18n.tr("Show episode description")
                        onTriggered: {
                            var popup = PopupUtils.open(episodeDescriptionDialog, episodesPage);
                            popup.description = model.description
                        }
                    }
                ]
            }

            onClicked: {
                Haptics.play()
                if (selectMode) {
                    selected = !selected
                } else {
                    if (currentGuid !== model.guid) {
                        player.savePosition()
                        currentUrl = model.downloadedfile ? "file://" + model.downloadedfile : model.audiourl
                        // We need to refetch the episode position as it may have changed without the model refreshing
                        var db = Podcasts.init()
                        db.transaction(function (tx) {
                            var position = 0
                            var rs = tx.executeSql("SELECT position FROM Episode WHERE guid=? AND position > 0", [model.guid])
                            if (rs.rows.length > 0) {
                                position = rs.rows.item(0).position
                            }
                            player.playEpisode(model.guid, model.image, model.name, model.artist, currentUrl, position)
                        });
                    }
                }
            }

            onPressAndHold: {
                ListView.view.ViewItems.selectMode = !ListView.view.ViewItems.selectMode
            }
        }

        onClearSelection: {
            ViewItems.selectedIndices = []
        }

        onCloseSelection: {
            clearSelection()
            ViewItems.selectMode = false
            episodesPage.header = standardHeader
        }

        PullToRefresh {
            refreshing: episodesUpdating
            onRefresh: updateEpisodesDatabase();
        }

        Scrollbar {
            flickableItem: episodeList
            align: Qt.AlignTrailing
        }
    }

    function refreshModel() {
        var db = Podcasts.init();
        loadEpisodes(episodeId, episodeArtist, episodeImage);
        episodesUpdating = false;
    }

    function loadEpisodes(pid, artist, img) {
        var i, episode;
        var newCount = 0;

        episodeModel.clear();

        var db = Podcasts.init();
        db.transaction(function (tx) {
            var rs = tx.executeSql("SELECT rowid, * FROM Episode WHERE podcast=? ORDER BY published", [pid]);
            for(i = 0; i < rs.rows.length; i++) {
                episode = rs.rows.item(i);
                if (!episode.listened) {
                    episodeModel.insert(newCount, {"guid" : episode.guid, "listened" : episode.listened, "published": episode.published, "name" : episode.name, "description" : episode.description, "duration" : episode.duration, "position" : episode.position, "downloadedfile" : episode.downloadedfile, "image" : img, "artist" : artist, "audiourl" : episode.audiourl, "queued": episode.queued, "favourited": episode.favourited});
                    newCount++;
                } else {
                    episodeModel.insert(i,{"guid" : episode.guid, "listened" : episode.listened, "published": episode.published, "name" : episode.name, "description" : episode.description, "duration" : episode.duration, "position" : episode.position, "downloadedfile" : episode.downloadedfile, "image" : img, "artist" : artist, "audiourl" : episode.audiourl, "queued": episode.queued, "favourited": episode.favourited});
                }
            }
        });
    }

    function updateEpisodesDatabase() {
        var db = Podcasts.init();
        db.transaction(function (tx) {
            //refresh all episodes for this podcast, do not care about last update
            var rs = tx.executeSql("UPDATE Podcast SET lastupdate=0 WHERE rowid=?", [episodeId]);
        });

        episodesUpdating = true;
        Podcasts.updateEpisodes(refreshModel)
    }
}
