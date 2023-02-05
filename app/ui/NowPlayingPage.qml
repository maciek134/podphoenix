/*
 * Copyright 2015-2016 Podphoenix Team
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
import QtMultimedia 5.6
import Ubuntu.Components 1.3
import QtQuick.LocalStorage 2.0
import "../podcasts.js" as Podcasts
import "../components"

Page {
    id: nowPlayingPage

    visible: false

    property bool isNowPlayingPage: true

    header: PageHeader {
        title: i18n.tr("Now Playing")

        StyleHints {
            backgroundColor: podphoenix.appTheme.background
        }

        leadingActionBar.actions: Action {
            iconName: "back"
            text: i18n.tr("Back")
            onTriggered: {
                if (nowPlayingPageSections.selectedIndex === 1 && currentViewLoader.item.ViewItems.dragMode) {
                    currentViewLoader.item.ViewItems.dragMode = !currentViewLoader.item.ViewItems.dragMode
                } else {
                    mainStack.pop()
                }
            }
        }

        trailingActionBar.actions: Action {
            iconName: "delete"
            visible: nowPlayingPageSections.selectedIndex === 1
            onTriggered: {
                Podcasts.clearQueue()
                player.playlist.clear()
                mainStack.pop()
            }
        }

        extension: Sections {
            id: nowPlayingPageSections

            anchors {
                left: parent.left
                bottom: parent.bottom
            }

            StyleHints {
                selectedSectionColor: podphoenix.appTheme.focusText
            }
            model: [i18n.tr("Full view"), i18n.tr("Queue")]
        }
    }

    Loader {
        id: currentViewLoader
        anchors { fill: parent; topMargin: nowPlayingPage.header.height }
        source: nowPlayingPageSections.selectedIndex === 0 ? Qt.resolvedUrl("FullPlayingView.qml") : Qt.resolvedUrl("Queue.qml")
    }
}
