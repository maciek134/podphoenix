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

import QtQuick 2.0
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.1
import QtQuick.LocalStorage 2.0
import Ubuntu.Components.ListItems 1.0 as ListItem
import "../podcasts.js" as Podcasts

Tab {
    title: i18n.tr("Search")

    property var xhr: new XMLHttpRequest;

    page: Page {
        Column {
            spacing: units.gu(2)
            anchors.fill: parent
            anchors.topMargin: units.gu(2)

            TextField {
                id: searchField
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: units.gu(2)
                placeholderText: i18n.tr("Search...")
                inputMethodHints: Qt.ImhNoPredictiveText;
                onTextChanged: {
                    if (text.length > 2) {
                        search(text)
                    } else {
                        searchResults.clear();
                    }
                }
            }

            ListView {
                clip: true
                width: parent.width
                model: searchResults
                height: parent.height - searchField.height - units.gu(2)

                footer: Item {
                    width: parent.width
                    height: units.gu(7)
                }

                delegate: ListItem.Empty {

                    height: units.gu(8)

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
                                fontSize: "small"
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
            }
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
                                             "image" : json.results[i].artworkUrl100});
                }
            }
        }
        xhr.send();
    }
}

