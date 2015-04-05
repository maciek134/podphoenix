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

import QtQuick 2.3
import QtMultimedia 5.0
import Ubuntu.Components 1.1
import QtQuick.Layouts 1.1
import QtQuick.LocalStorage 2.0
import Ubuntu.DownloadManager 0.1
import Ubuntu.Components.Popups 1.0
import Ubuntu.Components.ListItems 1.0 as ListItem
import "../podcasts.js" as Podcasts

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

    property bool episodesUpdating: false;

    Component.onCompleted: {
        loadEpisodes(episodeId, episodeArtist, episodeImage)
        if (downloader.downloadingGuid != "")
            tempGuid = downloader.downloadingGuid
    }

    /*
     #FIXME: The following lines of code is necessary due to a upstream bug
     in the SDK http://pad.lv/1400297. This bug is still present in the rtm.
     Once it is fixed, this following property and connection can be remvoed.
    */
    property Item __oldContents: null
    Connections {
        target: episodesPage.head
        onContentsChanged: {
            if (episodesPage.__oldContents) {
                episodesPage.__oldContents.parent = null;
            }
            episodesPage.__oldContents = episodesPage.head.contents;
        }
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
                        searchField.forceActiveFocus()
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
            backAction: Action {
                iconName: "back"
                text: i18n.tr("Back")
                onTriggered: {
                    episodeList.forceActiveFocus()
                    searchField.text = ""
                    episodesPage.state = "default"
                    episodeList.positionViewAtBeginning()
                }
            }

            contents: TextField {
                id: searchField
                inputMethodHints: Qt.ImhNoPredictiveText
                placeholderText: i18n.tr("Search episode")
                anchors.left: parent ? parent.left : undefined
                anchors.right: parent ? parent.right : undefined
                anchors.rightMargin: units.gu(2)
            }
        }
    ]

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
                color: podbird.theme.negativeActionButton
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
                color: podbird.theme.neutralActionButton
                onClicked: {
                    PopupUtils.close(dialogInternal)
                }
            }
        }
    }

    Component {
        id: popoverComponent

        Popover {
            id: popover

            property bool queued: false
            property bool listened: false
            property string downloadedfile: ""
            property string guid: ""
            property string audiourl: ""
            property int index: -1

            Column {
                width: parent.width
                anchors.top: parent.top

                ListItem.Standard {
                    id: download
                    iconFrame: false
                    iconName: popover.downloadedfile ? "delete" : (popover.queued && downloader.downloadingGuid !== popover.guid ? "history" : "save")
                    text: popover.downloadedfile ? i18n.tr("Delete local file")
                                                 : (popover.queued && downloader.downloadingGuid !== popover.guid ? i18n.tr("Episode queued for download")
                                                                                                                  : i18n.tr("Download episode"))
                    enabled: downloader.downloadingGuid !== popover.guid
                    onClicked: {
                        if (popover.downloadedfile) {
                            fileManager.deleteFile(popover.downloadedfile);
                            var db = Podcasts.init();
                            db.transaction(function (tx) {
                                tx.executeSql("UPDATE Episode SET downloadedfile = NULL WHERE guid = ?", [popover.guid]);
                            });
                            episodeModel.setProperty(popover.index, "downloadedfile", "")
                            episodeModel.setProperty(popover.index, "queued", false)
                        } else {
                            episodeModel.setProperty(popover.index, "queued", true)
                            downloader.addDownload(popover.guid, popover.audiourl);
                        }
                        PopupUtils.close(popover)
                    }
                }

                ListItem.Standard {
                    id: listen
                    iconFrame: false
                    iconName: popover.listened ? "view-collapse" : "select"
                    text: popover.listened ? "Mark episode unlistened" : "Mark episode listened"
                    onClicked: {
                        var db = Podcasts.init();
                        db.transaction(function (tx) {
                            if (popover.listened)
                                tx.executeSql("UPDATE Episode SET listened=0 WHERE guid=?", [popover.guid])
                            else
                                tx.executeSql("UPDATE Episode SET listened=1 WHERE guid=?", [popover.guid])
                            refreshModel();
                        });
                        PopupUtils.close(popover)
                    }
                }
            }
        }
    }

    EmptyState {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: Qt.inputMethod.visible ? units.gu(4) : 0
        visible: (episodesPage.state === "search" && sortedEpisodeModel.count === 0) || (episodeModel.count === 0 && podbird.settings.hideListened)
        iconName: "music-app-symbolic"
        title: podbird.settings.hideListened ? i18n.tr("No more episodes") : i18n.tr("No Episodes found")
        subTitle: podbird.settings.hideListened ? i18n.tr("All episodes have been listened to.") : i18n.tr("No episodes found matching the search term.")
    }

    ListModel {
        id: episodeModel
    }

    SortFilterModel {
        id: sortedEpisodeModel
        model: episodeModel
        filter.property: "name"
        filter.pattern: RegExp(searchField.text, "gi")
    }

    function formatTime(seconds) {
        var time = Podcasts.getTimeDiff(seconds)
        var hour = time[0]
        var minute = time[1]
        // TRANSLATORS: the first argument is the number of hours,
        // followed by minute (eg. 20h 3m)
        if(hour > 0 &&  minute > 0) {
            // xgettext: no-c-format
            return (i18n.tr("%1 hr %2 min"))
            .arg(hour)
            .arg(minute)
        }

        // TRANSLATORS: this string indicates the number of hours
        // eg. 20h (no plural state required)
        else if(hour > 0 && minute === 0) {
            // xgettext: no-c-format
            return (i18n.tr("%1 hr"))
            .arg(hour)
        }

        // TRANSLATORS: this string indicates the number of minutes
        // eg. 15m (no plural state required)
        else if(hour === 0 && minute > 0) {
            // xgettext: no-c-format
            return (i18n.tr("%1 min"))
            .arg(minute)
        }

        else {
            return Podcasts.formatTime(model.duration)
        }
    }

    UbuntuListView {
        id: episodeList

        anchors.fill: parent
        model: sortedEpisodeModel

        clip: true
        section.property: "listened"
        section.labelPositioning: ViewSection.InlineLabels

        section.delegate: Rectangle {
            width: parent.width
            color: section === "0" ? podbird.theme.hightlightListView : "Transparent"
            height: header.implicitHeight + units.gu(2)
            Label {
                id: header
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: units.gu(2)
                    verticalCenter: parent.verticalCenter
                }
                fontSize: "x-large"
                text: section === "0" ? "New" : "Listened"
            }
        }

        header: BlurredBackground {
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
                    color: podbird.theme.baseText
                }

                Label {
                    text: i18n.tr("%1 episode", "%1 episodes", episodeList.count).arg(episodeList.count)
                    width: parent.width
                    elide: Text.ElideRight
                    fontSize: "x-small"
                    color: podbird.theme.baseText
                }
            }
        }

        footer: Item {
            width: parent.width
            height: units.gu(8)
        }

        delegate: ListItem.Empty {
            id: listItem

            property bool expanded

            height: dataColumn.height + units.gu(2)
            highlightWhenPressed: false
            showDivider: false

            onClicked: {
                expanded = !expanded;
            }

            Rectangle {
                visible: !model.listened
                width: parent.width
                height: dataColumn.height + units.gu(2)
                color: podbird.theme.hightlightListView
            }

            Column {
                id: dataColumn

                spacing: units.gu(1)
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: units.gu(2)
                anchors.top: parent.top
                anchors.topMargin: units.gu(0.5)

                RowLayout {
                    id: rowlayout

                    width: parent.width
                    height: titleColumn.height

                    Column {
                        id: titleColumn
                        Layout.fillWidth: true

                        Label {
                            text: model.name.trim()
                            width: parent.width
                            maximumLineCount: 2
                            wrapMode: Text.WordWrap
                            elide: Text.ElideRight
                            color: listItem.expanded || currentGuid === model.guid || downloader.downloadingGuid === model.guid ? podbird.theme.focusText
                                                                                                                                : podbird.theme.baseText
                        }

                        Label {
                            id: episodePublishDate
                            width: parent.width
                            text: formatTime(model.duration) + " | " + Qt.formatDate(new Date(model.published), "MMM d, yyyy")
                            fontSize: "x-small"
                            elide: Text.ElideRight
                            color: podbird.theme.baseSubText
                        }
                    }

                    ActionButton {
                        id: contextualMenu

                        width: units.gu(5)
                        height: units.gu(4)

                        iconName: "contextual-menu"
                        color: progressBar.visible || listItem.expanded ? podbird.theme.focusText
                                                                        : podbird.theme.baseIcon
                        onClicked: {
                            var popover = PopupUtils.open(popoverComponent, contextualMenu)
                            popover.queued = Qt.binding(function() { return model.queued })
                            popover.listened = Qt.binding(function() { return model.listened })
                            popover.guid = Qt.binding(function() { return model.guid })
                            popover.audiourl = Qt.binding(function() { return model.audiourl })
                            popover.downloadedfile = Qt.binding(function() { return episodeModel.get(index).downloadedfile })
                            popover.index = Qt.binding(function() { return index })
                        }
                    }

                    ActionButton {
                        width: units.gu(4)
                        height: units.gu(4)

                        iconName: player.playbackState === MediaPlayer.PlayingState && currentGuid === model.guid ? "media-playback-pause"
                                                                                                                  : "media-playback-start"
                        color: player.playbackState === MediaPlayer.PlayingState && currentGuid === model.guid ? podbird.theme.focusText
                                                                                                               : podbird.theme.baseIcon

                        onClicked: {
                            var db = Podcasts.init();
                            db.transaction(function (tx) {
                                if (currentGuid === model.guid) {
                                    if (player.playbackState === MediaPlayer.PlayingState) {
                                        player.pause()
                                    } else {
                                        player.play()
                                    }
                                } else {
                                    currentGuid = "";
                                    player.source = model.downloadedfile ? model.downloadedfile : model.audiourl;
                                    var rs = tx.executeSql("SELECT position FROM Episode WHERE guid=?", [model.guid]);
                                    player.play();
                                    player.seek(rs.rows.item(0).position);
                                    currentName = model.name;
                                    currentArtist = model.artist;
                                    currentImage = model.image;
                                    currentGuid = model.guid;
                                }
                            });
                        }
                    }
                }

                Rectangle {
                    id: progressBar
                    radius: width/3
                    width: parent.width
                    height: units.dp(5)
                    color: Theme.palette.normal.base
                    visible: downloader.downloadingGuid === model.guid
                    Rectangle {
                        height: parent.height
                        radius: parent.radius
                        anchors.left: parent.left
                        anchors.top: parent.top
                        color: podbird.theme.focusText
                        width: downloader.progress > 0 ? Math.min((downloader.progress / 100) * parent.width, parent.width) : 0
                    }
                }

                Label {
                    id: desc
                    text: model.description
                    textFormat: Text.RichText
                    clip: true
                    height: listItem.expanded ? contentHeight : 0
                    wrapMode: Text.WordWrap
                    width: parent.width
                    fontSize: "small"
                    color: podbird.theme.baseSubText
                    Behavior on height {
                        UbuntuNumberAnimation {
                            duration: UbuntuAnimation.BriskDuration
                        }
                    }
                }
            }
        }

        PullToRefresh {
            refreshing: episodesUpdating
            onRefresh: updateEpisodes();
        }
    }

    Scrollbar {
        flickableItem: episodeList
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
                    episodeModel.insert(newCount, {"guid" : episode.guid, "listened" : episode.listened, "published": episode.published, "name" : episode.name, "description" : episode.description, "duration" : episode.duration, "position" : episode.position, "downloadedfile" : episode.downloadedfile, "image" : img, "artist" : artist, "audiourl" : episode.audiourl, "queued": false});
                    newCount++;
                } else if (!podbird.settings.hideListened) {
                    episodeModel.insert(i,{"guid" : episode.guid, "listened" : episode.listened, "published": episode.published, "name" : episode.name, "description" : episode.description, "duration" : episode.duration, "position" : episode.position, "downloadedfile" : episode.downloadedfile, "image" : img, "artist" : artist, "audiourl" : episode.audiourl, "queued": false});
                }
            }
        });
    }

    function updateEpisodes() {
        var db = Podcasts.init();
        episodesUpdating = true;
        db.transaction(function(tx) {
            var rs = tx.executeSql("SELECT rowid, feed FROM Podcast");
            tx.executeSql("UPDATE Podcast SET lastupdate=CURRENT_TIMESTAMP");
            var xhr = [];
            for(var i = 0; i < rs.rows.length; i++) {
                (function (i) {
                    xhr[i] = new XMLHttpRequest;
                    var url = rs.rows.item(i).feed;
                    var pid = rs.rows.item(i).rowid;
                    xhr[i].open("GET", url);
                    xhr[i].onreadystatechange = function() {
                        if (xhr[i].readyState === XMLHttpRequest.DONE) {
                            var e = xhr[i].responseXML.documentElement;
                            for(var h = 0; h < e.childNodes.length; h++) {
                                if(e.childNodes[h].nodeName === "channel") {
                                    var c = e.childNodes[h];
                                    for(var j = 0; j < c.childNodes.length; j++) {
                                        if(c.childNodes[j].nodeName === "item") {
                                            var t = c.childNodes[j];
                                            var track = {}
                                            for(var k = 0; k < t.childNodes.length; k++) {
                                                try {
                                                    var nodeName = t.childNodes[k].nodeName.toLowerCase();
                                                    if (nodeName === "title")               track['name'] = t.childNodes[k].childNodes[0].nodeValue;
                                                    else if (nodeName === "description")    track['description'] = t.childNodes[k].childNodes[0].nodeValue;
                                                    else if (nodeName === "guid")           track['guid'] = t.childNodes[k].childNodes[0].nodeValue;
                                                    else if (nodeName === "pubdate")        track['published'] = new Date(t.childNodes[k].childNodes[0].nodeValue).getTime();
                                                    else if (nodeName === "duration") {
                                                        var dur = t.childNodes[k].childNodes[0].nodeValue.split(":");
                                                        if (dur.length === 1) {
                                                            track['duration'] = parseInt(dur[0]);
                                                        } else if (dur.length === 2) {
                                                            track['duration'] = parseInt(dur[0]) * 60 + parseInt(dur[1]);
                                                        } else if (dur.length === 3) {
                                                            track['duration'] = parseInt(dur[0]) * 3600 + parseInt(dur[1]) * 60 + parseInt(dur[2]);
                                                        }
                                                    } else if (nodeName === "enclosure") {
                                                        var el = t.childNodes[k];
                                                        for (var l = 0; l < el.attributes.length; l++) {
                                                            if(el.attributes[l].nodeName === "url")         track['audiourl'] = el.attributes[l].nodeValue;
                                                        }
                                                    }
                                                } catch(err) {
                                                    console.debug(err.message);
                                                }
                                            }
                                            if (!track.hasOwnProperty("guid")) {
                                                track['guid'] = track.audiourl;
                                            }

                                            db.transaction(function(tx2) {
                                                var ers = tx2.executeSql("SELECT rowid FROM Episode WHERE guid=?", [track.guid]);
                                                if (ers.rows.length === 0) {
                                                    tx2.executeSql("INSERT INTO Episode(podcast, name, description, audiourl, guid, listened, duration, published) VALUES(?, ?, ? , ?, ?, ?, ?, ?)", [pid,
                                                                                                                                                                                                      track.name,
                                                                                                                                                                                                      track.description,
                                                                                                                                                                                                      track.audiourl,
                                                                                                                                                                                                      track.guid,
                                                                                                                                                                                                      false,
                                                                                                                                                                                                      track.duration,
                                                                                                                                                                                                      track.published]);
                                                }
                                            });
                                        }
                                    }
                                }
                            }
                        }
                        refreshModel();
                    }
                    xhr[i].send();

                })(i);
            }
        });
    }
}
