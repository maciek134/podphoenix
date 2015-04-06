/*
 * Copyright 2015 Michael Sheldon <mike@mikeasoft.com>
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
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.1
import QtQuick.LocalStorage 2.0
import Ubuntu.Components.ListItems 1.0 as ListItem
import "../podcasts.js" as Podcasts

Page {
    id: searchPage

    property var xhr: new XMLHttpRequest;

    /*
         #FIXME: The following lines of code is necessary due to a upstream bug
         in the SDK http://pad.lv/1400297. This bug is still present in the rtm.
         Once it is fixed, this following property and connection can be remvoed.
        */
    property Item __oldContents: null
    Connections {
        target: searchPage.head
        onContentsChanged: {
            if (searchPage.__oldContents) {
                searchPage.__oldContents.parent = null;
            }
            searchPage.__oldContents = searchPage.head.contents;
        }
    }

    state: "default"
    states: [
        PageHeadState {
            name: "default"
            head: searchPage.head
            actions: [
                Action {
                    iconName: "search"
                    text: i18n.tr("Search Episode")
                    onTriggered: {
                        searchPage.state = "search"
                        searchField.forceActiveFocus()
                    }
                }
            ]
        },

        PageHeadState {
            name: "search"
            head: searchPage.head
            backAction: Action {
                iconName: "back"
                text: i18n.tr("Back")
                onTriggered: {
                    resultsView.forceActiveFocus()
                    searchField.text = ""
                    searchPage.state = "default"
                }
            }

            contents: TextField {
                id: searchField
                inputMethodHints: Qt.ImhNoPredictiveText
                placeholderText: i18n.tr("Search...")
                anchors.left: parent ? parent.left : undefined
                anchors.right: parent ? parent.right : undefined
                anchors.rightMargin: units.gu(2)
                onTextChanged: {
                    if (text.length > 2) {
                        search(text)
                    } else {
                        searchResults.clear();
                    }
                }
            }
        }
    ]

    EmptyState {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: Qt.inputMethod.visible ? units.gu(4) : 0
        visible: searchResults.count === 0
        iconName: "search"
        title: searchPage.state !== "search" ? i18n.tr("Looking for a new Podcast?") : i18n.tr("No Podcasts found")
        subTitle: searchPage.state !== "search" ? i18n.tr("Click the 'magnifier' at the top to search.") : i18n.tr("No podcasts found matching the search term.")
    }

    ListView {
        id: resultsView

        clip: true
        model: searchResults
        anchors.fill: parent

        footer: Item {
            width: parent.width
            height: units.gu(7)
        }

        delegate: ListItem.Empty {
            id: listItem

            height: units.gu(8)
            showDivider: false
            highlightWhenPressed: false

            Rectangle {
                anchors.fill: parent
                opacity: 0.3
                color: index % 2 === 0 ? podbird.theme.hightlightListView : "Transparent"
            }

            RowLayout {
                id: titleRow

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: units.gu(2)
                anchors.verticalCenter: parent.verticalCenter

                spacing: units.gu(2)

                Image {
                    id: imgFrame
                    width: units.gu(6)
                    height: width
                    sourceSize.height: width
                    sourceSize.width: width
                    source: model.image
                }

                Column {
                    id: detailColumn

                    anchors.verticalCenter: imgFrame.verticalCenter
                    Layout.fillWidth: true

                    Label {
                        id: podcastTitle
                        textFormat: Text.PlainText
                        text: model.name
                        width: parent.width
                        fontSize: "medium"
                        elide: Text.ElideRight
                    }

                    Label {
                        id: episodeCount
                        width: parent.width
                        color: "#999999"
                        text: model.artist
                        fontSize: "x-small"
                        elide: Text.ElideRight
                    }
                }

                Button {
                    anchors.right: parent.right
                    text: i18n.tr("Subscribe")
                    color: UbuntuColors.green
                    onClicked: {
                        Podcasts.subscribe(model.artist, model.name, model.feed, model.image);
                        imageDownloader.feed = model.feed;
                        imageDownloader.download(model.image);
                        tabs.selectedTabIndex = 0;
                        searchField.text = ""
                    }
                }
            }
        }

        Scrollbar {
            flickableItem: resultsView
        }

    }

    ListModel {
        id: searchResults
    }

    function search(term) {
        var url = "https://itunes.apple.com/search?term=" + term + "&media=podcast&entity=podcast"
        xhr.open("GET", url);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                searchResults.clear();
                var json = JSON.parse(xhr.responseText);
                for(var i in json.results) {
                    searchResults.append({"name" : json.results[i].trackName,
                                             "artist" : json.results[i].artistName,
                                             "feed" : json.results[i].feedUrl,
                                             "image" : json.results[i].artworkUrl600});
                }
            }
        }
        xhr.send();
    }
}

