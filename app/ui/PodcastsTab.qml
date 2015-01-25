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
import QtQuick.Layouts 1.1
import QtQuick.LocalStorage 2.0
import Ubuntu.Components 1.1
import Ubuntu.DownloadManager 0.1
import Ubuntu.Components.ListItems 1.0 as ListItem
import Ubuntu.Components.Popups 1.0
import "../podcasts.js" as Podcasts

Tab {
    id: tab

    title: i18n.tr("Podcasts")

    property bool episodesUpdating: false;
    property bool addPodcast: false;

    page: Page {
        head.actions: [
            Action {
                text: i18n.tr("Add Podcast")
                iconName: "add"
                visible: !addPodcast
                onTriggered: {
                    addPodcast = true;
                }
            }
        ]

        onVisibleChanged: {
            if(visible) {
                refreshModel();
            }
        }

        Component {
            id: subscribeFailedDialog
            Dialog {
                id: dialogInternal
                title: i18n.tr("Unable to subscribe")
                text: i18n.tr("Please check the URL and try again")
                Button {
                    text: i18n.tr("Close")
                    onClicked: PopupUtils.close(dialogInternal)
                }
            }
        }

        EmptyState {
            anchors.centerIn: parent
            visible: view.model === podcastModel && podcastModel.count === 0
            iconName: "music-app-symbolic"
            title: i18n.tr("No Podcast Subscriptions")
            subTitle: i18n.tr("You haven't subscribed to any podcasts yet, visit the 'Search' page to add some.")
        }

        ListModel {
            id: podcastModel
        }

        ListModel {
            id: episodeModel
            property string pid;
            property string artist;
            property string image;
        }

        ListView {
            id: view

            clip: true
            model: podcastModel
            anchors.fill: parent

            footer: Item {
                width: parent.width
                height: units.gu(8)
            }

            delegate: ListItem.Empty {
                id: listItem

                property bool expanded: false

                height: units.gu(8)
                removable: true
                confirmRemoval: true
                onItemRemoved: {
                    var db = Podcasts.init();
                    db.transaction(function (tx) {
                        var rs = tx.executeSql("SELECT downloadedfile FROM Episode WHERE downloadedfile NOT NULL AND podcast=?", [model.id]);
                        for(var i = 0; i < rs.rows.length; i++) {
                            fileManager.deleteFile(rs.rows.item(i).downloadedfile);
                        }
                        tx.executeSql("DELETE FROM Episode WHERE podcast=?", [model.id]);
                        tx.executeSql("DELETE FROM Podcast WHERE rowid=?", [model.id]);
                        refreshModel()
                    });
                }

                onClicked: {
                    mainStack.push(Qt.resolvedUrl("EpisodesPage.qml"), {"episodeName": model.name, "episodeId": model.id, "episodeArtist": model.artist, "episodeImage": model.image})
                }

                Column {
                    id: mainColumn

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: units.gu(2)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: units.gu(1)

                    RowLayout {
                        id: titleRow

                        width: parent.width
                        spacing: units.gu(2)

                        Image {
                            id: imgFrame
                            width: units.gu(5)
                            height: width
                            sourceSize.height: width
                            sourceSize.width: width
                            source: model.image
                        }

                        Column {
                            id: detailColumn

                            anchors.verticalCenter: imgFrame.verticalCenter
                            Layout.fillWidth: true

                            Label {
                                id: podcastTitle
                                textFormat: Text.PlainText
                                text: model.name.trim()
                                width: parent.width
                                fontSize: "small"
                                elide: Text.ElideRight
                            }

                            Label {
                                id: episodeCount
                                width: parent.width
                                color: "#999999"
                                visible: model.episodeCount > 0
                                text: model.episodeCount + " Episodes"
                                fontSize: "x-small"
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

        Rectangle {
            anchors.top: parent.top
            anchors.topMargin: header.y + header.height
            width: parent.width
            height: addCol.height
            opacity: addPodcast ? 1 : 0
            color: Theme.palette.normal.background

            onOpacityChanged: {
                visible = opacity != 0;
            }

            onVisibleChanged: {
                if (visible) {
                    addText.forceActiveFocus()
                }
            }

            Behavior on opacity {
                UbuntuNumberAnimation {
                    duration: UbuntuAnimation.SlowDuration
                }
            }

            Column {
                id: addCol
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: units.gu(2)
                width: parent.width - units.gu(4)
                anchors.margins: units.gu(2)

                Item {
                    width: parent.width
                    height: units.gu(2)
                }

                TextField {
                    id: addText
                    width: parent.width
                    inputMethodHints: Qt.ImhUrlCharactersOnly
                    placeholderText: i18n.tr("Feed URL...")
                    onAccepted: {
                        subscribeFromFeed(addText.text);
                        addPodcast = false;
                        addText.text = "";
                    }
                }

                Row {
                    spacing: units.gu(2)
                    width: parent.width

                    Button {
                        width: (parent.width - parent.spacing) / 2
                        text: i18n.tr("Cancel")
                        onClicked: {
                            addText.text = "";
                            addPodcast = false;
                        }
                    }

                    Button {
                        width: (parent.width - parent.spacing) / 2
                        color: UbuntuColors.orange
                        text: i18n.tr("Add")
                        onClicked: {
                            subscribeFromFeed(addText.text);
                            addPodcast = false;
                            addText.text = "";
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: units.gu(2)
                }
            }
        }
    }

    function refreshModel() {
        var db = Podcasts.init();

        db.transaction(function (tx) {
            podcastModel.clear();
            var rs = tx.executeSql("SELECT rowid, * FROM Podcast ORDER BY name ASC");
            for(var i = 0; i < rs.rows.length; i++) {
                var podcast = rs.rows.item(i);
                var rs2 = tx.executeSql("SELECT Count(*) AS epcount FROM Episode WHERE podcast=? AND NOT listened", [rs.rows.item(i).rowid]);
                podcastModel.append({"id" : podcast.rowid, "name" : podcast.name, "artist" : podcast.artist, "image" : podcast.image, "episodeCount" : rs2.rows.item(0).epcount});
                if (podcast.lastupdate === null && !episodesUpdating) {
                    updateEpisodes();
                }
            }
        });

        episodesUpdating = false;
    }

    function subscribeFromFeed(feed) {
        var xhr = new XMLHttpRequest;
        if (feed.indexOf("://") === -1) {
            feed = "http://" + feed;
        }
        xhr.open("GET", feed);
        xhr.onreadystatechange = function() {
            var name = "";
            var artist = "";
            var image = "";
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status < 200 || xhr.status > 299 || xhr.responseXML === null) {
                    PopupUtils.open(subscribeFailedDialog);
                    addText.text = feed;
                    addPodcast = true;
                    return;
                }

                var e = xhr.responseXML.documentElement;
                for(var h = 0; h < e.childNodes.length; h++) {
                    if(e.childNodes[h].nodeName === "channel") {
                        var c = e.childNodes[h];
                        for(var j = 0; j < c.childNodes.length; j++) {
                            var nodeName = c.childNodes[j].nodeName;
                            if (nodeName === "title")               name = c.childNodes[j].childNodes[0].nodeValue;
                            else if (nodeName === "author")         artist = c.childNodes[j].childNodes[0].nodeValue;
                            else if (nodeName === "image") {
                                var el = c.childNodes[j];
                                for (var l = 0; l < el.attributes.length; l++) {
                                    if(el.attributes[l].nodeName === "href")         image = el.attributes[l].nodeValue;
                                }
                            }
                        }
                    }
                }

                if(name != "") {
                    Podcasts.subscribe(artist, name, feed, image);
                    imageDownloader.feed = feed;
                    imageDownloader.download(image);
                    updateEpisodes();
                } else {
                    PopupUtils.open(subscribeFailedDialog);
                    addText.text = feed;
                    addPodcast = true;
                    return;
                }
            }
        }
        xhr.send();
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

