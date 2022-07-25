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

Item {
    id: customSectionHeader

    property alias title: headerText.text

    height: headerText.text !== "" ? headerText.implicitHeight + divider.height + headerText.anchors.topMargin + headerText.anchors.bottomMargin
                                   : units.gu(0)

    anchors { left: parent.left; right: parent.right; margins: units.gu(2) }

    Label {
        id: headerText
        color: podbird.appTheme.baseText
        font.weight: Font.DemiBold
        anchors { top: parent.top; topMargin: units.gu(2); bottom: parent.bottom; bottomMargin: units.gu(2) }
        width: parent.width
    }
    
    Rectangle {
        id: divider
        color: settings.themeName === "Dark.qml" ? "#888888" : "#cdcdcd"
        width: parent.width
        height: units.dp(1)
        anchors.bottom: parent.bottom
    }
}
