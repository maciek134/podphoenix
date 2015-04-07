/*
 * Copyright (C) 2014-2015 Canonical Ltd
 *
 * This file is part of Ubuntu Clock App
 *
 * Ubuntu Clock App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * Ubuntu Clock App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.3
import Ubuntu.Components 1.1

/*
 Component which displays an empty state (approved by design). It offers an
 icon, title and subtitle to describe the empty state.
*/

Item {
    id: emptyState

    // Public APIs
    property alias iconName: emptyIcon.name
    property alias title: emptyLabel.text
    property alias subTitle: emptySublabel.text
    property alias iconSource: emptyIcon.source

    property real iconHeight: units.gu(10)
    property real iconWidth: units.gu(10)

    height: childrenRect.height
    width: parent.width

    Icon {
        id: emptyIcon
        width: parent.iconWidth
        height: parent.iconHeight
        color: podbird.theme.baseIcon
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Label {
        id: emptyLabel
        anchors.top: emptyIcon.bottom
        anchors.topMargin: units.gu(5)
        anchors.horizontalCenter: parent.horizontalCenter
        fontSize: "large"
        color: podbird.theme.baseText
    }

    Label {
        id: emptySublabel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: emptyLabel.bottom
        color: podbird.theme.baseSubText
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
    }
}
