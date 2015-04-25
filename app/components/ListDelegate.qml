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

import QtQuick 2.3
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 1.0 as ListItem

ListItem.Empty {
    id: listDelegate

    // Public APIs
    property bool expanded: false
    property string coverArt: ""
    property alias title: _title.text
    property alias subtitle: _subtitle.text

    highlightWhenPressed: false
    showDivider: false
    height: mainColumn.height + units.gu(2)

    Column {
        id: mainColumn

        anchors { left: parent.left; right: parent.right; margins: units.gu(2); verticalCenter: parent.verticalCenter }
        spacing: units.gu(1)

        RowLayout {
            id: mainRow

            width: parent.width
            spacing: units.gu(2)

            Loader {
                id: imgFrameLoader
                visible: sourceComponent !== undefined
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

                Label {
                    id: _subtitle
                    width: parent.width
                    fontSize: "x-small"
                    color: podbird.appTheme.baseSubText
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
}
