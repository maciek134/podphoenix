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

import QtQuick 2.4
import Ubuntu.Components 1.3

QtObject {
    id: themeManager

    property QtObject theme
    property string source

    onSourceChanged: {
        var themeComponent = Qt.createComponent(source)
        if (themeComponent.status == Component.Ready) {
            themeManager.theme = themeComponent.createObject(themeManager)
        }
    }
}
