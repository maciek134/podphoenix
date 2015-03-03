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

import QtQuick 2.0
import Ubuntu.Components 1.1

QtObject {
    // MainView
    property color background: "#1E1E23"

    // Main Text Colors
    property color baseText: "White"
    property color baseSubText: "#999999"
    property color focusText: "#FF9900"

    // Icon Colors
    property color baseIcon: "White"

    // Button Colors
    property color positiveActionButton: UbuntuColors.green
    property color negativeActionButton: UbuntuColors.red
    property color neutralActionButton: UbuntuColors.coolGrey

    // Bottom Player Bar Colors
    property color bottomBarBackground: "#0F0F0F"

    // Highlight Color
    property color hightlightListView: "#2C2C34"
}
