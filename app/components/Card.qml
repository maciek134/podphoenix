/*
 * Copyright 2016 Podbird Team
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
import Ubuntu.Components 1.3

AbstractButton {
    id: card

    height: parent.parent.cellHeight
    width: parent.parent.cellWidth

    property alias coverArt: imgFrame.source
    property alias primaryText: primaryLabel.text
    property string secondaryText: ""

    Image {
        id: imgFrame
        width: parent.width
        height: width
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        sourceSize.height: width
        sourceSize.width: width

        Loader {
            id: hintLoader
            anchors.top: parent.top
            anchors.topMargin: units.gu(0.5)
            anchors.right: parent.right
            anchors.rightMargin: units.gu(0.5)
            sourceComponent: secondaryText !== "" ? hintComponent : undefined
        }

        Component {
            id: hintComponent
            Rectangle {
                color: podbird.appTheme.focusText
                width: secondaryLabel.implicitWidth + units.gu(1)
                height: secondaryLabel.implicitHeight + units.gu(1)
                radius: units.gu(3)
                visible: secondaryLabel.text !== ""
                Label {
                    id: secondaryLabel
                    anchors.centerIn: parent
                    text: secondaryText
                    visible: text !== ""
                    textSize: Label.Small
                    color: "White"
                }
            }
        }
    }

    Label {
        id: primaryLabel
        anchors {
            top: imgFrame.bottom
            left: imgFrame.left
            right: imgFrame.right
            margins: units.gu(1)
        }
        color: podbird.appTheme.baseText
        elide: Text.ElideRight
        textSize: Label.Small
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        horizontalAlignment: Text.AlignHCenter
    }
}
