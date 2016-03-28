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

function init() {
    var db = LocalStorage.openDatabaseSync("Podbird", "", "Database of subscribed podcasts and their episodes", 1000000);

    db.transaction(function(tx) {
        tx.executeSql('CREATE TABLE IF NOT EXISTS Podcast(artist TEXT, name TEXT, description TEXT, feed TEXT, image TEXT, lastupdate TIMESTAMP)');
        tx.executeSql('CREATE TABLE IF NOT EXISTS Episode(guid TEXT, podcast INTEGER, name TEXT, subtitle TEXT, description TEXT, duration INTEGER, audiourl TEXT, downloadedfile TEXT, published TIMESTAMP, queued BOOLEAN, listened BOOLEAN, favourited BOOLEAN, position INTEGER, FOREIGN KEY(podcast) REFERENCES Podcast(rowid))');
    });

    try {
        /*
        Schema Upgrade to v1.1 which adds a new queued boolean variable which is needed to track the queued status
        of a episode properly.
        */
        if (db.version === "1.0" || db.version === "") {
            console.log("Upgrading database from %1 -> v1.1".arg(db.version))
            db.changeVersion(db.version, "1.1", function(tx) {
                tx.executeSql('ALTER TABLE Episode ADD queued BOOLEAN');
                tx.executeSql('UPDATE Episode SET queued=0');
            });
        }

        /*
        Schema Upgrade to v1.2 which adds a new favourited boolean variable which is needed to track the favourite status
        of an episode.
        */
        if (db.version === "1.1") {
            console.log("Upgrading database from %1 -> v1.2".arg(db.version))
            db.changeVersion("1.1", "1.2", function(tx) {
                tx.executeSql('ALTER TABLE Episode ADD favourited BOOLEAN');
                tx.executeSql('UPDATE Episode SET favourited=?', [false]);
            });
        }
    } catch(ex) {
        console.log(ex)
    }

    return db;
}

function subscribe(artist, name, feed, img) {
    var db = init();
    db.transaction(function(tx) {
        var rs = tx.executeSql("SELECT rowid FROM Podcast WHERE feed = ?", feed);
        if (rs.rows.length === 0) {
            tx.executeSql("INSERT INTO Podcast(artist, name, feed, image) VALUES(?, ?, ?, ?)", [artist, name, feed, img]);
        }
    });
}

function updateEpisodes(refreshModel) {
    console.log("[LOG]: Checking for new episodes")

    var db = Podcasts.init();
    db.transaction(function(tx) {
        var rs = tx.executeSql("SELECT rowid, feed FROM Podcast");
        tx.executeSql("UPDATE Podcast SET lastupdate=CURRENT_TIMESTAMP");
        var xhr = [];
        var xhrComplete = [];
        for(var i = 0; i < rs.rows.length; i++) {
            (function (i) {
                xhr[i] = new XMLHttpRequest;
                var url = rs.rows.item(i).feed;
                var pid = rs.rows.item(i).rowid;
                xhrComplete[i] = false;
                xhr[i].open("GET", url);
                xhr[i].onreadystatechange = function() {
                    if (xhr[i].readyState === XMLHttpRequest.DONE) {
                        xhrComplete[i] = true;

                        try {
                            var e = xhr[i].responseXML.documentElement;
                            for(var h = 0; h < e.childNodes.length; h++) {
                                if(e.childNodes[h].nodeName === "channel") {
                                    var c = e.childNodes[h];
                                    for(var j = 0; j < c.childNodes.length; j++) {
                                        if(c.childNodes[j].nodeName === "item") {
                                            var t = c.childNodes[j];
                                            var track = {}
                                            for(var k = 0; k < t.childNodes.length; k++) {
                                                try {
                                                    var nodeName = t.childNodes[k].nodeName.toLowerCase();
                                                    if (nodeName === "title")               track['name'] = t.childNodes[k].childNodes[0].nodeValue;
                                                    else if (nodeName === "description")    track['description'] = t.childNodes[k].childNodes[0].nodeValue;
                                                    else if (nodeName === "guid")           track['guid'] = t.childNodes[k].childNodes[0].nodeValue;
                                                    else if (nodeName === "pubdate")        track['published'] = new Date(t.childNodes[k].childNodes[0].nodeValue).getTime();
                                                    else if (nodeName === "duration") {
                                                        var dur = t.childNodes[k].childNodes[0].nodeValue.split(":");
                                                        if (dur.length === 1) {
                                                            track['duration'] = parseInt(dur[0]);
                                                        } else if (dur.length === 2) {
                                                            track['duration'] = parseInt(dur[0]) * 60 + parseInt(dur[1]);
                                                        } else if (dur.length === 3) {
                                                            track['duration'] = parseInt(dur[0]) * 3600 + parseInt(dur[1]) * 60 + parseInt(dur[2]);
                                                        }
                                                    } else if (nodeName === "enclosure") {
                                                        var el = t.childNodes[k];
                                                        for (var l = 0; l < el.attributes.length; l++) {
                                                            if(el.attributes[l].nodeName === "url")         track['audiourl'] = el.attributes[l].nodeValue;
                                                        }
                                                    }
                                                } catch(err) {
                                                    console.debug("Error: " + err.message);
                                                }
                                            }
                                            if (!track.hasOwnProperty("guid")) {
                                                track['guid'] = track.audiourl;
                                            }
                                            
                                            db.transaction(function(tx2) {
                                                var ers = tx2.executeSql("SELECT rowid FROM Episode WHERE guid=?", [track.guid]);
                                                if (ers.rows.length === 0) {
                                                    tx2.executeSql("INSERT INTO Episode(podcast, name, description, audiourl, guid, listened, queued, favourited, duration, published) VALUES(?, ?, ? , ?, ?, ?, ?, ?, ?, ?)", [pid,
                                                                                                                                                                                                                                track.name,
                                                                                                                                                                                                                                track.description,
                                                                                                                                                                                                                                track.audiourl,
                                                                                                                                                                                                                                track.guid,
                                                                                                                                                                                                                                false,
                                                                                                                                                                                                                                false,
                                                                                                                                                                                                                                false,
                                                                                                                                                                                                                                track.duration,
                                                                                                                                                                                                                                track.published]);
                                                }
                                            });
                                        }
                                    }
                                }
                            }
                        } catch (error) {
                            console.log("[WARNING]: Failed to parse " + rs.rows.item(i).feed + ": " + error);
                        }
                    }
                    var allComplete = true;
                    for(var j = 0; j < xhrComplete.length; j++) {
                        if (!xhrComplete[j]) {
                            allComplete = false;
                            break;
                        }
                    }
                    if(allComplete) {
                        console.log("[LOG]: Finished checking for new episodes..")
                        podbird.settings.lastUpdate = new Date();
                        refreshModel();
                    }
                }
                xhr[i].send();
            })(i);
        }
    });

}

function getTimeDiff(time) {
    var hours, minutes;
    time = Math.floor(time / 60)
    minutes = time % 60
    hours = Math.floor(time / 60)
    return [hours, minutes]
}

function formatTime(time) {
    var hours, minutes, seconds;
    seconds = zeroFill(Math.floor(time % 60), 2)
    time = Math.floor(time/60)
    hours = zeroFill(Math.floor(time/60), 2)
    minutes = zeroFill(time % 60, 2)
    if (hours > 0)
        return hours + ":" + minutes + ":" + seconds;
    else
        return minutes + ":" + seconds;
}

function formatEpisodeTime(seconds) {
    var time = getTimeDiff(seconds)
    var hour = time[0]
    var minute = time[1]
    // TRANSLATORS: the first argument is the number of hours,
    // followed by minute (eg. 20h 3m)
    if(hour > 0 &&  minute > 0) {
        // xgettext: no-c-format
        return (i18n.tr("%1 hr %2 min"))
        .arg(hour)
        .arg(minute)
    }

    // TRANSLATORS: this string indicates the number of hours
    // eg. 20h (no plural state required)
    else if(hour > 0 && minute === 0) {
        // xgettext: no-c-format
        return (i18n.tr("%1 hr"))
        .arg(hour)
    }

    // TRANSLATORS: this string indicates the number of minutes
    // eg. 15m (no plural state required)
    else if(hour === 0 && minute > 0) {
        // xgettext: no-c-format
        return (i18n.tr("%1 min"))
        .arg(minute)
    }

    else {
        return formatTime(seconds)
    }
}

function zeroFill(n, width) {
    width -= n.toString().length;
    if (width > 0) {
        return new Array(width + (/\./.test(n) ? 2 : 1)).join('0') + n;
    }
    return n + "";
}

function cleanUp(today, retentionDays) {
    console.log("[LOG]: Cleaning up old episodes")
    var dayToMs = 86400000; //1 * 24 * 60 * 60 * 1000
    var db = Podcasts.init()
    db.transaction(function (tx) {
        var rs = tx.executeSql("SELECT rowid, * FROM Podcast ORDER BY name ASC");
        for(var i = 0; i < rs.rows.length; i++) {
            var podcast = rs.rows.item(i);
            var rs2 = tx.executeSql("SELECT rowid, * FROM Episode WHERE podcast=?", [rs.rows.item(i).rowid]);
            for (var j=0; j< rs2.rows.length; j++) {
                var diff = Math.floor((today - rs2.rows.item(j).published)/dayToMs)
                if (rs2.rows.item(j).downloadedfile && diff > retentionDays) {
                    fileManager.deleteFile(rs2.rows.item(j).downloadedfile)
                    tx.executeSql("UPDATE Episode SET downloadedfile = NULL WHERE guid = ?", [rs2.rows.item(j).guid]);
                }
            }
        }
    });
}

function autoDownloadEpisodes(maxEpisodeDownload) {
    console.log("[LOG]: Auto-downloading new episodes")
    var db = Podcasts.init()
    db.transaction(function (tx) {
        var rs = tx.executeSql("SELECT rowid, * FROM Podcast ORDER BY name ASC");
        for (var i=0; i < rs.rows.length; i++) {
            var podcast = rs.rows.item(i);
            var rs2 = tx.executeSql("SELECT rowid, * FROM Episode WHERE podcast=? ORDER BY published DESC", [rs.rows.item(i).rowid]);
            var loopCount = maxEpisodeDownload > rs2.rows.length ? rs2.rows.length : maxEpisodeDownload
            for (var j=0; j < loopCount; j++) {
                if (!rs2.rows.item(j).downloadedfile && !rs2.rows.item(j).listened) {
                    downloader.addDownload(rs2.rows.item(j).guid, rs2.rows.item(j).audiourl)
                    tx.executeSql("UPDATE Episode SET queued=1 WHERE guid = ?", [rs2.rows.item(j).guid]);
                }
            }
        }
    });
}
