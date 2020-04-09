import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Content 1.3


Page {
    id: picker
    property var activeTransfer

    property var url
    property var handler
    property var contentType

    signal cancel()
    signal imported(string fileUrl)

    header: PageHeader {
        title: i18n.tr("Choose")
    }

    ContentPeerPicker {
        anchors { fill: parent; topMargin: picker.header.height }
        visible: parent.visible
        showTitle: false
        contentType: picker.contentType
        handler: picker.handler

        onPeerSelected: {
            peer.selectionType = ContentTransfer.Single
            picker.activeTransfer = peer.request()
            picker.activeTransfer.stateChanged.connect(function() {
                if (picker.activeTransfer.state === ContentTransfer.InProgress) {
                    console.log("In progress");
                    picker.activeTransfer.items = picker.activeTransfer.items[0].url = url;
                    picker.activeTransfer.state = ContentTransfer.Charged;
                }
                if (picker.activeTransfer.state === ContentTransfer.Charged) {
                    console.log("Charged");
                    picker.imported(picker.activeTransfer.items[0].url)
                    console.log(picker.activeTransfer.items[0].url)
                    picker.activeTransfer = null
                }
            })
        }

        onCancelPressed: {
            pageStack.pop()
        }
    }

    ContentTransferHint {
        id: transferHint
        anchors.fill: parent
        activeTransfer: picker.activeTransfer
    }

    Component {
        id: resultComponent
        ContentItem {}
    }
}
