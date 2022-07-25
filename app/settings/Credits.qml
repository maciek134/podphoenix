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
import "../components"

Item {
    id: creditsPage

    ListModel {
        id: creditsModel
        Component.onCompleted: initialize()
        function initialize() {
            // TRANSLATORS: The first argument is the name of creator of Podbird (Michael Sheldon)
            creditsModel.append({ name: i18n.tr("%1 (Creator)").arg("Michael Sheldon"), title: i18n.tr("Developers"), url: "http://blog.mikeasoft.com" })
            creditsModel.append({ name: "Nekhelesh Ramananthan", title: i18n.tr("Developers"), url: "https://launchpad.net/~nik90" })
            creditsModel.append({ name: "Kevin Feyder", title: i18n.tr("Designer"), url: "https://feyder.design/" })
            creditsModel.append({ name: "Ubuntu Translators Community", title: i18n.tr("Translators"), url: "https://discourse.ubuntu.com/t/translations/32" })
        }
    }

    UbuntuListView {
        id: credits

        currentIndex: -1
        model: creditsModel
        anchors.fill: parent

        section.property: "title"
        section.labelPositioning: ViewSection.InlineLabels
        section.delegate: HeaderListItem {
            title.text: section
        }

        // Required to accomodate the now playing bar being shown in landscape mode which
        // can hide a setting if not for this footer.
        footer: Item {
            width: parent.width
            height: units.gu(8)
        }

        delegate: ListItem {
            ListItemLayout {
                title.text: model.name
                title.color: podbird.appTheme.baseText
                ProgressionSlot {}
            }
            divider.visible: false
            onClicked: Qt.openUrlExternally(model.url)
        }
    }
}
