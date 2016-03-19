/*
 * Copyright 2015-2016 Podbird Team
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

ListItem {
    id: customListItem

    property alias title: customItemLayout.title
    property alias value: _value.text

    divider.anchors.leftMargin: units.gu(2)
    divider.anchors.rightMargin: units.gu(2)

    ListItemLayout {
        id: customItemLayout

        title.text: " "
        title.color: podbird.appTheme.baseText

        Label {
            id: _value
            color: podbird.appTheme.baseText
            SlotsLayout.position: SlotsLayout.Trailing;
        }

        ProgressionSlot {}
    }
}
