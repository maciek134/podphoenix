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
import QtMultimedia 5.6
import QtQuick.LocalStorage 2.0
import Ubuntu.Components 1.3
import Ubuntu.DownloadManager 1.2
import Ubuntu.Components.Popups 1.0
import "../podcasts.js" as Podcasts
import "../components"

Page {
    id: podcastPage

    TabsList {
        id: tabsList
    }

    header: standardHeader

    PageHeader {
        id: standardHeader

        title: i18n.tr("Podcasts")
        visible: podcastPage.header === standardHeader

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
                    podcastPage.header = searchHeader
                    searchField.item.forceActiveFocus()
                }
            }
        ]
    }

    PageHeader {
        id: searchHeader
        visible: podcastPage.header === searchHeader

        StyleHints {
            backgroundColor: podphoenix.appTheme.background
        }

        contents: Loader {
            id: searchField
            sourceComponent: podcastPage.header === searchHeader ? searchFieldComponent : undefined
            anchors.left: parent ? parent.left : undefined
            anchors.right: parent ? parent.right : undefined
            anchors.verticalCenter: parent.verticalCenter
        }

        leadingActionBar.actions: [
            Action {
                iconName: "back"
                onTriggered: {
                    viewLoader.item.forceActiveFocus()
                    podcastPage.header = standardHeader
                }
            }
        ]
    }

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
        } else {
            podcastPage.header = standardHeader;
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
            icon.source: podcastModel.count === 0 ? Qt.resolvedUrl("../graphics/owlSearch.svg") : Qt.resolvedUrl("../graphics/notFound.svg")
            title: podcastModel.count === 0 ? i18n.tr("No Podcast Subscriptions") : i18n.tr("No Podcasts Found")
            subTitle: podcastModel.count === 0 ? i18n.tr("You haven't subscribed to any podcasts yet, visit the 'Add New Podcasts' page to add some.")
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
        filter.pattern: podcastPage.header === searchHeader && searchField.status == Loader.Ready ? RegExp(searchField.item.text, "gi")
                                                                                                  : RegExp("", "gi")
    }

    Loader {
        id: viewLoader
        anchors {
            top: podcastPage.header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        sourceComponent: podphoenix.settings.showListView ? listviewComponent : cardviewComponent
    }

    Component {
        id: cardviewComponent

        CardView {
            id: cardView
            clip: false
            heightOffset: units.gu(0)
            widthOffset: units.gu(0)
            model: sortedPodcastModel
            delegate: Card {
                id: albumCard
                coverArt: model.image !== undefined ? model.image : Qt.resolvedUrl("../graphics/podphoenix.png")
                secondaryText: model.episodeCount > 0 ? model.episodeCount
                                                      : ""
                onClicked: {
                    if(podcastPage.header === searchHeader) {
                        cardView.forceActiveFocus()
                        podcastPage.header = standardHeader
                    }
                    mainStack.push(Qt.resolvedUrl("EpisodesPage.qml"), {"episodeName": model.name, "episodeId": model.id, "episodeArtist": model.artist, "episodeImage": model.image, "mode": (model.episodeCount > 0 ? "unheard" : "listened")})
                }
            }
        }
    }

    Component {
        id: listviewComponent

        UbuntuListView {
            id: listView

            Component.onCompleted: {
                // FIXME: workaround for qtubuntu not returning values depending on the grid unit definition
                // for Flickable.maximumFlickVelocity and Flickable.flickDeceleration
                var scaleFactor = units.gridUnit / 8;
                maximumFlickVelocity = maximumFlickVelocity * scaleFactor;
                flickDeceleration = flickDeceleration * scaleFactor;
            }

            clip: true
            currentIndex: -1
            model: sortedPodcastModel
            anchors.fill: parent

            footer: Item {
                width: parent.width
                height: units.gu(8)
            }

            delegate: ListItem {
                id: listItem

                height: listItemLayout.height
                divider.visible: false
                highlightColor: podphoenix.appTheme.hightlightListView

                ListItemLayout {
                    id: listItemLayout
                    title.text: model.name !== undefined ? model.name.trim() : "Undefined"
                    summary.text: model.episodeCount > 0 ? i18n.tr("%1 unheard episode", "%1 unheard episodes", model.episodeCount).arg(model.episodeCount)
                                                          : ""
                    summary.color: podphoenix.appTheme.baseSubText

                    Image {
                        height: width
                        width: units.gu(6)
                        source: model.image !== undefined ? model.image : Qt.resolvedUrl("../graphics/podphoenix.png")
                        SlotsLayout.position: SlotsLayout.Leading
                        sourceSize { width: width; height: height }
                    }
                }

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
                    if(podcastPage.header === searchHeader) {
                        listView.forceActiveFocus()
                        podcastPage.header = standardHeader
                    }
                    mainStack.push(Qt.resolvedUrl("EpisodesPage.qml"), {"episodeName": model.name, "episodeId": model.id, "episodeArtist": model.artist, "episodeImage": model.image, "mode": (model.episodeCount > 0 ? "unheard" : "listened")})
                }
            }

            Scrollbar {
                flickableItem: listView
                align: Qt.AlignTrailing
                StyleHints { sliderColor: podphoenix.appTheme.focusText }
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
            var rs = tx.executeSql(`
                SELECT p.rowid as rowid, p.*, sum(CASE WHEN e.listened = 0 THEN 1 ELSE 0 END) as episodeCount
                FROM Podcast as p
                JOIN Episode as e
                ON p.rowid = e.podcast
                GROUP BY p.rowid
                ORDER BY p.name ASC
            `);
            for(var i = 0; i < rs.rows.length; i++) {
                var podcast = rs.rows.item(i);
                podcastModel.append({"id" : podcast.rowid, "name" : podcast.name, "artist" : podcast.artist, "image" : podcast.image, "episodeCount" : podcast.episodeCount});
            }
        });

        episodesUpdating = false;
    }

    function updateEpisodesDatabase() {
        episodesUpdating = true;
        Podcasts.updateEpisodes(refreshModel)
    }
}

