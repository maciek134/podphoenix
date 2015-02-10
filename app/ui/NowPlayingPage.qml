import QtQuick 2.0
import QtQuick.Layouts 1.1
import QtMultimedia 5.0
import Ubuntu.Components 1.1
import "../podcasts.js" as Podcasts

Page {
    id: nowPlayingPage

    visible: false
    title: i18n.tr("Now Playing")

    property bool isNowPlayingPage: true

    BlurredBackground {
        id: blurredBackground

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.right: parent.right
        height: parent.height/2.5
        art: currentImage

        Image {
            width: units.gu(6)
            height: width
            sourceSize.height: width
            sourceSize.width: width
            source: currentImage
            anchors.centerIn: parent
        }
    }

    Label {
        id: title
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: blurredBackground.bottom
        anchors.margins: units.gu(2)
        text: currentName
        elide: Text.ElideRight
        fontSize: "x-large"
        maximumLineCount: 2
        wrapMode: Text.WordWrap
    }

    Label {
        id: artist
        anchors.left: title.left
        anchors.right: title.right
        anchors.top: title.bottom
        anchors.topMargin: units.gu(1)
        text: currentArtist
        elide: Text.ElideRight
        fontSize: "small"
    }

    RowLayout {
        id: sliderRow

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: artist.bottom
        anchors.margins: units.gu(2)
        anchors.topMargin: units.gu(4)
        spacing: units.gu(0.5)

        Label {
            id: startTime
            fontSize: "small"
            text: Podcasts.formatTime(player.position / 1000)
        }

        Slider {
            id: scrubber
            minimumValue: 0
            Layout.fillWidth: true
            live: true
            height: units.gu(2)
            onValueChanged: {
                if (pressed) {
                    player.seek(value);
                }
            }
            function formatValue(v) { return Podcasts.formatTime(v/1000); }
        }

        Label {
            id: endTime
            fontSize: "small"
            text: Podcasts.formatTime(player.duration / 1000)
        }
    }

    Connections {
        target: player
        onDurationChanged: {
            scrubber.maximumValue = player.duration
        }
        onPositionChanged: {
            scrubber.value = player.position
        }
    }

    Row {
        id: controls
        anchors.top: sliderRow.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.margins: units.gu(4)
        spacing: units.gu(4)

        Icon {
            width: units.gu(6)
            height: width
            name: "media-skip-backward"
            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            width: units.gu(6); height: units.gu(6)
            anchors.verticalCenter: parent.verticalCenter
            Icon {
                anchors.centerIn: parent
                //color: "gray"
                width: units.gu(10)
                height: width
                name: player.playbackState === MediaPlayer.PlayingState ? "media-playback-pause"
                                               : "media-playback-start"
                opacity: play.pressed ? 0.4 : 1.0
            }
            MouseArea {
                id: play
                anchors.fill: parent
                onClicked: player.playbackState === MediaPlayer.PlayingState ? player.pause() : player.play()
            }
        }

        Icon {
            width: units.gu(6)
            height: width
            name: "media-skip-forward"
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
