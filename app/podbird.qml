import QtQuick 2.0
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0
import Ubuntu.DownloadManager 0.1
import Ubuntu.Components 1.1
import Podbird 1.0
import "ui"
import "podcasts.js" as Podcasts

MainView {
    objectName: "mainView"
    applicationName: "com.mikeasoft.podbird"

    property string currentName
    property string currentArtist
    property string currentImage
    property string currentGuid

    useDeprecatedToolbar: false
    anchorToKeyboard: true

    width: units.gu(50)
    height: units.gu(75)

    FileManager {
        id: fileManager
    }

    SingleDownload {
        id: imageDownloader
        property string feed;
        onFinished: {
            var db = Podcasts.init();
            var finalLocation = fileManager.saveDownload(path);
            db.transaction(function (tx) {
                tx.executeSql("UPDATE Podcast SET image=? WHERE feed=?", [finalLocation, feed]);
            });
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

    MediaPlayer {
        id: player
        onPositionChanged: {
            if (currentGuid == "" || duration <= 0) {
                return;
            }

            var db = Podcasts.init();
            db.transaction(function (tx) {
                tx.executeSql("UPDATE Episode SET position=? WHERE guid=?", [position >= duration - 30 ? 0 : position, currentGuid]);
                if (position >= duration - 30) {
                    tx.executeSql("UPDATE Episode SET listened = 1 WHERE guid=?", [currentGuid]);
                }
            });
        }
    }

    PageStack {
        id: mainStack
        Component.onCompleted: push(tabs)
        Tabs {
            id: tabs

            PodcastsTab {
                id: podcastTab
                objectName: "podcastsTab"
            }

            SearchTab {
                objectName: "searchTab"
            }
        }
    }

    PlayerControls {
        anchors.bottom: parent.bottom
        height: player.source == "" ? 0 : units.gu(8)
        width: parent.width

        Behavior on height {
            UbuntuNumberAnimation {
                duration: UbuntuAnimation.SlowDuration
            }
        }
    }
}

