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

ListItem {
    id: headerListItem

    property alias title: headerText.title

    height: headerText.height + divider.height
    divider.anchors.leftMargin: units.gu(2)
    divider.anchors.rightMargin: units.gu(2)

    ListItemLayout {
        id: headerText
        title.text: " "
        title.color: podphoenix.appTheme.baseText
        title.font.weight: Font.DemiBold
    }
}
