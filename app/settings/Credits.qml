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
import Ubuntu.Components 1.2
import Ubuntu.Components.ListItems 1.0 as ListItem

Page {
    id: creditsPage

    title: i18n.tr("Credits")

    ListModel {
        id: creditsModel
        Component.onCompleted: initialize()
        function initialize() {
            // TRANSLATORS: The first argument is the name of creator of Podbird (Michael Sheldon)
            creditsModel.append({ name: i18n.tr("%1 (Creator)").arg("Michael Sheldon"), title: i18n.tr("Developers") })
            creditsModel.append({ name: "Nekhelesh Ramananthan", title: i18n.tr("Developers") })
            creditsModel.append({ name: "Kevin Feyder", title: i18n.tr("Designer") })
            creditsModel.append({ name: "Ubuntu Translators Community", title: i18n.tr("Translators") })
        }
    }

    UbuntuListView {
        id: credits

        model: creditsModel
        anchors.fill: parent

        section.property: "title"
        section.labelPositioning: ViewSection.InlineLabels
        section.delegate: ListItem.Header {
            text: section
        }

        // Required to accomodate the now playing bar being shown in landscape mode which
        // can hide a setting if not for this footer.
        footer: Item {
            width: parent.width
            height: units.gu(8)
        }

        delegate: ListItem.Standard {
            text: model.name
            showDivider: false
        }
    }
}
