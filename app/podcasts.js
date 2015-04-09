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

function init() {
    var db = LocalStorage.openDatabaseSync("Podbird", "", "Database of subscribed podcasts and their episodes", 1000000);

    db.transaction(function(tx) {
        tx.executeSql('CREATE TABLE IF NOT EXISTS Podcast(artist TEXT, name TEXT, description TEXT, feed TEXT, image TEXT, lastupdate TIMESTAMP)');
        tx.executeSql('CREATE TABLE IF NOT EXISTS Episode(guid TEXT, podcast INTEGER, name TEXT, subtitle TEXT, description TEXT, duration INTEGER, audiourl TEXT, downloadedfile TEXT, published TIMESTAMP, listened BOOLEAN, queued BOOLEAN, position INTEGER, FOREIGN KEY(podcast) REFERENCES Podcast(rowid))');
    });

    if (db.version == "1.0") {
        db.changeVersion("1.0", "1.1", function(tx) {
            tx.executeSql('ALTER TABLE Episode ADD queued BOOLEAN');
            tx.executeSql('UPDATE Episode SET queued=?', [false]);
        });
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

function zeroFill(n, width) {
    width -= n.toString().length;
    if (width > 0) {
        return new Array(width + (/\./.test(n) ? 2 : 1)).join('0') + n;
    }
    return n + "";
}
