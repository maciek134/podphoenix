CREATE TABLE IF NOT EXISTS Podcast (
  artist text,
  name text,
  description text,
  feed text,
  image text,
  lastupdate timestamp
);

CREATE INDEX podcast_feed ON Podcast (feed);
CREATE INDEX podcast_lastupdate ON Podcast (lastupdate);


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

CREATE INDEX episode_guid ON Episode (guid);
CREATE INDEX episode_podcast ON Episode (podcast);
CREATE INDEX episode_published ON Episode (published);
CREATE INDEX episode_queued ON Episode (queued);
CREATE INDEX episode_listened ON Episode (listened);
CREATE INDEX episode_favourited ON Episode (favourited);
CREATE INDEX episode_position ON Episode (position);
CREATE INDEX episode_downloadedfile ON Episode (downloadedfile);
CREATE INDEX episode_name ON Episode (name);


CREATE TABLE IF NOT EXISTS Queue (
  position integer,
  ind integer NOT NULL,
  guid text,
  image text,
  name text,
  artist text,
  url text
);

CREATE INDEX queue_position ON Queue (position);
CREATE INDEX queue_ind ON Queue (ind);
CREATE INDEX queue_guid ON Queue (guid);
CREATE INDEX queue_url ON Queue (url);
