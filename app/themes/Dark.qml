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

QtObject {
    // MainView
    property color background: "#000000"

    // Main Text Colors
    property color baseText: "White"
    property color baseSubText: "#999999"
    property color focusText: UbuntuColors.red
    property color linkText: "Red"

    // Icon Colors
    property color baseIcon: "White"

    // Button Colors
    property color positiveActionButton: UbuntuColors.green
    property color negativeActionButton: UbuntuColors.red
    property color neutralActionButton: UbuntuColors.coolGrey

    // Bottom Player Bar Colors
    property color bottomBarBackground: "#15141A"

    // Highlight Color
    property color hightlightListView: "#2D2D2C"
}
