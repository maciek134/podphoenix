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

QtObject {
    // MainView
    property color background: "#ECECEC"

    // Main Text Colors
    property color baseText: UbuntuColors.darkGrey
    property color baseSubText: "#999999"
    property color focusText: UbuntuColors.blue
    property color linkText: "Blue"

    // Icon Colors
    property color baseIcon: UbuntuColors.darkGrey

    // Button Colors
    property color positiveActionButton: UbuntuColors.green
    property color negativeActionButton: UbuntuColors.red
    property color neutralActionButton: UbuntuColors.coolGrey

    // Bottom Player Bar Colors
    property color bottomBarBackground: "#323435"

    // Highlight Color
    property color hightlightListView: "#F5F5F5"
}
