import QtQuick 2.3
import QtMultimedia 5.0
import Ubuntu.Components 1.1
import QtQuick.Layouts 1.1
import QtQuick.LocalStorage 2.0
import Ubuntu.DownloadManager 0.1
import Ubuntu.Components.Popups 1.0
import Ubuntu.Components.ListItems 1.0 as ListItem
import "../podcasts.js" as Podcasts

Tab {
    id: whatsNewTab

    title: i18n.tr("What's New")

    property var today: new Date()
    property int dayToMs: 86400000
    property string tempGuid: "NULL"
    property bool episodesUpdating: false

    page: Page {
        id: whatsNewPage

        state: "default"
        states: [
            PageHeadState {
                name: "default"
                head: whatsNewPage.head
                actions: [
                    Action {
                        iconName: "search"
                        text: i18n.tr("Search Episode")
                        onTriggered: {
                            whatsNewPage.state = "search"
                            searchField.forceActiveFocus()
                        }
                    },

                    Action {
                        iconName: "select"
                        text: i18n.tr("Mark all listened")
                        onTriggered: {
                            var db = Podcasts.init();
                            db.transaction(function (tx) {
                                for (var i=0; i<whatsNewModel.count; i++) {
                                    tx.executeSql("UPDATE Episode SET listened=1 WHERE guid=?", [whatsNewModel.get(i).guid]);
                                }
                                whatsNewModel.clear()
                            });
                        }
                    },

                    Action {
                        iconName: "save"
                        text: i18n.tr("Download all")
                        onTriggered: {
                            var db = Podcasts.init();
                            db.transaction(function (tx) {
                                for (var i=0; i<whatsNewModel.count; i++) {
                                    if (!whatsNewModel.get(i).downloadedfile) {
                                        whatsNewModel.setProperty(i, "queued", 1)
                                        tx.executeSql("UPDATE Episode SET queued=1 WHERE guid = ?", [whatsNewModel.get(i).guid]);
                                        downloader.addDownload(whatsNewModel.get(i).guid, whatsNewModel.get(i).audiourl);
                                    }
                                }
                            });
                        }
                    }
                ]
            },

            PageHeadState {
                name: "search"
                head: whatsNewPage.head
                backAction: Action {
                    iconName: "back"
                    text: i18n.tr("Back")
                    onTriggered: {
                        episodeList.forceActiveFocus()
                        searchField.text = ""
                        whatsNewPage.state = "default"
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

        EmptyState {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: Qt.inputMethod.visible ? units.gu(4) : 0
            iconHeight: units.gu(12)
            iconWidth: iconHeight + units.gu(10)
            visible: whatsNewModel.count === 0 || sortedEpisodeModel.count === 0
            iconSource: whatsNewModel.count === 0 ? Qt.resolvedUrl("../graphics/owlSearch.svg")
                                                  : Qt.resolvedUrl("../graphics/notFound.svg")
            title: whatsNewModel.count === 0 ? i18n.tr("No New Episodes")
                                             : i18n.tr("No Episodes Found")
            subTitle: whatsNewModel.count === 0 ? i18n.tr("No more episodes to listen to!")
                                                : i18n.tr("No Episodes found matching the search term.")
        }

        ListModel {
            id: whatsNewModel
        }

        SortFilterModel {
            id: sortedEpisodeModel
            model: whatsNewModel
            filter.property: "name"
            filter.pattern: RegExp(searchField.text, "gi")
        }

        onVisibleChanged: {
            if (visible) {
                refreshModel()
                if (downloader.downloadingGuid != "")
                    tempGuid = downloader.downloadingGuid
            }
        }

        Connections {
            target: downloader
            onDownloadingGuidChanged: {
                var db = Podcasts.init();
                db.transaction(function (tx) {
                    /*
                     If tempGuid is NULL, then the episode currently being downloaded is not found within
                     this podcast. On the other hand, if it is within this podcast, then update the whatsNewModel
                     with the downloadedfile location we just received from the downloader.
                    */
                    if (tempGuid != "NULL") {
                        var rs2 = tx.executeSql("SELECT downloadedfile FROM Episode WHERE guid=?", [tempGuid]);
                        for (var i=0; i<whatsNewModel.count; i++) {
                            if (whatsNewModel.get(i).guid == tempGuid) {
                                console.log("[LOG]: Setting episode download URL to " + rs2.rows.item(0).downloadedfile)
                                whatsNewModel.setProperty(i, "downloadedfile", rs2.rows.item(0).downloadedfile)
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
            }
        }

        Component {
            id: popoverComponent

            Popover {
                id: popover

                property bool queued: false
                property string downloadedfile: ""
                property string guid: ""
                property string audiourl: ""
                property int index: -1
                property string name: ""
                property string artist: ""
                property string image: ""

                contentWidth: mainColumn.width

                Column {
                    id: mainColumn

                    width: Math.max(download.width, listen.width, play.width)
                    anchors.top: parent.top

                    ListItem.Empty {
                        id: download

                        width: Math.max(row.width, row2.width, row3.width)

                        Row {
                            id: row

                            spacing: units.gu(3)
                            anchors.left: parent.left
                            anchors.leftMargin: units.gu(2)
                            anchors.verticalCenter: parent.verticalCenter
                            width: downloadIcon.width + downloadText.implicitWidth + row.spacing + units.gu(4)

                            Icon {
                                id: downloadIcon
                                width: height
                                height: downloadText.height
                                name: popover.downloadedfile ? "delete" : (popover.queued && downloader.downloadingGuid !== popover.guid ? "history" : "save")
                            }

                            Label {
                                id: downloadText
                                color: UbuntuColors.darkGrey
                                text: popover.downloadedfile ? i18n.tr("Delete local file")
                                                             : (popover.queued && downloader.downloadingGuid !== popover.guid ? i18n.tr("Episode queued for download")
                                                                                                                              : i18n.tr("Download episode"))
                            }
                        }

                        enabled: downloader.downloadingGuid !== popover.guid
                        onClicked: {
                            var db = Podcasts.init();
                            if (popover.downloadedfile) {
                                fileManager.deleteFile(popover.downloadedfile);
                                db.transaction(function (tx) {
                                    tx.executeSql("UPDATE Episode SET downloadedfile = NULL WHERE guid = ?", [popover.guid]);
                                });
                                whatsNewModel.setProperty(popover.index, "downloadedfile", "")
                            } else {
                                db.transaction(function (tx) {
                                    tx.executeSql("UPDATE Episode SET queued=1 WHERE guid = ?", [popover.guid]);
                                });
                                whatsNewModel.setProperty(popover.index, "queued", 1)
                                downloader.addDownload(popover.guid, popover.audiourl);
                            }
                            PopupUtils.close(popover)
                        }
                    }

                    ListItem.Empty {
                        id: listen

                        width: Math.max(row.width, row2.width, row3.width)

                        Row {
                            id: row2

                            spacing: units.gu(3)
                            anchors.left: parent.left
                            anchors.leftMargin: units.gu(2)
                            anchors.verticalCenter: parent.verticalCenter
                            width: listenIcon.width + listenText.implicitWidth + row2.spacing + units.gu(4)

                            Icon {
                                id: listenIcon
                                width: height
                                height: listenText.height
                                name: "select"
                            }

                            Label {
                                id: listenText
                                color: UbuntuColors.darkGrey
                                text: i18n.tr("Mark episode listened")
                            }
                        }

                        onClicked: {
                            var db = Podcasts.init();
                            db.transaction(function (tx) {
                                tx.executeSql("UPDATE Episode SET listened=1 WHERE guid=?", [popover.guid])
                                whatsNewModel.remove(popover.index, 1)
                            });
                            PopupUtils.close(popover)
                        }
                    }

                    ListItem.Empty {
                        id: play

                        showDivider: false
                        width: Math.max(row.width, row2.width, row3.width)

                        Row {
                            id: row3

                            spacing: units.gu(3)
                            anchors.left: parent.left
                            anchors.leftMargin: units.gu(2)
                            anchors.verticalCenter: parent.verticalCenter
                            width: playIcon.width + playText.implicitWidth + row3.spacing + units.gu(4)

                            Icon {
                                id: playIcon
                                width: height
                                height: listenText.height
                                name: player.playbackState === MediaPlayer.PlayingState && currentGuid === popover.guid ? "media-playback-pause"
                                                                                                                        : "media-playback-start"
                            }

                            Label {
                                id: playText
                                color: UbuntuColors.darkGrey
                                text: player.playbackState === MediaPlayer.PlayingState && currentGuid === popover.guid ? i18n.tr("Pause Episode")
                                                                                                                        : i18n.tr("Play Episode")
                            }
                        }

                        onClicked: {
                            var db = Podcasts.init();
                            db.transaction(function (tx) {
                                if (currentGuid === popover.guid) {
                                    if (player.playbackState === MediaPlayer.PlayingState) {
                                        player.pause()
                                    } else {
                                        player.play()
                                    }
                                } else {
                                    currentGuid = "";
                                    player.source = popover.downloadedfile ? popover.downloadedfile : popover.audiourl;
                                    var rs = tx.executeSql("SELECT position FROM Episode WHERE guid=?", [popover.guid]);
                                    player.play();
                                    player.seek(rs.rows.item(0).position);
                                    currentName = popover.name;
                                    currentArtist = popover.artist;
                                    currentImage = popover.image;
                                    currentGuid = popover.guid;
                                }
                            });
                            PopupUtils.close(popover)
                        }
                    }
                }
            }
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
            section.property: "diff"
            section.labelPositioning: ViewSection.InlineLabels

            section.delegate: Rectangle {
                width: parent.width
                color: "Transparent"
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
                    text:  {
                        if (section === "Today") {
                            return i18n.tr("Today")
                        }

                        else if (section === "Yesterday") {
                            return i18n.tr("Yesterday")
                        }

                        else if (section === "Older")
                            return i18n.tr("Older")
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
                        height: imgFrame.height

                        Image {
                            id: imgFrame
                            width: units.gu(6)
                            height: width
                            sourceSize.height: width
                            sourceSize.width: width
                            source: model.image
                        }

                        Item {
                            width: units.gu(2)
                            height: imgFrame.height
                        }

                        Column {
                            id: titleColumn
                            anchors.verticalCenter: imgFrame.verticalCenter
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

                            Row {
                                height:episodePublishDate.height
                                width:parent.width
                                spacing:units.gu(1)

                                Icon{
                                    height:episodePublishDate.height
                                    width:height
                                    name:"attachment"
                                    visible: model.downloadedfile ? true : false
                                }

                                Label {
                                    id: episodePublishDate
                                    width: parent.width
                                    text: model.duration === undefined ? model.artist : Podcasts.formatEpisodeTime(model.duration) + " | " + model.artist
                                    fontSize: "x-small"
                                    elide: Text.ElideRight
                                    color: podbird.theme.baseSubText
                                }
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
                                popover.guid = Qt.binding(function() { return model.guid })
                                popover.audiourl = Qt.binding(function() { return model.audiourl })
                                popover.downloadedfile = Qt.binding(function() { return whatsNewModel.get(index).downloadedfile })
                                popover.index = Qt.binding(function() { return index })
                                popover.name = Qt.binding(function() { return model.name })
                                popover.artist = Qt.binding(function() { return model.artist })
                                popover.image = Qt.binding(function() { return model.image })
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
                            id: currentProgress
                            height: parent.height
                            radius: parent.radius
                            anchors.left: parent.left
                            anchors.top: parent.top
                            color: podbird.theme.focusText
                            width: downloader.progress >= 0 && downloader.progress <= 100 ? (downloader.progress / 100) * parent.width : parent.width / 6

                            SequentialAnimation {
                                running: downloader.progress < 0 || downloader.progress > 100 && downloader.downloadingGuid === model.guid
                                onRunningChanged: {
                                    currentProgress.anchors.leftMargin = 0;
                                }
                                loops: Animation.Infinite
                                PropertyAnimation { target: currentProgress.anchors; property: "leftMargin"; from: 0.0; to: parent.width  - parent.width / 6 - units.gu(3); duration: UbuntuAnimation.SleepyDuration; easing.type:  Easing.InOutQuad; }
                                PropertyAnimation { target: currentProgress.anchors; property: "leftMargin"; from: parent.width  - parent.width / 6 - units.gu(3); to: 0; duration: UbuntuAnimation.SleepyDuration; easing.type: Easing.InOutQuad; }
                            }
                        }
                    }

                    CustomProgressBar {
                        id: progressBar2
                        width: parent.width
                        visible: downloader.downloadingGuid === model.guid
                        indeterminateProgress: downloader.progress < 0 || downloader.progress > 100 && downloader.downloadingGuid === model.guid
                        progress: downloader.progress
                    }

                    Label {
                        id: desc
                        text: model.description
                        clip: true
                        height: listItem.expanded ? contentHeight : 0
                        wrapMode: Text.WordWrap
                        width: parent.width
                        fontSize: "small"
                        color: podbird.theme.baseSubText
                        linkColor: podbird.theme.linkText
                        onLinkActivated: Qt.openUrlExternally(link)
                        Behavior on height {
                            UbuntuNumberAnimation {
                                duration: UbuntuAnimation.BriskDuration
                            }
                        }
                    }
                }
            }

            // #FIXME: Use SDK Scrollbar when it is themeable
            CustomScrollBar {
                listview: episodeList
            }

            PullToRefresh {
                refreshing: episodesUpdating
                onRefresh: whatsNewPage.updateEpisodesDatabase();
            }
        }

        function refreshModel() {
            var today = new Date()
            var dayToMs = 86400000; //1 * 24 * 60 * 60 * 1000
            var i, j, episode, diff
            var todayCount, yesterdayCount

            whatsNewModel.clear()
            todayCount = 0
            yesterdayCount = 0

            var db = Podcasts.init()
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
                                whatsNewModel.insert(todayCount, {"guid" : episode.guid, "listened" : episode.listened, "published": episode.published, "name" : episode.name, "description" : episode.description, "duration" : episode.duration, "position" : episode.position, "downloadedfile" : episode.downloadedfile, "image" : podcast.image, "artist" : podcast.artist, "audiourl" : episode.audiourl, "queued": episode.queued, "diff": "Today"})
                                todayCount++;
                            } else if (diff < 2) {
                                whatsNewModel.insert(todayCount + yesterdayCount, {"guid" : episode.guid, "listened" : episode.listened, "published": episode.published, "name" : episode.name, "description" : episode.description, "duration" : episode.duration, "position" : episode.position, "downloadedfile" : episode.downloadedfile, "image" : podcast.image, "artist" : podcast.artist, "audiourl" : episode.audiourl, "queued": episode.queued, "diff": "Yesterday"})
                                yesterdayCount++;
                            } else {
                                whatsNewModel.append({"guid" : episode.guid, "listened" : episode.listened, "published": episode.published, "name" : episode.name, "description" : episode.description, "duration" : episode.duration, "position" : episode.position, "downloadedfile" : episode.downloadedfile, "image" : podcast.image, "artist" : podcast.artist, "audiourl" : episode.audiourl, "queued": episode.queued, "diff": "Older"})
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

            episodesUpdating = false;
        }

        function updateEpisodesDatabase() {
            console.log("[LOG]: Checking for new episodes")
            episodesUpdating = true;
            Podcasts.updateEpisodes(refreshModel)
        }
    }
}
