/*
 * Copyright (C) 2013, 2014
 *      Andrew Hayzen <ahayzen@gmail.com>
 *      Daniel Holm <d.holmen@gmail.com>
 *      Victor Thompson <victor.thompson@gmail.com>
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
import Ubuntu.Components 1.3
import QtGraphicalEffects 1.0

// Blurred background
Item {
    width: parent.width

    property string art
    property real backgroundStrength: 0.4

    // the album art
    Image {
        id: backgroundImage
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        anchors.fill: parent
        source: art // this has to be fixed for the default cover art to work - cant find in this dir
        visible: false
    }

    // the blur
    FastBlur {
        id: backgroundBlur
        anchors.fill: backgroundImage
        source: backgroundImage
        radius: units.dp(30)
        opacity: backgroundStrength
    }
    onArtChanged: {
        // TODO: This is a work around for LP:1261078 and LP:1306845. Ideally,
        //       there should be a better way of getting the blur to repaint
        backgroundImage.source = art
        backgroundBlur.source = null
        backgroundBlur.source = backgroundImage
    }
}
