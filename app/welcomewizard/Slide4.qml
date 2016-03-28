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

// Slide 4
Component {
    id: slide4
    Item {
        id: slide1Container

        Image {
            anchors {
                top: parent.top
                bottom: introductionText.top
                bottomMargin: units.gu(6)
                horizontalCenter: parent.horizontalCenter
            }
            fillMode: Image.PreserveAspectFit
            source: Qt.resolvedUrl("../graphics/language.png")
        }

        Label {
            id: introductionText
            anchors.centerIn: parent
            elide: Text.ElideRight
            textSize: Label.XLarge
            maximumLineCount: 2
            // TRANSLATORS: This text should be in a language different from the language set by the user.
            // For instance, if the app was in english, then it is appropriate to set this string as
            // Hallo or Bonjour etc to symbolize the internationalization feature in podbird.
            text: i18n.tr("Hallo! Bonjour!")
            horizontalAlignment: Text.AlignHCenter
            width: parent.width
            wrapMode: Text.WordWrap
        }

        Label {
            id: finalMessage
            anchors {
                top: introductionText.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                margins: units.gu(1)
                topMargin: units.gu(4)
            }
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            linkColor: podbird.appTheme.linkText
            text: i18n.tr("Podbird is available in over 15 languages and is translated by the %1 community").arg("<a href=\"http://community.ubuntu.com/contribute/translations\">Ubuntu Translators</a>")
            onLinkActivated: Qt.openUrlExternally(link)
        }
    }
}
