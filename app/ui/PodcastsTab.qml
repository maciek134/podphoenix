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

import QtQuick 2.4
import QtMultimedia 5.0
import QtQuick.Layouts 1.1
import QtQuick.LocalStorage 2.0
import Ubuntu.Components 1.2
import Ubuntu.DownloadManager 0.1
import Ubuntu.Components.ListItems 1.0 as ListItem
import Ubuntu.Components.Popups 1.0
import "../podcasts.js" as Podcasts
import "../components"

Page {
    id: podcastPage

    /*
     #FIXME: The page flickable is to null instead of viewLoader.item since
     it otherwise creates bug http://pad.lv/1446162 which can confuse a
     new user.
    */
    flickable: null

    property bool episodesUpdating: false;

    state: "default"
    states: [
        PageHeadState {
            name: "default"
            head: podcastPage.head
            actions: [
                Action {
                    iconName: "search"
                    text: i18n.tr("Search Podcast")
                    onTriggered: {
                        podcastPage.state = "search"
                        searchField.item.forceActiveFocus()
                    }
                },
                Action {
                    iconName: podbird.settings.showListView ? "view-grid-symbolic" : "view-list-symbolic"
                    text: podbird.settings.showListView ? i18n.tr("Grid View") : i18n.tr("List View")
                    onTriggered: {
                        podbird.settings.showListView = !podbird.settings.showListView
                    }
                }
            ]
        },

        PageHeadState {
            name: "search"
            head: podcastPage.head
            actions: [
                Action {
                    iconName: podbird.settings.showListView ? "view-grid-symbolic" : "view-list-symbolic"
                    text: podbird.settings.showListView ? i18n.tr("Grid View") : i18n.tr("List View")
                    onTriggered: {
                        podbird.settings.showListView = !podbird.settings.showListView
                    }
                }
            ]

            backAction: Action {
                iconName: "back"
                text: i18n.tr("Back")
                onTriggered: {
                    viewLoader.item.forceActiveFocus()
                    podcastPage.state = "default"
                }
            }

            contents: Loader {
                id: searchField
                sourceComponent: podcastPage.state === "search" ? searchFieldComponent : undefined
                anchors.left: parent ? parent.left : undefined
                anchors.right: parent ? parent.right : undefined
                anchors.rightMargin: units.gu(2)
            }
        }
    ]

    Component {
        id: searchFieldComponent
        TextField {
            inputMethodHints: Qt.ImhNoPredictiveText
            placeholderText: i18n.tr("Search podcast")
        }
    }

    onVisibleChanged: {
        if(visible) {
            refreshModel();
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

        sourceComponent: podcastModel.count === 0 || sortedPodcastModel.count === 0 ? emptyStateComponent : undefined
    }

    Component {
        id: emptyStateComponent
        EmptyState {
            iconHeight: units.gu(12)
            iconWidth: units.gu(22)
            iconSource: podcastModel.count === 0 ? Qt.resolvedUrl("../graphics/owlSearch.svg") : Qt.resolvedUrl("../graphics/notFound.svg")
            title: podcastModel.count === 0 ? i18n.tr("No Podcast Subscriptions") : i18n.tr("No Podcasts Found")
            subTitle: podcastModel.count === 0 ? i18n.tr("You haven't subscribed to any podcasts yet, visit the 'Find New Podcasts' page to add some.")
                                               : i18n.tr("No podcasts found matching the search term.")
        }
    }

    ListModel {
        id: podcastModel
    }

    SortFilterModel {
        id: sortedPodcastModel
        model: podcastModel
        filter.property: "name"
        filter.pattern: podcastPage.state === "search" && searchField.status == Loader.Ready ? RegExp(searchField.item.text, "gi")
                                                                                             : RegExp("", "gi")
    }

    Loader {
        id: viewLoader
        anchors.fill: parent
        sourceComponent: podbird.settings.showListView ? listviewComponent : cardviewComponent
    }

    Component {
        id: cardviewComponent

        CardView {
            id: cardView
            clip: true
            model: sortedPodcastModel
            delegate: Card {
                id: albumCard
                coverArt: model.image !== undefined ? model.image : Qt.resolvedUrl("../graphics/podbird.png")
                primaryText: model.name !== undefined ? model.name.trim() : "Undefined"
                secondaryText: model.episodeCount > 0 ? i18n.tr("%1 unheard episode", "%1 unheard episodes", model.episodeCount).arg(model.episodeCount)
                                                      : null
                onClicked: {
                    if(podcastPage.state === "search") {
                        cardView.forceActiveFocus()
                        podcastPage.state = "default"
                    }
                    mainStack.push(Qt.resolvedUrl("EpisodesPage.qml"), {"episodeName": model.name, "episodeId": model.id, "episodeArtist": model.artist, "episodeImage": model.image})
                }
            }
        }
    }

    Component {
        id: listviewComponent

        ListView {
            id: listView

            Component.onCompleted: {
                // FIXME: workaround for qtubuntu not returning values depending on the grid unit definition
                // for Flickable.maximumFlickVelocity and Flickable.flickDeceleration
                var scaleFactor = units.gridUnit / 8;
                maximumFlickVelocity = maximumFlickVelocity * scaleFactor;
                flickDeceleration = flickDeceleration * scaleFactor;
            }

            clip: true
            model: sortedPodcastModel
            anchors.fill: parent

            footer: Item {
                width: parent.width
                height: units.gu(8)
            }

            delegate: ListDelegate {
                id: listItem

                height: units.gu(8)
                highlightColor: index % 2 === 0 ? "Transparent" : podbird.appTheme.hightlightListView
                color: index % 2 === 0 ? podbird.appTheme.hightlightListView : "Transparent"
                title: model.name !== undefined ? model.name.trim() : "Undefined"
                subtitle: model.episodeCount > 0 ? i18n.tr("%1 unheard episode", "%1 unheard episodes", model.episodeCount).arg(model.episodeCount)
                                                 : null
                coverArt: model.image !== undefined ? model.image : Qt.resolvedUrl("../graphics/podbird.png")

                leadingActions: ListItemActions {
                    actions: [
                        Action {
                            iconName: "delete"
                            onTriggered: {
                                var db = Podcasts.init();
                                db.transaction(function (tx) {
                                    var rs = tx.executeSql("SELECT downloadedfile FROM Episode WHERE downloadedfile NOT NULL AND podcast=?", [model.id]);
                                    for(var i = 0; i < rs.rows.length; i++) {
                                        fileManager.deleteFile(rs.rows.item(i).downloadedfile);
                                    }
                                    tx.executeSql("DELETE FROM Episode WHERE podcast=?", [model.id]);
                                    tx.executeSql("DELETE FROM Podcast WHERE rowid=?", [model.id]);
                                    podcastModel.remove(index, 1)
                                });
                            }
                        }
                    ]
                }

                onClicked: {
                    if(podcastPage.state === "search") {
                        listView.forceActiveFocus()
                        podcastPage.state = "default"
                    }
                    mainStack.push(Qt.resolvedUrl("EpisodesPage.qml"), {"episodeName": model.name, "episodeId": model.id, "episodeArtist": model.artist, "episodeImage": model.image})
                }
            }

            // #FIXME: Use SDK Scrollbar when it is themeable
            CustomScrollBar {
                listview: listView
            }

            PullToRefresh {
                refreshing: episodesUpdating
                onRefresh: updateEpisodesDatabase();
            }
        }
    }

    function refreshModel() {
        var db = Podcasts.init();

        db.transaction(function (tx) {
            podcastModel.clear();
            var rs = tx.executeSql("SELECT rowid, * FROM Podcast ORDER BY name ASC");
            for(var i = 0; i < rs.rows.length; i++) {
                var podcast = rs.rows.item(i);
                var rs2 = tx.executeSql("SELECT Count(*) AS epcount FROM Episode WHERE podcast=? AND NOT listened", [rs.rows.item(i).rowid]);
                podcastModel.append({"id" : podcast.rowid, "name" : podcast.name, "artist" : podcast.artist, "image" : podcast.image, "episodeCount" : rs2.rows.item(0).epcount});
                if (podcast.lastupdate === null && !episodesUpdating) {
                    updateEpisodesDatabase();
                }
            }
        });

        episodesUpdating = false;
    }

    function updateEpisodesDatabase() {
        episodesUpdating = true;
        Podcasts.updateEpisodes(refreshModel)
    }
}

