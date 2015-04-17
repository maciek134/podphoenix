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
import Ubuntu.Components.Popups 1.0
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
                },

                Action {
                    text: i18n.tr("Add Podcast")
                    iconName: "add"
                    onTriggered: {
                        searchPage.state = "add"
                        feedUrlField.forceActiveFocus()
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
        },

        PageHeadState {
            name: "add"
            head: searchPage.head
            backAction: Action {
                iconName: "back"
                text: i18n.tr("Back")
                onTriggered: {
                    resultsView.forceActiveFocus()
                    feedUrlField.text = ""
                    searchPage.state = "default"
                }
            }

            actions: [
                Action {
                    iconName: "ok"
                    text: i18n.tr("Save Podcast")
                    onTriggered: {
                        resultsView.forceActiveFocus()
                        subscribeFromFeed(feedUrlField.text);
                    }
                }
            ]

            contents: TextField {
                id: feedUrlField
                inputMethodHints: Qt.ImhUrlCharactersOnly
                placeholderText: i18n.tr("Feed URL")
                anchors.left: parent ? parent.left : undefined
                anchors.right: parent ? parent.right : undefined
                onAccepted: {
                    resultsView.forceActiveFocus()
                    subscribeFromFeed(feedUrlField.text);
                }
            }
        }
    ]

    Component {
        id: subscribeFailedDialog
        Dialog {
            id: dialogInternal
            title: i18n.tr("Unable to subscribe")
            text: i18n.tr("Please check the URL and try again")
            Button {
                text: i18n.tr("Close")
                color: podbird.theme.neutralActionButton
                onClicked: {
                    PopupUtils.close(dialogInternal)
                }
            }
        }
    }

    EmptyState {
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: Qt.inputMethod.visible ? units.gu(4) : 0
        iconHeight: units.gu(12)
        iconWidth: iconHeight + units.gu(10)
        visible: searchPage.state !== "search" && searchPage.state !== "add" ? true : searchResults.count === 0 && searchField.text.length > 2
        iconSource: searchPage.state !== "search" ? Qt.resolvedUrl("../graphics/owlSearch.svg") : Qt.resolvedUrl("../graphics/notFound.svg")
        title: searchPage.state !== "search" ? i18n.tr("Looking to add a new Podcast?") : i18n.tr("No Podcasts found")
        subTitle: searchPage.state !== "search" ? i18n.tr("Click the 'magnifier' at the top to search or the 'plus' button to add by URL") : i18n.tr("No podcasts found matching the search term.")
    }

    ListView {
        id: resultsView

        Component.onCompleted: {
            // FIXME: workaround for qtubuntu not returning values depending on the grid unit definition
            // for Flickable.maximumFlickVelocity and Flickable.flickDeceleration
            var scaleFactor = units.gridUnit / 8;
            maximumFlickVelocity = maximumFlickVelocity * scaleFactor;
            flickDeceleration = flickDeceleration * scaleFactor;
        }

        model: searchResults
        anchors.fill: parent
        visible: searchPage.state !== "add"

        footer: Item {
            width: parent.width
            height: units.gu(7)
        }

        delegate: ListItem.Empty {
            id: listItem

            property bool expanded: false
            property bool fetchedDescription: false

            height: dataColumn.height + units.gu(2)
            showDivider: false
            highlightWhenPressed: false

            onClicked: {
                expanded = !expanded;
                if (expanded && !fetchedDescription) {
                    getPodcastDescription(model.feed, index)
                    fetchedDescription = true
                }
            }

            Rectangle {
                anchors.fill: parent
                opacity: 0.3
                color: index % 2 === 0 ? podbird.theme.hightlightListView : "Transparent"
            }

            Column {
                id: dataColumn

                spacing: units.gu(1)
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: units.gu(2)
                anchors.top: parent.top
                anchors.topMargin: units.gu(1)

                RowLayout {
                    id: titleRow

                    width: parent.width
                    height: imgFrame.height

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
                        text: !model.subscribed ? i18n.tr("Subscribe") : i18n.tr("Unsubscribe")
                        color: !model.subscribed ? UbuntuColors.green : UbuntuColors.red
                        onClicked: {
                            if (!model.subscribed) {
                                Podcasts.subscribe(model.artist, model.name, model.feed, model.image);
                                imageDownloader.feed = model.feed;
                                imageDownloader.download(model.image);
                            } else {
                                var db = Podcasts.init();
                                db.transaction(function (tx) {
                                    var rs = tx.executeSql("SELECT rowid FROM Podcast WHERE feed = ?", model.feed);
                                    if (rs.rows.length !== 0) {
                                        var podcast = rs.rows.item(0)
                                        var rs2 = tx.executeSql("SELECT downloadedfile FROM Episode WHERE downloadedfile NOT NULL AND podcast=?", [podcast.rowid]);
                                        for(var i = 0; i < rs2.rows.length; i++) {
                                            fileManager.deleteFile(rs2.rows.item(i).downloadedfile);
                                        }
                                        tx.executeSql("DELETE FROM Episode WHERE podcast=?", [podcast.rowid]);
                                        tx.executeSql("DELETE FROM Podcast WHERE rowid=?", [podcast.rowid]);
                                    }
                                });
                            }
                            tabs.selectedTabIndex = 1;
                            searchField.text = ""
                        }
                    }
                }

                Label {
                    id: desc
                    clip: true
                    text: i18n.tr("Last Updated: %1\n%2").arg(model.releaseDate.split("T")[0]).arg(model.description)
                    height: listItem.expanded ? contentHeight : 0
                    wrapMode: Text.WordWrap
                    width: parent.width
                    fontSize: "small"
                    color: podbird.theme.baseSubText
                    Behavior on height {
                        UbuntuNumberAnimation {
                            duration: UbuntuAnimation.BriskDuration
                        }
                    }
                }
            }
        }

        // #FIXME: Use SDK Scrollbar when it is themeable
        CustomScrollBar {
            listview: resultsView
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
                var db = Podcasts.init();

                for(var i in json.results) {

                    var subscribed = false
                    db.transaction(function (tx) {
                        var rs = tx.executeSql("SELECT rowid, * FROM Podcast ORDER BY name ASC");
                        for(var j = 0; j < rs.rows.length; j++) {
                            var podcast = rs.rows.item(j);
                            if (podcast.name == json.results[i].trackName) {
                                subscribed = true
                                break
                            }
                        }
                    });

                    searchResults.append({"name" : json.results[i].trackName,
                                             "artist" : json.results[i].artistName,
                                             "feed" : json.results[i].feedUrl,
                                             "image" : json.results[i].artworkUrl600,
                                             "releaseDate": json.results[i].releaseDate,
                                             "description": i18n.tr("Not Available"),
                                             "subscribed": subscribed});
                }
            }
        }
        xhr.send();
    }

    function getPodcastDescription(feedUrl, index) {
        var description = ""
        var xhr = new XMLHttpRequest;
        xhr.open("GET", feedUrl);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var e = xhr.responseXML.documentElement;
                for(var h = 0; h < e.childNodes.length; h++) {
                    if(e.childNodes[h].nodeName === "channel") {
                        var c = e.childNodes[h];
                        for(var j = 0; j < c.childNodes.length; j++) {
                            if (c.childNodes[j].nodeName === "description") {
                                description = c.childNodes[j].childNodes[0].nodeValue
                                if (description != undefined) {
                                    console.log(description)
                                    searchResults.setProperty(index, "description", description)
                                    return
                                }
                            }
                        }
                    }
                }
            }
        }
        xhr.send();
    }

    function subscribeFromFeed(feed) {
        var xhr = new XMLHttpRequest;
        if (feed.indexOf("://") === -1) {
            feed = "http://" + feed;
        }
        xhr.open("GET", feed);
        xhr.onreadystatechange = function() {
            var name = "";
            var artist = "";
            var image = "";
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status < 200 || xhr.status > 299 || xhr.responseXML === null) {
                    PopupUtils.open(subscribeFailedDialog);
                    feedUrlField.text = feed
                    searchPage.state = "add"
                    return;
                }

                var e = xhr.responseXML.documentElement;
                for(var h = 0; h < e.childNodes.length; h++) {
                    if(e.childNodes[h].nodeName === "channel") {
                        var c = e.childNodes[h];
                        for(var j = 0; j < c.childNodes.length; j++) {
                            var nodeName = c.childNodes[j].nodeName;
                            if (nodeName === "title")               name = c.childNodes[j].childNodes[0].nodeValue;
                            else if (nodeName === "author")         artist = c.childNodes[j].childNodes[0].nodeValue;
                            else if (nodeName === "image") {
                                var el = c.childNodes[j];
                                for (var l = 0; l < el.attributes.length; l++) {
                                    if(el.attributes[l].nodeName === "href")         image = el.attributes[l].nodeValue;
                                }
                            }
                        }
                    }
                }

                if(name != "") {
                    Podcasts.subscribe(artist, name, feed, image);
                    imageDownloader.feed = feed;
                    imageDownloader.download(image);
                    tabs.selectedTabIndex = 1;
                } else {
                    PopupUtils.open(subscribeFailedDialog);
                    feedUrlField.text = feed
                    searchPage.state = "add"
                    return;
                }
            }
        }
        xhr.send();
    }
}

