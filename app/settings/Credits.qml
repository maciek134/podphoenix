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
import Ubuntu.Components.ListItems 1.0 as ListItem

Page {
    id: creditsPage

    title: i18n.tr("Credits")

    Flickable {
        id: flickable

        anchors.topMargin: units.gu(1)
        anchors.fill: parent
        contentHeight: dataColumn.height + units.gu(8)

        Column {
            id: dataColumn

            anchors { top: parent.top; left: parent.left; right: parent.right }

            ListItem.Header {
                text: i18n.tr("Developers")
            }

            ListItem.Standard {
                showDivider: false
                // TRANSLATORS: The first argument is the name of creator of Podbird (Michael Sheldon)
                text: i18n.tr("%1 (Creator)").arg("Michael Sheldon")
            }

            ListItem.Standard {
                showDivider: false
                text: "Nekhelesh Ramananthan"
            }

            ListItem.Header {
                text: i18n.tr("Designer")
            }

            ListItem.Standard {
                showDivider: false
                text: "Kevin Feyder"
            }

            ListItem.Header {
                text: i18n.tr("Translators")
            }

            ListItem.Standard {
                showDivider: false
                text: "Ubuntu Translators Team"
            }
        }
    }
}
