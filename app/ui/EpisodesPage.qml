import QtQuick 2.0
import QtMultimedia 5.0
import Ubuntu.Components 1.1
import QtQuick.Layouts 1.1
import QtQuick.LocalStorage 2.0
import Ubuntu.DownloadManager 0.1
import Ubuntu.Components.ListItems 1.0 as ListItem
import "../podcasts.js" as Podcasts

Page {
    id: episodesPage

    visible: false
    title: episodeName

    property string episodeName
    property string episodeId
    property string episodeArtist
    property string episodeImage

    property bool episodesUpdating: false;

    Component.onCompleted: {
        loadEpisodes(episodeId, episodeArtist, episodeImage)
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

    head.actions: [
        Action {
            text: i18n.tr("Unsubscribe")
            iconName: "delete"
            onTriggered: {
                var db = Podcasts.init();
                db.transaction(function (tx) {
                    var rs = tx.executeSql("SELECT downloadedfile FROM Episode WHERE downloadedfile NOT NULL AND podcast=?", [episodeModel.pid]);
                    for(var i = 0; i < rs.rows.length; i++) {
                        fileManager.deleteFile(rs.rows.item(i).downloadedfile);
                    }
                    tx.executeSql("DELETE FROM Episode WHERE podcast=?", [episodeModel.pid]);
                    tx.executeSql("DELETE FROM Podcast WHERE rowid=?", [episodeModel.pid]);
                    mainStack.pop()
                });
            }
        }
    ]

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

    ListModel {
        id: episodeModel
        property string pid;
        property string artist;
        property string image;
    }

    ListView {
        id: episodeList

        clip: true
        anchors.fill: parent
        model: episodeModel

        footer: Item {
            width: parent.width
            height: units.gu(8)
        }

        delegate: ListItem.Empty {
            id: listItem

            property bool expanded: false

            width: parent.width
            height: mainColumn.height

            onClicked: listItem.expanded = !listItem.expanded

            Column {
                id: mainColumn

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: units.gu(2)
                    topMargin: units.gu(1)
                }

                spacing: units.gu(1)

                RowLayout {
                    id: titleRow

                    width: parent.width
                    spacing: units.gu(2)

                    Image {
                        id: imgFrame
                        width: units.gu(6)
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
                            textFormat: Text.PlainText
                            text: model.name.trim()
                            width: parent.width
                            elide: Text.ElideRight
                        }

                        Label {
                            id: episodeCount
                            width: parent.width
                            text: model.artist
                            fontSize: "small"
                        }
                    }
                }

                Label {
                    id: desc
                    text: model.description
                    textFormat: Text.RichText
                    clip: true
                    height: listItem.expanded ? contentHeight : units.gu(4)
                    wrapMode: Text.WordWrap
                    width: parent.width
                    elide: Text.ElideRight
                    fontSize: "small"
                    color: "#999999"
                    Behavior on height {
                        UbuntuNumberAnimation {
                            duration: UbuntuAnimation.SlowDuration
                        }
                    }

                }

                Item {
                    id: statusBox

                    width: parent.width
                    height: units.gu(6)

                    function formatTime(seconds) {
                        var time = Podcasts.getTimeDiff(seconds)
                        var hour = time[0]
                        var minute = time[1]
                        if(hour > 0 &&  minute > 0) {
                            return (i18n.tr("%1h %2m"))
                            .arg(hour)
                            .arg(minute)
                        }

                        else if(hour > 0 && minute === 0) {
                            return (i18n.tr("%1h"))
                            .arg(hour)
                        }

                        else if(hour === 0 && minute > 0) {
                            return (i18n.tr("%1m"))
                            .arg(minute)
                        }

                        else {
                            return Podcasts.formatTime(model.duration)
                        }
                    }

                    Rectangle {
                        id: listened
                        border.color: UbuntuColors.lightGrey
                        height: units.gu(2.5)
                        width: height
                        radius: width / 2
                        anchors.right: durationIcon.left
                        anchors.rightMargin: units.gu(2)
                        visible: model.listened
                        Icon {
                            id: tick
                            name: "tick"
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: units.gu(0.1)
                            height: units.gu(1.4)
                            width: height
                        }
                    }

                    Icon {
                        id: durationIcon
                        width: units.gu(2.5)
                        height: width
                        name: "alarm-clock"
                        visible: duration.text !== ""
                        anchors.right: duration.left
                        anchors.rightMargin: units.gu(0.5)
                    }

                    Label {
                        id: duration
                        anchors.right: parent.right
                        anchors.verticalCenter: durationIcon.verticalCenter
                        fontSize: "small"
                        text: !isNaN(model.duration) && model.duration !== 0 ? statusBox.formatTime(model.duration) : ""
                    }

                    Row {
                        id: actionRow

                        spacing: units.gu(2)
                        anchors.left: parent.left

                        Icon {
                            id: playButton
                            name: player.playbackState === MediaPlayer.PlayingState && currentGuid === model.guid ? "media-playback-pause"
                                                                                                                  : "media-playback-start"
                            width: units.gu(2.5)
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
                            id: downloadButton

                            width: units.gu(2.5)
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
        }

        PullToRefresh {
            refreshing: episodesUpdating
            onRefresh: updateEpisodes();
        }
    }

    function refreshModel() {
        var db = Podcasts.init();
        loadEpisodes(episodeModel.pid, episodeModel.artist, episodeModel.image);
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
