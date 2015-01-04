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
import QtQuick.LocalStorage 2.0
import Ubuntu.Components 1.1
import Ubuntu.DownloadManager 0.1
import "../podcasts.js" as Podcasts

Tab {
    id: tab
    title: i18n.tr("Podcasts")
    property bool episodesUpdating: false;

    page: Page {
        tools: ToolbarItems {
            ToolbarButton {
                action: Action {
                    text: i18n.tr("Up")
                    iconName: "up"
                    visible: view.model === episodeModel
                    onTriggered: {
                        page.title = i18n.tr("Podcasts");
                        view.model = podcastModel;
                        refreshModel();
                    }
                }
            }

            ToolbarButton {
                action: Action {
                    text: i18n.tr("Unsubscribe")
                    iconName: "delete"
                    visible: view.model === episodeModel
                    onTriggered: {
                        var db = Podcasts.init();
                        db.transaction(function (tx) {
                            var rs = tx.executeSql("SELECT downloadedfile FROM Episode WHERE downloadedfile NOT NULL AND podcast=?", [episodeModel.pid]);
                            for(var i = 0; i < rs.rows.length; i++) {
                                fileManager.deleteFile(rs.rows.item(i).downloadedfile);
                            }
                            tx.executeSql("DELETE FROM Episode WHERE podcast=?", [episodeModel.pid]);
                            tx.executeSql("DELETE FROM Podcast WHERE rowid=?", [episodeModel.pid]);
                            page.title = i18n.tr("Podcasts");
                            view.model = podcastModel;
                            refreshModel();
                        });
                    }
                }
            }
        }

        onVisibleChanged: {
            if(visible) {
                refreshModel();
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
                    tx.executeSql("UPDATE Episode SET downloadedfile=? WHERE guid=?", [finalLocation, downloadingGuid]);
                    queue.shift();
                    if (queue.length > 0) {
                        downloadingGuid = queue[0][0];
                        download(queue[0][1]);
                    } else {
                        downloadingGuid = "";
                    }

                    loadEpisodes(episodeModel.pid, episodeModel.artist, episodeModel.image);
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

        Label {
            anchors.centerIn: parent
            width: parent.width - units.gu(4)
            horizontalAlignment: Text.AlignHCenter
            text: "<b>" + i18n.tr("No Podcast Subscriptions") + "</b><br /><br />" + i18n.tr("You haven't subscribed to any podcasts yet, visit the 'Search' page to add some.")
            wrapMode: Text.WordWrap
            visible: view.model === podcastModel && podcastModel.count === 0
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
            anchors.fill: parent
            anchors.margins: units.gu(2)
            model: podcastModel
            clip: true
            spacing: units.gu(1)
            footer: Item {
                width: parent.width
                height: units.gu(7)
            }

            delegate: Rectangle {
                id: listItem
                height: expanded ? desc.height + imgFrame.height : imgFrame.height
                width: parent.width
                color: Theme.palette.normal.background
                property bool expanded: false;

                Behavior on height {
                    UbuntuNumberAnimation {
                        duration: UbuntuAnimation.SlowDuration
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (view.model === podcastModel) {
                            page.title = model.name
                            loadEpisodes(model.id, model.artist, model.image)
                            view.model = episodeModel
                        } else {
                            listItem.expanded = !listItem.expanded
                        }
                    }
                }

                UbuntuShape {
                    id: imgFrame
                    width: units.gu(9.1)
                    height: width

                    anchors.left: parent.left
                    image: Image {
                        source: model.image
                    }
                }

                Column {
                    anchors.left: imgFrame.right
                    anchors.leftMargin: units.gu(2)
                    anchors.right: parent.right
                    anchors.rightMargin: units.gu(2)
                    spacing: units.gu(0.5)

                    Row {
                        width: parent.width
                        spacing: units.gu(1)

                        Label {
                            text: model.name
                            width: parent.width - episodeCount.width - units.gu(1)
                            elide: Text.ElideRight
                        }

                        Label {
                            id: episodeCount
                            width: units.gu(4)
                            visible: view.model === episodeModel || model.episodeCount > 0
                            text: view.model === episodeModel ? (!isNaN(model.duration) && model.duration !== 0 ? Podcasts.formatTime(model.duration) : "") : model.episodeCount
                            horizontalAlignment: Text.AlignRight
                            fontSize: "small"
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: units.gu(1)

                        Label {
                            id: desc
                            text: view.model === episodeModel ? model.description : model.artist
                            maximumLineCount: listItem.expanded ? undefined : 1
                            wrapMode: Text.WordWrap
                            width: parent.width - listened.width - units.gu(1)
                            elide: Text.ElideRight
                            fontSize: "small"
                        }

                        Rectangle {
                            id: listened
                            border.color: UbuntuColors.lightGrey
                            height: units.gu(2)
                            width: height
                            radius: width / 2
                            visible: view.model === episodeModel && model.listened
                            Icon {
                                id: tick
                                name: "tick"
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: units.gu(0.1)
                                height: units.gu(1.4)
                                width: height
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: units.gu(2)
                        Icon {
                            name: player.playbackState === MediaPlayer.PlayingState && currentGuid === model.guid ? "media-playback-pause"
                                                                                                                  : "media-playback-start"
                            visible: view.model === episodeModel
                            width: units.gu(4)
                            height: width
                            MouseArea {
                                anchors.fill: parent

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

                        Item {
                            width: units.gu(4)
                            height: width

                            ActivityIndicator {
                                anchors.centerIn: parent
                                visible: downloader.downloadingGuid === model.guid
                                running: visible
                            }

                            Icon {
                                anchors.fill: parent
                                property bool queued: false;
                                name: model.downloadedfile ? "delete" : (queued && downloader.downloadingGuid !== model.guid ? "history" : "save")
                                width: units.gu(4)
                                height: width
                                visible: view.model === episodeModel
                                opacity: downloader.downloadingGuid === model.guid ? 0.4 : 1.0

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: downloader.downloadingGuid !== model.guid

                                    onClicked: {
                                        if (model.downloadedfile) {
                                            fileManager.deleteFile(model.downloadedfile);
                                            var db = Podcasts.init();
                                            db.transaction(function (tx) {
                                                tx.executeSql("UPDATE Episode SET downloadedfile = NULL WHERE guid = ?", [model.guid]);
                                            });
                                            loadEpisodes(episodeModel.pid, episodeModel.artist, episodeModel.image);
                                        } else {
                                            parent.queued = true;
                                            downloader.addDownload(model.guid, model.audiourl);
                                        }
                                    }
                                }
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
    }

    function refreshModel() {
        var db = Podcasts.init();

        if (view.model === podcastModel) {
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
        } else {
            loadEpisodes(episodeModel.pid, episodeModel.artist, episodeModel.image);
        }

        episodesUpdating = false;
    }

    function loadEpisodes(pid, artist, img) {
        var db = Podcasts.init();
        db.transaction(function (tx) {
            episodeModel.clear();
            var rs = tx.executeSql("SELECT rowid, * FROM Episode WHERE podcast=? ORDER BY published DESC", [pid]);
            for(var i = 0; i < rs.rows.length; i++) {
                var episode = rs.rows.item(i);
                episodeModel.pid = pid;
                episodeModel.artist = artist;
                episodeModel.image = img;
                episodeModel.append({"guid" : episode.guid, "listened" : episode.listened, "name" : episode.name, "description" : episode.description, "duration" : episode.duration, "position" : episode.position, "downloadedfile" : episode.downloadedfile, "image" : img, "artist" : artist, "audiourl" : episode.audiourl});
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

