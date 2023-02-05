/*
 * Copyright 2015-2016 Michael Sheldon <mike@mikeasoft.com>
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
import QtQuick.LocalStorage 2.0
import QtQuick.XmlListModel 2.0
import Ubuntu.Components.Popups 1.3
import Ubuntu.Content 1.3
import "../podcasts.js" as Podcasts
import "../components"

Page {
    id: searchPage

    property var xhr: new XMLHttpRequest;

    TabsList {
        id: tabsList
    }

    header: standardHeader

    PageHeader {
        id: standardHeader

        visible: searchPage.header === standardHeader
        title: i18n.tr("Add New Podcasts")

        StyleHints {
            backgroundColor: podphoenix.appTheme.background
        }

        leadingActionBar {
            numberOfSlots: 0
            actions: tabsList.actions
        }

        trailingActionBar.actions: [
            Action {
                iconName: "search"
                text: i18n.tr("Search Podcast")
                onTriggered: {
                    searchPage.header = searchHeader
                    searchField.item.forceActiveFocus()
                }
            },

            Action {
                text: i18n.tr("Add Podcast")
                iconName: "add"
                onTriggered: {
                    searchPage.header = addHeader
                    feedUrlField.item.forceActiveFocus()
                }
            },
            Action {
                text:i18n.tr("Import Podcasts")
                iconName: "import"
                onTriggered: {
                    var importPage = mainStack.push(Qt.resolvedUrl("ImportPage.qml"),{"contentType": ContentType.Unknown, "handler": ContentHandler.Source})
                    importPage.imported.connect(function(fileUrl) {
                        mainStack.pop()
                        parseOPML(fileUrl)
                    })
                }
            }
        ]
    }

    PageHeader {
        id: searchHeader

        visible: searchPage.header === searchHeader

        StyleHints {
            backgroundColor: podphoenix.appTheme.background
        }

        contents: Loader {
            id: searchField
            sourceComponent: searchPage.header === searchHeader ? searchFieldComponent : undefined
            anchors.left: parent ? parent.left : undefined
            anchors.right: parent ? parent.right : undefined
            anchors.verticalCenter: parent.verticalCenter
        }

        leadingActionBar.actions: [
            Action {
                iconName: "back"
                onTriggered: {
                    resultsView.forceActiveFocus()
                    searchResults.clear()
                    searchPage.header = standardHeader
                }
            }
        ]
    }

    PageHeader {
        id: addHeader

        visible: searchPage.header === addHeader

        StyleHints {
            backgroundColor: podphoenix.appTheme.background
        }

        contents: Loader {
            id: feedUrlField
            sourceComponent: searchPage.header === addHeader ? feedUrlComponent : undefined
            anchors.left: parent ? parent.left : undefined
            anchors.right: parent ? parent.right : undefined
            anchors.verticalCenter: parent.verticalCenter
        }

        trailingActionBar.actions: [
            Action {
                iconName: "ok"
                text: i18n.tr("Save Podcast")
                onTriggered: {
                    resultsView.forceActiveFocus()
                    subscribeFromFeed(feedUrlField.item.text);
                }
            },
            Action {
                iconName: "edit-clear"
                text: i18n.tr("Cancel")
                onTriggered: {
                    resultsView.forceActiveFocus()
                    searchPage.header = standardHeader
                }
            }
        ]
    }

    onVisibleChanged: {
        if(!visible) {
            searchPage.header = standardHeader;
        }
    }

    Component {
        id: feedUrlComponent
        TextField {
            inputMethodHints: Qt.ImhUrlCharactersOnly | Qt.ImhNoPredictiveText
            placeholderText: i18n.tr("Feed URL")
            onAccepted: {
                resultsView.forceActiveFocus()
                subscribeFromFeed(feedUrlField.item.text);
            }
        }
    }

    Component {
        id: searchFieldComponent
        TextField {
            inputMethodHints: Qt.ImhNoPredictiveText
            placeholderText: i18n.tr("Search Podcast")
            onTextChanged: {
                if (text.length > 2) {
                    search(text)
                } else {
                    searchResults.clear();
                }
            }
        }
    }

    Component {
        id: subscribeFailedDialog
        Dialog {
            id: dialogInternal
            title: i18n.tr("Unable to subscribe")
            text: i18n.tr("Please check the URL and try again")
            Button {
                text: i18n.tr("Close")
                color: podphoenix.appTheme.neutralActionButton
                onClicked: {
                    PopupUtils.close(dialogInternal)
                }
            }
        }
    }

    Loader {
        id: emptyState

        anchors {
            left: parent.left
            right: parent.right
            margins: units.gu(2)
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: Qt.inputMethod.visible ? units.gu(4) : 0
        }

        sourceComponent: searchPage.header === standardHeader ? emptyStateComponent : searchResults.count === 0 && searchPage.header === searchHeader ? emptyStateComponent
                                                                                                                                                      : undefined
    }

    Component {
        id: emptyStateComponent
        EmptyState {
            icon.source: searchPage.header !== searchHeader ? Qt.resolvedUrl("../graphics/owlSearch.svg") : Qt.resolvedUrl("../graphics/notFound.svg")
            title: searchPage.header !== searchHeader ? i18n.tr("Looking to add a new podcast?") : i18n.tr("No Podcasts Found")
            subTitle: searchPage.header !== searchHeader ? i18n.tr("Click the 'magnifier' at the top to search or the 'plus' button to add by URL")
                                                         : i18n.tr("No podcasts found matching the search term.")
        }
    }

    UbuntuListView {
        id: resultsView

        Component.onCompleted: {
            // FIXME: workaround for qtubuntu not returning values depending on the grid unit definition
            // for Flickable.maximumFlickVelocity and Flickable.flickDeceleration
            var scaleFactor = units.gridUnit / 8;
            maximumFlickVelocity = maximumFlickVelocity * scaleFactor;
            flickDeceleration = flickDeceleration * scaleFactor;
        }

        model: searchResults
        currentIndex: -1

        anchors {
            top: searchPage.header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        clip: true
        visible: searchPage.header !== addHeader

        footer: Item {
            width: parent.width
            height: units.gu(7)
        }

        delegate: ListItem {
            id: listItem

            property bool fetchedDescription: false
            property bool expanded: false

            divider.visible: false
            highlightColor: "Transparent"
            height: expanded ? listItemLayout.height +  descriptionLoader.height + units.gu(1) : listItemLayout.height + units.gu(0.5)
            color: index % 2 === 0 ? podphoenix.appTheme.hightlightListView : "Transparent"

            ListItemLayout {
                id: listItemLayout

                title.text: model.name

                subtitle.text: model.artist
                subtitle.color: podphoenix.appTheme.baseSubText

                padding.top: units.gu(1)
                padding.bottom: units.gu(0.5)

                Image {
                    height: width
                    width: units.gu(6)
                    source: model.image
                    SlotsLayout.position: SlotsLayout.Leading
                    sourceSize { width: width; height: height }
                }

                Button {
                    SlotsLayout.position: SlotsLayout.Trailing
                    color: !model.subscribed ? UbuntuColors.green : UbuntuColors.red
                    text: !model.subscribed ? i18n.tr("Subscribe") : i18n.tr("Unsubscribe")
                    onClicked: {
                        if (!model.subscribed) {
                            Podcasts.subscribe(model.artist, model.name, model.feed, model.image);
                            imageDownloader.addDownload(model.feed, model.image)
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
                        model.subscribed=!model.subscribed;
                    }
                }
            }

            Loader {
                id: descriptionLoader
                anchors { top: listItemLayout.bottom; left: parent.left; right: parent.right; leftMargin: units.gu(2); rightMargin: units.gu(2) }
                visible: sourceComponent !== undefined
                sourceComponent: expanded ? _description : undefined
            }

            Component {
                id: _description
                Label {
                    clip: true
                    // TRANSLATORS: The first argument here is the date of when the podcast was last updated followed by
                    // the podcast description.
                    text: i18n.tr("Last Updated: %1\n%2").arg(model.releaseDate.split("T")[0]).arg(model.description)
                    wrapMode: Text.WordWrap
                    textSize: Label.Small
                    color: podphoenix.appTheme.baseSubText
                    linkColor: podphoenix.appTheme.linkText
                    height: expanded ? contentHeight : 0
                    onLinkActivated: Qt.openUrlExternally(link)
                    Behavior on height {
                        UbuntuNumberAnimation {
                            duration: UbuntuAnimation.BriskDuration
                        }
                    }
                }
            }

            onClicked: {
                expanded = !expanded
                if (expanded && !fetchedDescription) {
                    getPodcastDescription(model.feed, index)
                    fetchedDescription = true
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
                if(loadingDialog)
                    progressBar.value++
                if (xhr.status < 200 || xhr.status > 299 || xhr.responseXML === null) {
                    PopupUtils.open(subscribeFailedDialog);
                    searchPage.header = addHeader
                    feedUrlField.item.text = feed
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
                    imageDownloader.addDownload(feed, image);
                    if (!loadingDialog)
                        tabs.selectedTabIndex = 2;
                } else {
                    PopupUtils.open(subscribeFailedDialog);
                    searchPage.header = addHeader
                    feedUrlField.item.text = feed
                    return;
                }
            }
        }
        xhr.send();
    }

    function parseOPML(fileUrl) {
        opmlModel.source = fileUrl;
        opmlModel.reload()
    }

    XmlListModel {
        id:opmlModel

        query: "/opml/body/outline"
        XmlRole { name: "text"; query: "@text/string()" }
        XmlRole { name: "type"; query: "@type/string()" }
        XmlRole { name: "xmlUrl"; query: "@xmlUrl/string()" }

        onRowsInserted: {
            progressBar.minimumValue = first
            progressBar.maximumValue = last
            progressBar.value = first
            loadingDialog.show()
            for(var i=first;i<=last;i++){
                subscribeFromFeed(opmlModel.get(i).xmlUrl)
            }
        }
    }

    Dialog {
        id: loadingDialog

        modal: true;
        title: i18n.tr("Please wait")
        text: i18n.tr("Importing podcasts...")

        ActivityIndicator {
            running: parent.visible
        }

        ProgressBar {
            id:progressBar

            onValueChanged: {
                if(value > maximumValue) {
                    PopupUtils.close(loadingDialog)
                    tabs.selectedTabIndex = 2;
                }
            }
        }

        Label {
            text: progressBar.value + "/" + (progressBar.maximumValue+1) + " " + i18n.tr("imported")
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
