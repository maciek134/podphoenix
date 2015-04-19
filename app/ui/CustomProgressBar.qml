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

Rectangle {
    id: progressBar

    property alias progress: currentProgress.width
    property bool indeterminateProgress: false

    radius: width/3
    width: parent.width
    height: units.dp(5)
    color: Theme.palette.normal.base

    Rectangle {
        id: currentProgress

        height: parent.height
        radius: parent.radius
        anchors.left: parent.left
        anchors.top: parent.top
        color: podbird.theme.focusText
        
        SequentialAnimation {
            loops: Animation.Infinite
            running: indeterminateProgress

            onRunningChanged: {
                currentProgress.anchors.leftMargin = 0;
            }

            PropertyAnimation { target: currentProgress.anchors; property: "leftMargin"; from: 0.0; to: parent.width  - parent.width / 6 - units.gu(3); duration: UbuntuAnimation.SleepyDuration; easing.type:  Easing.InOutQuad; }
            PropertyAnimation { target: currentProgress.anchors; property: "leftMargin"; from: parent.width  - parent.width / 6 - units.gu(3); to: 0; duration: UbuntuAnimation.SleepyDuration; easing.type: Easing.InOutQuad; }
        }
    }
}
