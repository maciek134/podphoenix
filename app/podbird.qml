import QtQuick 2.0
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0
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

    width: units.gu(50)
    height: units.gu(75)

    FileManager {
        id: fileManager
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

    Tabs {
        id: tabs

        PodcastsTab {
            objectName: "podcastsTab"
        }

        SearchTab {
            objectName: "searchTab"
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

