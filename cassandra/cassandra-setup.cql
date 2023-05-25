CREATE KEYSPACE IF NOT EXISTS reddit 
    WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

USE reddit;

CREATE TABLE IF NOT EXISTS comments(
    uuid uuid,
    id text,
    name text,
    author text,
    body text,
    subreddit text,
    upvotes int,
    downvotes int,
    over_18 boolean,
    permalink text,
    api_timestamp timestamp,
    ingest_timestamp timestamp,
    sentiment_score float,
    PRIMARY KEY((subreddit), api_timestamp)
)
WITH CLUSTERING ORDER BY (api_timestamp DESC);

CREATE INDEX IF NOT EXISTS ON comments (uuid);

CREATE TABLE IF NOT EXISTS subreddit_sentiment_avg(
    uuid uuid,
    subreddit text,
    sentiment_score_avg double,
    ingest_timestamp timestamp,
    PRIMARY KEY((subreddit),ingest_timestamp))
WITH CLUSTERING ORDER BY (ingest_timestamp DESC);

CREATE INDEX IF NOT EXISTS ON subreddit_sentiment_avg (uuid);