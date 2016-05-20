module NuviNews
  class Downloader

    def initialize(source_url, redis_listname, redis_instance)
        @source_url = source_url
        @redis_listname = redis_listname
        @redis_instance = redis_instance
        @progressbar = nil
    end

    def run
      @reports_inserted = 0
      # Grab a list of the zipped archives from the given URL.
      archives = get_archives

      @progressbar = ProgressBar.create(title: "Processing news reports", total: archives.size)

      # Process all of the report archives, running up to five threads at once.
      archives.pmap(5) { |a| process_archive(a) }

      puts Paint["Completed! #{@reports_inserted} reports inserted into #{@redis_listname}.", @reports_inserted > 0 ? :green : :red]
    end

    private

    def get_archives
      html = Nokogiri::HTML(open(@source_url))
      html.css('a').map { |link| link.attribute('href').to_s }.keep_if { |s| s =~ /\.zip/ }
    end

    def process_archive(archive)
      # Use a Redis set to ensure that the application is idempotent.
      if @redis_instance.sadd("#{@redis_listname}_VISITED", archive)
        begin
          # Create a temp file and download the archive.
          temp = Tempfile.new("#{archive}")
          temp.write(open("#{@source_url}#{archive}").read)
          temp.close

          # Unzip the archive and add the xml news reports to the Redis database.
          Zip::File.open(temp.path) do |files|
            files.each do |file|
              xml = files.read(file)
              @redis_instance.lpush(@redis_listname, xml)
              @reports_inserted += 1
            end
          end
        ensure
          @progressbar.increment
          temp.close
          temp.unlink
        end
      end
    end

  end
end
