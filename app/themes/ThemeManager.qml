import QtQuick 2.3
import Ubuntu.Components 1.1

QtObject {
    id: themeManager
    property string name
    property var themeObject: new QtObject()

    onNameChanged: {
        var themeComponent = Qt.createComponent(Qt.resolvedUrl(name))
        if (themeComponent.status == Component.Ready) {
            var themeObject = themeComponent.createObject(themeManager)
            for (var key in themeObject) {
                if (themeManager.hasOwnProperty(key)) {
                    themeManager[key] = themeObject[key]
                }
            }
        }
    }

    // MainView
    property color background

    // Main Text Colors
    property color baseText
    property color baseSubText
    property color focusText

    // Icon Colors
    property color baseIcon

    // Button Colors
    property color positiveActionButton
    property color negativeActionButton
    property color neutralActionButton

    // Bottom Player Bar Colors
    property color bottomBarBackground

    // Highlight Color
    property color hightlightListView
}
