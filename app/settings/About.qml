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
import Ubuntu.Components 1.1

Page {
    id: aboutPage

    title: i18n.tr("About")

    Column {
        spacing: units.gu(3)
        anchors.fill: parent
        anchors.topMargin: units.gu(5)
        anchors.bottomMargin: units.gu(10)

        Image {
            height: width
            width: parent.width/2
            source: "../graphics/podbird.png"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Column {
            width: parent.width
            Label {
                width: parent.width
                fontSize: "x-large"
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                text: "Podbird"
            }
            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: i18n.tr("Version %1").arg("0.6.beta2")
            }
        }

        Column {
            anchors {
                left: parent.left
                right: parent.right
                margins: units.gu(2)
            }
            Label {
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                text: "(C) 2015 Podbird Team"
            }
            Label {
                fontSize: "small"
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                text: i18n.tr("Released under the terms of the GNU GPL v3")
            }
        }

        Label {
            width: parent.width
            wrapMode: Text.WordWrap
            fontSize: "small"
            horizontalAlignment: Text.AlignHCenter
            text: i18n.tr("Source code available on %1").arg("<a href=\"https://launchpad.net/podbird\">launchpad.net</a>")
            onLinkActivated: Qt.openUrlExternally(link)
        }
    }
}
