/*
 * Copyright 2015 Podphoenix Team
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

function init() {
    var db = LocalStorage.openDatabaseSync("Podphoenix", "", "Database of subscribed podcasts and their episodes", 1000000);

    db.transaction(function(tx) {
        tx.executeSql(`
            CREATE TABLE IF NOT EXISTS Podcast (
                artist text,
                name text,
                description text,
                feed text,
                image text,
                lastupdate timestamp
            );
        `)
        tx.executeSql(`
          CREATE INDEX IF NOT EXISTS podcast_feed ON Podcast (feed);
        `)
        tx.executeSql(`
          CREATE INDEX IF NOT EXISTS podcast_lastupdate ON Podcast (lastupdate);
        `)
        tx.executeSql(`
          CREATE TABLE IF NOT EXISTS Episode (
            guid text,
            podcast integer,
            name text,
            subtitle text,
            description text,
            duration integer,
            audiourl text,
            downloadedfile text,
            published timestamp,
            queued boolean,
            listened boolean,
            favourited boolean,
            position integer,
            FOREIGN KEY (podcast) REFERENCES Podcast (rowid)
          );
        `)
        tx.executeSql(`
          CREATE INDEX IF NOT EXISTS episode_guid ON Episode (guid);
        `)
        tx.executeSql(`
          CREATE INDEX IF NOT EXISTS episode_podcast ON Episode (podcast);
        `)
        tx.executeSql(`
          CREATE INDEX IF NOT EXISTS episode_published ON Episode (published);
        `)
        tx.executeSql(`
          CREATE INDEX IF NOT EXISTS episode_queued ON Episode (queued);
        `)
        tx.executeSql(`
          CREATE INDEX IF NOT EXISTS episode_listened ON Episode (listened);
        `)
        tx.executeSql(`
          CREATE INDEX IF NOT EXISTS episode_favourited ON Episode (favourited);
        `)
        tx.executeSql(`
          CREATE INDEX IF NOT EXISTS episode_position ON Episode (position);
        `)
        tx.executeSql(`
          CREATE INDEX IF NOT EXISTS episode_downloadedfile ON Episode (downloadedfile);
        `)
        tx.executeSql(`
          CREATE INDEX IF NOT EXISTS episode_name ON Episode (name);
        `)
        tx.executeSql(`
          CREATE TABLE IF NOT EXISTS Queue (
            position integer,
            ind integer NOT NULL,
            guid text,
            image text,
            name text,
            artist text,
            url text
          );
        `)
        tx.executeSql(`
          CREATE INDEX IF NOT EXISTS queue_position ON Queue (position);
        `)
        tx.executeSql(`
          CREATE INDEX IF NOT EXISTS queue_ind ON Queue (ind);
        `)
        tx.executeSql(`
          CREATE INDEX IF NOT EXISTS queue_guid ON Queue (guid);
        `)
        tx.executeSql(`
          CREATE INDEX IF NOT EXISTS queue_url ON Queue (url);
        `);
    });

    return db;
}

// Function to add item to queue
function addItemToQueue(guid, image, name, artist, url, position) {
    var db = init()

    db.transaction(function(tx) {
        var ind = getNextIndex(tx);
        var rs = tx.executeSql("INSERT OR REPLACE INTO Queue (ind, guid, image, name, artist, url, position) VALUES (?, ?, ?, ?, ?, ?, ?)", [ind, guid, image, name, artist, url, position]);
        if (rs.rowsAffected > 0) {
            console.log("[LOG]: QUEUE add OK")
            console.log("[LOG]: URL Added to queue: " + url)
        } else {
            console.log("[LOG]: QUEUE add FAIL")
        }
    });
}

function removeItemFromQueue(source) {
    var db = init()

    db.transaction(function(tx) {
        // Remove selected source from the queue
        tx.executeSql("DELETE FROM Queue WHERE url = ?", source)

        // Rebuild queue in order
        var rs = tx.executeSql("SELECT ind FROM Queue ORDER BY ind ASC")

        for (var i=0; i<rs.rows.length; i++) {
            tx.executeSql("UPDATE Queue SET ind = ? WHERE ind = ?", [i, rs.rows.item(i).ind])
        }
    })
}

// Function to clear the queue
function clearQueue() {
    var db = init();
    db.transaction(function(tx) {
        tx.executeSql("DELETE FROM Queue");
    });

    db.transaction(function (tx) {
        tx.executeSql('UPDATE Episode SET queued=0 WHERE queued=1');
    });
}

function lookup(source) {
    var db = init();
    var meta = {
        name: "",
        artist: "",
        image: "",
        guid: "",
        position: 0,
    }

    db.transaction(function(tx) {
        var rs = tx.executeSql("SELECT * FROM Queue WHERE url = ?", [source]);
        if (rs.rows.length > 0) {
            var episode = rs.rows.item(0);
            meta.name = episode.name
            meta.artist = episode.artist
            meta.image = episode.image
            meta.guid = episode.guid
            meta.position = episode.position
        }
    });

    return meta
}

// Function to get the next index for the queue
function getNextIndex(tx) {
    var ind;

    if (tx === undefined) {
        var db = init();
        db.transaction(function(tx) {
            ind = getNextIndex(tx);
        });
    } else {
        var rs = tx.executeSql('SELECT MAX(ind) FROM Queue')
        ind = isQueueEmpty(tx) ? 0 : rs.rows.item(0)["MAX(ind)"] + 1
    }

    return ind;
}

function isQueueEmpty(tx) {
    var empty = false;

    if (tx === undefined) {
        var db = init();
        db.transaction( function(tx) {
            empty = isQueueEmpty(tx)
        });
    } else {
        var rs = tx.executeSql("SELECT count(*) as value FROM Queue")
        empty = rs.rows.item(0).value === 0
    }

    return empty
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
        var rs_timestamp = tx.executeSql("SELECT lastupdate FROM Podcast");
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
                                            //do not check every episode in database, just ~11.5 days before last update
                                            if(new Date(rs_timestamp.rows.item(i).lastupdate).getTime()<(track['published']+1000000000))
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
                            console.log("[LOG]: Response: " + xhr[i].response)
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
                        db.transaction(function(tx) {
                            tx.executeSql("UPDATE Podcast SET lastupdate=CURRENT_TIMESTAMP");
                        })
                        console.log("[LOG]: Finished checking for new episodes..")
                        podphoenix.settings.lastUpdate = new Date();
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
            var rs2 = tx.executeSql("SELECT rowid, * FROM Episode WHERE podcast=? ORDER BY published DESC", [podcast.rowid]);
            var loopCount = maxEpisodeDownload > rs2.rows.length ? rs2.rows.length : maxEpisodeDownload
            for (var j=0; j < loopCount; j++) {
                var  episode = rs2.rows.item(j);
                if ( !episode.downloadedfile && !episode.listened && episode.audiourl && !episode.queued ) {
                    podphoenix.downloadEpisode(podcast.image, episode.name, episode.guid, episode.audiourl, podphoenix.settings.downloadOverWifiOnly)
                    tx.executeSql("UPDATE Episode SET queued=1 WHERE guid = ?", [episode.guid]);
                }
            }
        }
    });
}
