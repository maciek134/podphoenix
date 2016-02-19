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
import Ubuntu.Components 1.3

ListItem {
    id: subtitledListItem

    property alias title: _title.text
    property alias subtitle: _subtitle.text
    property bool progression: true

    height: Math.max(mainColumn.height + units.gu(2), units.gu(6))
    divider.visible: false

    Column {
        id: mainColumn

        anchors {
            left: parent.left
            leftMargin: units.gu(2)
            right: progression ? nextIcon.left : parent.right
            rightMargin: progression ? units.gu(1) : units.gu(2)
            verticalCenter: parent.verticalCenter
        }

        Label {
            id: _title
            width: parent.width
            wrapMode: Text.WordWrap
        }
        
        Label {
            id: _subtitle
            fontSize: "small"
            color: podbird.appTheme.baseSubText
            width: parent.width
            visible: text !== ""
            wrapMode: Text.WordWrap
        }
    }

    Icon {
        id: nextIcon
        visible: progression
        height: units.gu(2)
        width: height
        anchors.right: parent.right
        anchors.rightMargin: units.gu(2)
        anchors.verticalCenter: parent.verticalCenter
        name: "next"
    }
}
