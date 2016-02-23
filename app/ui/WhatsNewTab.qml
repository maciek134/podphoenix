import QtQuick 2.4
import QtMultimedia 5.0
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.1
import QtQuick.LocalStorage 2.0
import Ubuntu.DownloadManager 0.1
import Ubuntu.Components.Popups 1.0
import Ubuntu.Components.ListItems 1.0 as ListItem
import "../podcasts.js" as Podcasts
import "../components"

Tab {
    id: whatsNewTab

    property var today: new Date()
    property int dayToMs: 86400000
    property string tempGuid: "NULL"
    property bool episodesUpdating: false

    TabsList {
        id: tabsList
    }

    page: Page {
        id: whatsNewPage

        header: standardHeader

        PageHeader {
            id: standardHeader
            visible: whatsNewPage.header === standardHeader
            title: i18n.tr("What's New")

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
                        whatsNewPage.header = searchHeader
                        searchField.item.forceActiveFocus()
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
        }

        PageHeader {
            id: searchHeader
            visible: whatsNewPage.header === searchHeader

            StyleHints {
                backgroundColor: podbird.appTheme.background
            }

            contents: Loader {
                id: searchField
                sourceComponent: whatsNewPage.header === searchHeader ? searchFieldComponent : undefined
                anchors.left: parent ? parent.left : undefined
                anchors.right: parent ? parent.right : undefined
                anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            }

            trailingActionBar.actions: [
                Action {
                    iconName: "edit-clear"
                    text: i18n.tr("Cancel")
                    onTriggered: {
                        episodeList.forceActiveFocus()
                        whatsNewPage.header = standardHeader
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

            sourceComponent: whatsNewModel.count === 0 || sortedEpisodeModel.count === 0 ? emptyStateComponent : undefined
        }

        Component {
            id: emptyStateComponent
            EmptyState {
                iconHeight: units.gu(12)
                iconWidth: units.gu(22)
                iconSource: whatsNewModel.count === 0 ? Qt.resolvedUrl("../graphics/owlSearch.svg") : Qt.resolvedUrl("../graphics/notFound.svg")
                title: whatsNewModel.count === 0 ? i18n.tr("No New Episodes") : i18n.tr("No Episodes Found")
                subTitle: whatsNewModel.count === 0 ? i18n.tr("No more episodes to listen to!") : i18n.tr("No Episodes found matching the search term.")
            }
        }

        ListModel {
            id: whatsNewModel
        }

        SortFilterModel {
            id: sortedEpisodeModel
            model: whatsNewModel
            filter.property: "name"
            filter.pattern: whatsNewPage.state === "search" && searchField.status == Loader.Ready ? RegExp(searchField.item.text, "gi")
                                                                                                  : RegExp("", "gi")
        }

        onVisibleChanged: {
            if (visible) {
                refreshModel()
                if (downloader.downloadingGuid != "")
                    tempGuid = downloader.downloadingGuid
            } else {
                whatsNewPage.header = standardHeader
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
                                whatsNewModel.setProperty(i, "queued", 0)
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

        UbuntuListView {
            id: episodeList

            Component.onCompleted: {
                // FIXME: workaround for qtubuntu not returning values depending on the grid unit definition
                // for Flickable.maximumFlickVelocity and Flickable.flickDeceleration
                var scaleFactor = units.gridUnit / 8;
                maximumFlickVelocity = maximumFlickVelocity * scaleFactor;
                flickDeceleration = flickDeceleration * scaleFactor;
            }

            anchors {
                top: whatsNewPage.header.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            clip: true

            model: sortedEpisodeModel
            currentIndex: -1
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

            delegate: ListDelegate {
                id: listItem

                coverArt: model.image !== undefined ? model.image : Qt.resolvedUrl("../graphics/podbird.png")

                title: model.name !== undefined ? model.name.trim() : "Undefined"
                titleColor: expanded || currentGuid === model.guid || downloader.downloadingGuid === model.guid ? podbird.appTheme.focusText
                                                                                                                : podbird.appTheme.baseText

                subtitle: model.duration === 0 || model.duration === undefined ? model.artist
                                                                               : Podcasts.formatEpisodeTime(model.duration) + " | " + model.artist

                isDownloaded: model.downloadedfile ? true : false

                showProgressBar: downloader.downloadingGuid === model.guid
                isInDeterminateDownload: downloader.progress < 0 || downloader.progress > 100 && downloader.downloadingGuid === model.guid
                progress: downloader.progress

                color: index % 2 === 0 ? podbird.appTheme.hightlightListView : "Transparent"

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
                                    whatsNewModel.setProperty(model.index, "downloadedfile", "")
                                } else {
                                    db.transaction(function (tx) {
                                        tx.executeSql("UPDATE Episode SET queued=1 WHERE guid = ?", [model.guid]);
                                    });
                                    whatsNewModel.setProperty(model.index, "queued", 1)
                                    downloader.addDownload(model.guid, model.audiourl);
                                }
                            }
                        },

                        Action {
                            iconName: "select"
                            onTriggered: {
                                var db = Podcasts.init();
                                db.transaction(function (tx) {
                                    tx.executeSql("UPDATE Episode SET listened=1 WHERE guid=?", [model.guid])
                                    whatsNewModel.remove(model.index, 1)
                                });
                            }
                        },

                        Action {
                            iconName: "info"
                            onTriggered: {
                                var popup = PopupUtils.open(episodeDescriptionDialog, whatsNewTab);
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

            // #FIXME: Use SDK Scrollbar when it is themeable
            CustomScrollBar {
                listview: episodeList
            }

            PullToRefresh {
                refreshing: episodesUpdating
                onRefresh: updateEpisodesDatabase();
            }
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

