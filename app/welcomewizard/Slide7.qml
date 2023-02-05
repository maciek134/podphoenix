/*
 * Copyright 2015 Podphoenix Team
 *
 * This file is part of Podphoenix.
 *
 * Podphoenix is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * Podphoenix is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3

// Slide 6
Component {
    id: slide6
    Item {
        id: slide1Container

        Image {
            anchors {
                top: parent.top
                bottom: introductionText.top
                bottomMargin: units.gu(6)
                horizontalCenter: parent.horizontalCenter
            }
            fillMode: Image.PreserveAspectFit
            source: Qt.resolvedUrl("../graphics/gift.png")
        }

        Label {
            id: introductionText
            anchors.centerIn: parent
            elide: Text.ElideRight
            textSize: Label.XLarge
            maximumLineCount: 2
            text: i18n.tr("Enjoy")
            horizontalAlignment: Text.AlignHCenter
            width: parent.width
            wrapMode: Text.WordWrap
        }

        Label {
            id: finalMessage
            anchors {
                top: introductionText.bottom
                bottom: continueButton.top
                left: parent.left
                right: parent.right
                margins: units.gu(1)
                topMargin: units.gu(4)
            }
            horizontalAlignment: Text.AlignHCenter
            text: i18n.tr("We hope you enjoy using Podphoenix!")
            wrapMode: Text.WordWrap
        }

        Button {
            id: continueButton
            anchors {
                bottom: parent.bottom
                bottomMargin: units.gu(3)
                horizontalCenter: parent.horizontalCenter
            }
            width: Math.min(parent.width/1.3, units.gu(40))
            color: theme.palette.normal.positive
            text: i18n.tr("Finish")
            onClicked: finished()
        }
    }
}
