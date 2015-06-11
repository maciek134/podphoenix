import QtQuick 2.3
import Ubuntu.Components 1.2

ListItem {
    id: headerListItem

    property alias title: headerText.text

    height: headerText.implicitHeight + units.gu(1)
    Label {
        id: headerText
        anchors.left: parent.left
        anchors.leftMargin: units.gu(2)
        anchors.verticalCenter: parent.verticalCenter
        font.weight: Font.DemiBold
    }
}
