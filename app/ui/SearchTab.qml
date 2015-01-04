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
import Ubuntu.Components 1.1
import Ubuntu.DownloadManager 0.1
import QtQuick.LocalStorage 2.0
import "../podcasts.js" as Podcasts

Tab {
    title: i18n.tr("Search")

    property var xhr: new XMLHttpRequest;

    page: Page {
        Column {
            spacing: units.gu(2)
            anchors.fill: parent
            anchors.margins: units.gu(2)

            TextField {
                id: searchField
                width: parent.width
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
                width: parent.width
                model: searchResults
                height: parent.height - searchField.height - units.gu(4)
                clip: true
                spacing: units.gu(1)
                footer: Item {
                    width: parent.width
                    height: units.gu(7)
                }

                delegate: Item {

                    height: imgFrame.height
                    width: parent.width

                    UbuntuShape {
                        id: imgFrame
                        width: units.gu(9.1)
                        height: width

                        anchors.left: parent.left
                        image: Image {
                            source: model.image
                        }
                    }

                    Column {
                        anchors.left: imgFrame.right
                        anchors.leftMargin: units.gu(2)
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(2)
                        spacing: units.gu(0.5)

                        Label {
                            text: model.name
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Label {
                            text: model.artist
                            width: parent.width
                            elide: Text.ElideRight
                            fontSize: "small"
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

    SingleDownload {
        id: imageDownloader
        property string feed;
        onFinished: {
            var db = Podcasts.init();
            var finalLocation = fileManager.saveDownload(path);
            db.transaction(function (tx) {
                tx.executeSql("UPDATE Podcast SET image=? WHERE feed=?", [finalLocation, feed]);
            });
        }
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

