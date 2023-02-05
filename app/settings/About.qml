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
import Ubuntu.Components 1.3

Page {
    id: aboutPage

    header: PageHeader {
        id: aboutPageHeader

        title: i18n.tr("About")

        StyleHints {
            backgroundColor: podphoenix.appTheme.background
        }

        extension: Sections {
            id: aboutPageHeaderSections

            anchors {
                left: parent.left
                bottom: parent.bottom
            }

            StyleHints {
                selectedSectionColor: podphoenix.appTheme.focusText
            }
            // TRANSTORS: Credits as in the code and design contributors to the app
            model: [i18n.tr("About"), i18n.tr("Credits")]
        }
    }


    VisualItemModel {
        id: tabs

        Item {
            width: tabView.width
            height: tabView.height

            Flickable {
                id: flickable

                anchors.fill: parent
                contentHeight: dataColumn.height + units.gu(10) + dataColumn.anchors.topMargin

                Column {
                    id: dataColumn

                    spacing: units.gu(3)
                    anchors {
                        top: parent.top; left: parent.left; right: parent.right; topMargin: units.gu(5)
                    }

                    Image {
                        height: width
                        width: Math.min(parent.width/2, parent.height/2)
                        source: "../graphics/logo.png"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Column {
                        width: parent.width
                        Label {
                            width: parent.width
                            textSize: Label.XLarge
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignHCenter
                            text: "Podphoenix"
                        }
                        Label {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            // TRANSLATORS: Podphoenix version number e.g Version 0.8
                            text: i18n.tr("Version %1").arg("0.8")
                        }
                    }

                    Column {
                        anchors {
                            left: parent.left
                            right: parent.right
                            margins: units.gu(2)
                        }
                        Label {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                            text: "(C) 2015 Podphoenix Team"
                        }
                        Label {
                            textSize: Label.Small
                            width: parent.width
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                            text: i18n.tr("Released under the terms of the GNU GPL v3")
                        }
                    }

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        textSize: Label.Small
                        horizontalAlignment: Text.AlignHCenter
                        linkColor: podphoenix.appTheme.linkText
                        text: i18n.tr("Source code available on %1").arg("<a href=\"https://launchpad.net/podphoenix\">launchpad.net</a>")
                        onLinkActivated: Qt.openUrlExternally(link)
                    }
                }
            }
        }

        Credits {
            width: tabView.width
            height: tabView.height
        }
    }

    ListView {
        id: tabView
        model: tabs
        interactive: false

        anchors {
            top: aboutPageHeader.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        orientation: Qt.Horizontal
        snapMode: ListView.SnapOneItem
        currentIndex: aboutPageHeaderSections.selectedIndex
        highlightMoveDuration: UbuntuAnimation.SlowDuration
    }
}
