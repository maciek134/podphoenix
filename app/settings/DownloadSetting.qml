import QtQuick 2.0
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 1.0 as ListItem

Page {
    id: downloadSetting

    visible: false
    title: i18n.tr("Download at most")

    ListModel {
        id: episodeDownloadNumber
        Component.onCompleted: initialize()
        function initialize() {
            episodeDownloadNumber.append({ name: i18n.tr("Never"), value: -1 })
            episodeDownloadNumber.append({ name: i18n.tr("%1 episode", "%1 episodes", 1).arg(1), value: 1 })
            episodeDownloadNumber.append({ name: i18n.tr("%1 episode", "%1 episodes", 3).arg(3), value: 3 })
            episodeDownloadNumber.append({ name: i18n.tr("%1 episode", "%1 episodes", 5).arg(5), value: 5 })
            episodeDownloadNumber.append({ name: i18n.tr("%1 episode", "%1 episodes", 10).arg(10), value: 10 })
        }
    }

    UbuntuListView {
        id: download

        model: episodeDownloadNumber
        anchors.fill: parent

        delegate: ListItem.Standard {
            text: model.name
            onClicked: {
                podbird.settings.maxEpisodeDownload = model.value
            }

            Icon {
                width: units.gu(2)
                height: width
                name: "ok"
                visible: podbird.settings.maxEpisodeDownload === model.value
                anchors.right: parent.right
                anchors.rightMargin: units.gu(3)
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
