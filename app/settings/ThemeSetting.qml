import QtQuick 2.3
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 1.0 as ListItem

Page {
    id: themeSettingPage

    visible: false
    title: i18n.tr("Theme")

    ListModel {
        id: themeModel
        Component.onCompleted: initialize()
        function initialize() {
            themeModel.append({ name: i18n.tr("Light"), file: "Light.qml" })
            themeModel.append({ name: i18n.tr("Dark"), file: "Dark.qml" })
        }
    }

    UbuntuListView {
        id: themes

        model: themeModel
        anchors.fill: parent

        delegate: ListItem.Standard {
            text: model.name
            onClicked: {
                var themeElement = model.file
                podbird.settings.themeName = themeElement
                podbird.themeManager.source = themeElement
            }

            Icon {
                width: units.gu(2)
                height: width
                name: "ok"
                visible: podbird.settings.themeName === model.file
                anchors.right: parent.right
                anchors.rightMargin: units.gu(3)
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
