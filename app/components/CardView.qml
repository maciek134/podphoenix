/*
 * Copyright (C) 2014
 *      Andrew Hayzen <ahayzen@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Ubuntu.Components 1.2

Flickable {
    id: cardViewFlickable
    anchors {
        fill: parent
        margins: units.gu(1)
    }

    // dont use flow.contentHeight as it is inaccurate due to height of labels
    // changing as they load
    contentHeight: flow.contentHeight + flow.anchors.margins * 2 + units.gu(8)
    contentWidth: width

    property alias count: flow.count
    property alias delegate: flow.delegate
    property var getter
    property alias model: flow.model
    property real itemWidth: units.gu(15)

    onGetterChanged: flow.getter = getter  // cannot use alias to set a function (must be var)

    ColumnFlow {
        id: flow
        anchors.fill: parent
        columns: parseInt(cardViewFlickable.width / itemWidth) || 1  // never drop to 0
        flickable: cardViewFlickable
    }

    Component.onCompleted: {
        // FIXME: workaround for qtubuntu not returning values depending on the grid unit definition
        // for Flickable.maximumFlickVelocity and Flickable.flickDeceleration
        var scaleFactor = units.gridUnit / 8;
        maximumFlickVelocity = maximumFlickVelocity * scaleFactor;
        flickDeceleration = flickDeceleration * scaleFactor;
    }
}
