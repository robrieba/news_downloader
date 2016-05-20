require 'rubygems'
require 'open-uri'
require 'redis'
require 'nokogiri'
require 'celluloid/current'
require 'celluloid/pmap'
require 'zip'
require 'thor'
require 'ruby-progressbar'
require 'paint'

require_relative 'lib/nuvi_news_downloader.rb'

class NewsDownloader < Thor
  option :redis_host, default: "localhost"
  option :redis_port, default: "6379"
  option :redis_password, default: nil
  option :redis_database, default: "0"
  desc "download <source_url> <redis_list> [--redis_host REDIS_HOST --redis_port REDIS_PORT --redis_password REDIS_PASSWORD --redis_database REDIS_DATABASE]",
    "download archived (.zip) XML news reports from <source_url> and insert into <redis_list>"
  long_desc <<-INSTRUCTIONS
    `news_downloader download <source_url> <redis_list>` will download archived (.zip) XML
    news reports from the specified URL and insert them into the specified Redis list.
    The application is idempotent.

    A source URL and name for the Redis list is required.  You may optionally specify
    a host, port, password, and database number for the Redis server.  By default,
    the application will look for a server running on the localhost at port 6379, without
    a password, and with the default database number of 0.

    > $ news_downloader download <source_url> <redis_list> [--redis_host REDIS_HOST
          --redis_port REDIS_PORT --redis_password REDIS_PASSWORD
          --redis_database REDIS_DATABASE]

  INSTRUCTIONS

  def download(source_url, redis_list)
    redis_instance = Redis.new( host: options[:redis_host],
                                port: options[:redis_port],
                                password: options[:redis_password],
                                db: options[:redis_db] )
    downloader = NuviNews::Downloader.new(source_url, redis_list, redis_instance)
    downloader.run
  end
end

NewsDownloader.start(ARGV)
