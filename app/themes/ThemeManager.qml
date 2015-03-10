/*
 * Copyright 2015 Michael Hall <mhall119@ubuntu.com>
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

QtObject {
    id: themeManager
    property string name
    property var themeObject: new QtObject()

    onNameChanged: {
        var themeComponent = Qt.createComponent(Qt.resolvedUrl(name))
        if (themeComponent.status == Component.Ready) {
            var themeObject = themeComponent.createObject(themeManager)
            for (var key in themeObject) {
                if (themeManager.hasOwnProperty(key)) {
                    themeManager[key] = themeObject[key]
                }
            }
        }
    }

    // MainView
    property color background

    // Main Text Colors
    property color baseText
    property color baseSubText
    property color focusText

    // Icon Colors
    property color baseIcon

    // Button Colors
    property color positiveActionButton
    property color negativeActionButton
    property color neutralActionButton

    // Bottom Player Bar Colors
    property color bottomBarBackground

    // Highlight Color
    property color hightlightListView
}
