# News Downloader

This command line tool will download a list of archived news reports, unzip the archives, and insert
the news reports into a Redis list.  The application is idempotent.

A Redis host, port, password, and database number may be optionally specified.

```bash
> $ news_downloader download <source_url> <redis_list> [--redis_host REDIS_HOST
      --redis_port REDIS_PORT --redis_password REDIS_PASSWORD
      --redis_database REDIS_DATABASE]

'news_downloader download <source_url> <redis_list>' will download archived (zip)
news reports (xml) from the specified URL and insert them into the specified Redis list.
The application is idempotent.

A source URL and name for the Redis list is required.  

You may optionally specify a host, port, password, and database number for the
Redis server.  By default, the application will look for a server running on the
localhost at port 6379, without a password, and with the default database number of 0.

```

## Installation

Install the gems from the Gemfile.

```bash
bundle install
```

## Usage

```bash
news_downloader http://feed.omgili.com/5Rh5AMTrc4Pv/mainstream/posts/ NEWS_XML
```

## Implementation Details

This tool iterates through a remote directory of zipped archives located at the
specified URL, batching the archives for processing using Celluloid futures.  Up to five
archives will be processed at a time using a thread pool.  

The archives are processed by downloading them into a temporary file, unzipping the contents,
iterating over the contents (xml files containing news reports), and inserting the news reports
into the specified Redis list.

Idempotency is achieved by utilizing a Redis set to keep track of each archive, ensuring that
an archive will never be processed twice.
