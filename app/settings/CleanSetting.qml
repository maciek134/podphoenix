import QtQuick 2.3
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 1.0 as ListItem

Page {
    id: cleanSettingPage

    visible: false
    title: i18n.tr("Delete older than")

    ListModel {
        id: cleanupModel
        Component.onCompleted: initialize()
        function initialize() {
            cleanupModel.append({ name: i18n.tr("Never"), value: -1 })
            cleanupModel.append({ name: i18n.tr("%1 day", "%1 days", 7).arg(7), value: 7 })
            cleanupModel.append({ name: i18n.tr("%1 day", "%1 days", 31).arg(31), value: 31 })
            cleanupModel.append({ name: i18n.tr("%1 day", "%1 days", 90).arg(90), value: 90 })
            cleanupModel.append({ name: i18n.tr("%1 day", "%1 days", 180).arg(180), value: 180 })
            cleanupModel.append({ name: i18n.tr("%1 day", "%1 days", 360).arg(360), value: 360 })
        }
    }

    UbuntuListView {
        id: cleanup

        model: cleanupModel
        anchors.fill: parent

        delegate: ListItem.Standard {
            text: model.name
            onClicked: {
                podbird.settings.retentionDays = model.value
            }

            Icon {
                width: units.gu(2)
                height: width
                name: "ok"
                visible: podbird.settings.retentionDays === model.value
                anchors.right: parent.right
                anchors.rightMargin: units.gu(3)
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
