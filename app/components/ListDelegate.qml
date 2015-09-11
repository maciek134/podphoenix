/*
 * Copyright 2015 Podbird Team
 *
 * This file is part of Podbird.
 *
 * Podbird is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * Podbird is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.2

ListItem {
    id: listDelegate

    // Public APIs
    property bool expanded: false

    property string coverArt: ""

    property alias title: _title.text
    property alias titleColor: _title.color
    property alias subtitle: _subtitle.text

    property string description: ""

    property bool isDownloaded: false

    property bool showProgressBar: false
    property bool isInDeterminateDownload: false
    property real progress: 0

    highlightColor: "Transparent"
    divider.visible: false
    height: mainColumn.height + units.gu(2)

    Column {
        id: mainColumn

        anchors { left: parent.left; right: parent.right; margins: units.gu(2); verticalCenter: parent.verticalCenter }

        RowLayout {
            id: mainRow

            width: parent.width
            spacing: units.gu(2)

            Loader {
                id: imgFrameLoader
                visible: coverArt !== ""
                sourceComponent: coverArt !== "" ? imgFrame : undefined
            }

            Column {
                id: detailColumn

                anchors.verticalCenter: parent.verticalCenter
                Layout.fillWidth: true

                Label {
                    id: _title
                    textFormat: Text.PlainText
                    width: parent.width
                    maximumLineCount: 2
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    color: podbird.appTheme.baseText
                }

                Row {
                    height: _subtitle.height
                    width: parent.width
                    spacing: units.gu(1)

                    Loader {
                        id: downloadIconLoader
                        height: _subtitle.height
                        width: height
                        visible: isDownloaded
                        sourceComponent: downloadIcon
                    }

                    Label {
                        id: _subtitle
                        width: parent.width
                        fontSize: "x-small"
                        elide: Text.ElideRight
                        color: podbird.appTheme.baseSubText
                    }
                }
            }
        }

        Item {
            id: gapFiller2
            height: showProgressBar || expanded ? units.gu(1) : 0
            width: height
        }

        Loader {
            id: progressBarLoader
            width: parent.width
            height: showProgressBar ? units.dp(5) : 0
            visible: sourceComponent !== undefined
            sourceComponent: showProgressBar ? progressBar : undefined
        }

        Loader {
            id: descriptionLoader
            width: parent.width
            height: expanded && loaded ? item.contentHeight : 0
            visible: sourceComponent !== undefined
            sourceComponent: expanded ? _description : undefined
            Behavior on height {
                UbuntuNumberAnimation {
                    duration: UbuntuAnimation.BriskDuration
                }
            }
        }
    }

    Component {
        id: imgFrame
        Image {
            height: width
            width: units.gu(6)
            source: coverArt
            sourceSize { width: width; height: height }
        }
    }

    Component {
        id: progressBar
        CustomProgressBar {
            indeterminateProgress: isInDeterminateDownload
            progress: listDelegate.progress
        }
    }

    Component {
        id: downloadIcon
        Icon {
            name: "attachment"
        }
    }

    Component {
        id: _description
        Label {
            clip: true
            text: description
            wrapMode: Text.WordWrap
            fontSize: "small"
            color: podbird.appTheme.baseSubText
            linkColor: podbird.appTheme.linkText
            onLinkActivated: Qt.openUrlExternally(link)
        }
    }
}
