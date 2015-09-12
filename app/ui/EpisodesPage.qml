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
import QtMultimedia 5.0
import Ubuntu.Components 1.2
import QtQuick.Layouts 1.1
import QtQuick.LocalStorage 2.0
import Ubuntu.DownloadManager 0.1
import Ubuntu.Components.Popups 1.0
import Ubuntu.Components.ListItems 1.0 as ListItem
import "../podcasts.js" as Podcasts
import "../components"

Page {
    id: episodesPage

    visible: false
    title: i18n.tr("Podcast")
    flickable: null

    property string episodeName
    property string episodeId
    property string episodeArtist
    property string episodeImage
    property string tempGuid: "NULL"
    property string mode: "listened"

    property bool episodesUpdating: false;

    Component.onCompleted: {
        loadEpisodes(episodeId, episodeArtist, episodeImage)
        if (downloader.downloadingGuid != "")
            tempGuid = downloader.downloadingGuid
    }

    head.contents: Label {
        text: title
        anchors.fill: parent
        anchors.margins: units.gu(0.5)
        verticalAlignment: Text.AlignVCenter

        fontSize: "x-large"
        fontSizeMode: Text.Fit

        maximumLineCount: 3
        minimumPointSize: 8
        elide: Text.Right
        wrapMode: Text.WordWrap
    }

    state: "default"
    states: [
        PageHeadState {
            name: "default"
            head: episodesPage.head
            actions: [
                Action {
                    iconName: "search"
                    text: i18n.tr("Search Episode")
                    onTriggered: {
                        episodesPage.state = "search"
                        searchField.item.forceActiveFocus()
                    }
                },

                Action {
                    iconName: "select"
                    text: i18n.tr("Mark all listened")
                    onTriggered: {
                        var db = Podcasts.init();
                        db.transaction(function (tx) {
                            tx.executeSql("UPDATE Episode SET listened=1 WHERE podcast=?", [episodeId]);
                            refreshModel();
                        });
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
        },

        PageHeadState {
            name: "search"
            head: episodesPage.head

            actions: [
                Action {
                    iconName: "edit-clear"
                    text: i18n.tr("Cancel")
                    onTriggered: {
                        episodeList.forceActiveFocus()
                        episodesPage.state = "default"
                        episodeList.positionViewAtBeginning()
                    }
                }
            ]

            contents: Loader {
                id: searchField
                sourceComponent: episodesPage.state === "search" ? searchFieldComponent : undefined
                anchors.left: parent ? parent.left : undefined
                anchors.right: parent ? parent.right : undefined
                anchors.rightMargin: units.gu(2)
            }
        }
    ]

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
                color: podbird.appTheme.negativeActionButton
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
                color: podbird.appTheme.neutralActionButton
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
                color: UbuntuColors.darkGrey
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

    Loader {
        id: emptyState

        anchors {
            left: parent.left
            right: parent.right
            margins: units.gu(2)
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: Qt.inputMethod.visible ? units.gu(4) : 0
        }

        sourceComponent: (episodesPage.state === "search" && sortedEpisodeModel.count === 0) || (episodeModel.count === 0 && podbird.settings.hideListened) ? emptyStateComponent
                                                                                                                                                            : undefined
    }

    Component {
        id: emptyStateComponent
        EmptyState {
            iconHeight: units.gu(12)
            iconWidth: units.gu(22)
            iconSource: Qt.resolvedUrl("../graphics/notFound.svg")
            title: podbird.settings.hideListened ? i18n.tr("No more episodes") : i18n.tr("No episodes found")
            subTitle: podbird.settings.hideListened ? i18n.tr("All episodes have been listened to.") : i18n.tr("No episodes found matching the search term.")
        }
    }

    ListModel {
        id: episodeModel
    }

    SortFilterModel {
        id: sortedEpisodeModel
        model: episodeModel
        filter.property: "name"
        filter.pattern: episodesPage.state === "search" && searchField.status == Loader.Ready ? RegExp(searchField.item.text, "gi")
                                                                                              : RegExp("", "gi")
    }

    UbuntuListView {
        id: episodeList

        Component.onCompleted: {
            // FIXME: workaround for qtubuntu not returning values depending on the grid unit definition
            // for Flickable.maximumFlickVelocity and Flickable.flickDeceleration
            var scaleFactor = units.gridUnit / 8;
            maximumFlickVelocity = maximumFlickVelocity * scaleFactor;
            flickDeceleration = flickDeceleration * scaleFactor;
        }

        anchors.fill: parent
        model: sortedEpisodeModel

        clip: true        

        header: Column {
            height: blurredBackground.height + modeTabs.height + units.gu(2)
            spacing: units.gu(2)
            BlurredBackground {
                id: blurredBackground

                art: episodeImage
                width: parent.width
                visible: episodesPage.state !== "search" && sortedEpisodeModel.count !== 0
                height: episodesPage.state !== "search" && sortedEpisodeModel.count !== 0 ? cover.height + units.gu(4) : 0
                backgroundStrength: podbird.settings.themeName === "Light.qml" ? 0.3 : 0.6

                Image {
                    id:cover
                    width: units.gu(12)
                    height: width
                    sourceSize.height: width
                    sourceSize.width: width
                    source: episodeImage
                    asynchronous: true
                    anchors {
                        left: parent.left
                        top: parent.top
                        margins: units.gu(2)
                    }
                }

                Column {
                    id: podcastTitle

                    anchors {
                        left: cover.right
                        right: parent.right
                        bottom: parent.bottom
                        margins: units.gu(2)
                    }

                    Label {
                        text: episodeName
                        width: parent.width
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        color: podbird.appTheme.baseText
                    }

                    Label {
                        text: i18n.tr("%1 episode", "%1 episodes", episodeList.count).arg(episodeList.count)
                        width: parent.width
                        elide: Text.ElideRight
                        fontSize: "x-small"
                        color: podbird.appTheme.baseText
                    }
                }
            }

            Item {
                id: modeTabs
                height: unheardTab.implicitHeight + units.gu(2)
                width: episodesPage.width

                Label {
                    id: unheardTab
                    fontSize: "large"
                    text: i18n.tr("Unheard")
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(2)
                    color: episodesPage.mode == "unheard" ? podbird.appTheme.focusText : podbird.appTheme.baseText

                    AbstractButton {
                        anchors.fill: parent
                        onClicked: episodesPage.mode = "unheard"
                    }
                }

                Rectangle {
                    anchors.top: unheardTab.bottom
                    anchors.topMargin: units.gu(1)
                    anchors.horizontalCenter: unheardTab.horizontalCenter
                    height: units.gu(0.25)
                    width: unheardTab.width
                    radius: width/3
                    color: podbird.appTheme.focusText
                    visible: episodesPage.mode == "unheard"
                }

                Label {
                    id: listenedTab
                    anchors.left: unheardTab.right
                    anchors.leftMargin: (parent.width - unheardTab.width - listenedTab.width - downloadedTab.width - unheardTab.anchors.leftMargin - downloadedTab.anchors.rightMargin) / 2.0
                    fontSize: "large"
                    text: i18n.tr("Listened")
                    color: episodesPage.mode == "listened" ? podbird.appTheme.focusText : podbird.appTheme.baseText

                    AbstractButton {
                        anchors.fill: parent
                        onClicked: episodesPage.mode = "listened"
                    }
                }

                Rectangle {
                    anchors.top: listenedTab.bottom
                    anchors.topMargin: units.gu(1)
                    anchors.horizontalCenter: listenedTab.horizontalCenter
                    height: units.gu(0.25)
                    width: listenedTab.width
                    radius: width/3
                    color: podbird.appTheme.focusText
                    visible: episodesPage.mode == "listened"
                }

                Label {
                    id: downloadedTab
                    anchors.right: parent.right
                    anchors.rightMargin: units.gu(2)
                    fontSize: "large"
                    text: i18n.tr("Downloaded")
                    color: episodesPage.mode == "downloaded" ? podbird.appTheme.focusText : podbird.appTheme.baseText

                    AbstractButton {
                        anchors.fill: parent
                        onClicked: episodesPage.mode = "downloaded"
                    }
                }

                Rectangle {
                    anchors.top: downloadedTab.bottom
                    anchors.topMargin: units.gu(1)
                    anchors.horizontalCenter: downloadedTab.horizontalCenter
                    height: units.gu(0.25)
                    width: downloadedTab.width
                    radius: width/3
                    color: podbird.appTheme.focusText
                    visible: episodesPage.mode == "downloaded"
                }
            }

        }

        footer: Item {
            width: parent.width
            height: units.gu(8)
        }

        delegate: ListDelegate {
            id: listItem

            title: model.name !== undefined ? model.name.trim() : "Undefined"
            titleColor: listItem.expanded || currentGuid === model.guid || downloader.downloadingGuid === model.guid ? podbird.appTheme.focusText
                                                                                                                     : podbird.appTheme.baseText

            subtitle: model.duration === 0 || model.duration === undefined ? Qt.formatDate(new Date(model.published), "MMM d, yyyy") : Podcasts.formatEpisodeTime(model.duration) + " | " + Qt.formatDate(new Date(model.published), "MMM d, yyyy")

            isDownloaded: model.downloadedfile ? true : false
            showProgressBar: downloader.downloadingGuid === model.guid
            isInDeterminateDownload: downloader.progress < 0 || downloader.progress > 100 && downloader.downloadingGuid === model.guid
            progress: downloader.progress
            visible: episodesPage.mode == "listened" ? model.listened
                                                     : (episodesPage.mode == "unheard" ? !model.listened
                                                                                       : isDownloaded)
            height: visible ? undefined : 0

            trailingActions: ListItemActions {
                actions: [
                    Action {
                        iconName: model.listened ? "view-collapse" : "select"
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
                                downloader.addDownload(model.guid, model.audiourl);
                            }
                        }
                    },

                    Action {
                        iconName: "info"
                        onTriggered: {
                            var popup = PopupUtils.open(episodeDescriptionDialog, episodesPage);
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

        PullToRefresh {
            refreshing: episodesUpdating
            onRefresh: updateEpisodesDatabase();
        }

        // #FIXME: Use SDK Scrollbar when it is themeable
        CustomScrollBar {
            listview: episodeList
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
            var rs = tx.executeSql("SELECT rowid, * FROM Episode WHERE podcast=? ORDER BY published DESC", [pid]);
            for(i = 0; i < rs.rows.length; i++) {
                episode = rs.rows.item(i);
                if (!episode.listened) {
                    episodeModel.insert(newCount, {"guid" : episode.guid, "listened" : episode.listened, "published": episode.published, "name" : episode.name, "description" : episode.description, "duration" : episode.duration, "position" : episode.position, "downloadedfile" : episode.downloadedfile, "image" : img, "artist" : artist, "audiourl" : episode.audiourl, "queued": episode.queued});
                    newCount++;
                } else if (!podbird.settings.hideListened) {
                    episodeModel.insert(i,{"guid" : episode.guid, "listened" : episode.listened, "published": episode.published, "name" : episode.name, "description" : episode.description, "duration" : episode.duration, "position" : episode.position, "downloadedfile" : episode.downloadedfile, "image" : img, "artist" : artist, "audiourl" : episode.audiourl, "queued": episode.queued});
                }
            }
        });
    }

    function updateEpisodesDatabase() {
        episodesUpdating = true;
        Podcasts.updateEpisodes(refreshModel)
    }
}
