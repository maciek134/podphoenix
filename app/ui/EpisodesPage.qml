import QtQuick 2.0
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
    title: episodeName

    property string episodeName
    property string episodeId
    property string episodeArtist
    property string episodeImage

    property bool episodesUpdating: false;

    Component.onCompleted: {
        loadEpisodes(episodeId, episodeArtist, episodeImage)
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
                    text: i18n.tr("Mark all as listened")
                    onTriggered: {
                        var db = Podcasts.init();
                        db.transaction(function (tx) {
                            tx.executeSql("UPDATE Episode SET listened=1 WHERE podcast=?", [episodeModel.pid]);
                            refreshModel();
                        });
                    }
                },

                Action {
                    text: i18n.tr("Unsubscribe")
                    iconName: "delete"
                    onTriggered: {
                        PopupUtils.open(confirmDeleteDialog);
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
                }
            }

            contents: TextField {
                id: searchField
                inputMethodHints: Qt.ImhNoPredictiveText
                placeholderText: i18n.tr("Search Episode...")
                anchors.left: parent ? parent.left : undefined
                anchors.right: parent ? parent.right : undefined
                anchors.rightMargin: units.gu(2)
            }
        }
    ]

    Component {
        id: confirmDeleteDialog
        Dialog {
            id: dialogInternal
            title: i18n.tr("Unsubscribe Confirmation")
            text: i18n.tr("Are you sure you want to unsubscribe from <b>%1</b>?").arg(episodesPage.episodeName)
            Button {
                text: i18n.tr("Yes")
                color: UbuntuColors.orange
                onClicked: {
                    var db = Podcasts.init();
                    db.transaction(function (tx) {
                        var rs = tx.executeSql("SELECT downloadedfile FROM Episode WHERE downloadedfile NOT NULL AND podcast=?", [episodeModel.pid]);
                        for(var i = 0; i < rs.rows.length; i++) {
                            fileManager.deleteFile(rs.rows.item(i).downloadedfile);
                        }
                        tx.executeSql("DELETE FROM Episode WHERE podcast=?", [episodeModel.pid]);
                        tx.executeSql("DELETE FROM Podcast WHERE rowid=?", [episodeModel.pid]);
                        mainStack.pop()
                        PopupUtils.close(dialogInternal)
                    });
                }
            }
            Button {
                text: i18n.tr("No")
                color: UbuntuColors.green
                onClicked: {
                    PopupUtils.close(dialogInternal)
                }
            }
        }
    }

    EmptyState {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: Qt.inputMethod.visible ? units.gu(4) : 0
        visible: episodesPage.state === "search" && sortedEpisodeModel.count === 0
        iconName: "music-app-symbolic"
        title: i18n.tr("No Episodes found")
        subTitle: i18n.tr("No episodes found matching the search term.")
    }

    ListModel {
        id: episodeModel
        property string pid;
        property string artist;
        property string image;
    }

    SortFilterModel {
        id: sortedEpisodeModel
        model: episodeModel
        filter.property: "name"
        filter.pattern: RegExp(searchField.text, "gi")
    }

    ListView {
        id: episodeList

        clip: true
        anchors.fill: parent
        model: sortedEpisodeModel

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
                            id: episodeArtist
                            width: parent.width
                            text: model.artist
                            fontSize: "small"
                            elide: Text.ElideRight
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

                        ProgressBar {
                            visible: downloader.downloadingGuid === model.guid
                            minimumValue: 0
                            maximumValue: 100
                            width: units.gu(16)
                            height: units.gu(2.6)
                            value: downloader.progress
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
