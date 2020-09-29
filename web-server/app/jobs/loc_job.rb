class LocJob < ApplicationJob
  queue_as :loc_jobs # in-memory queue is fine for my purposes

  def perform(vcs_url, sha)
    @vcs_url = vcs_url
    @sha = sha

    tag = Rails.env == 'production' ? 'stable' : 'unstable'
    ssh_path = Rails.application.config.cfg['ssh_key_path']

    Docker.options[:read_timeout] = 300 # 5 mins

    counter = Docker::Container.create('Image' => "koellewe/loculator:#{tag}",
                                       'Env' => ["VCS_URL=#{@vcs_url}"],
                                       'HostConfig' => { 'Binds' => ["#{ssh_path}:/mnt/creds"] }
    )

    # run the counting in-container
    res = counter.tap(&:start).attach(stdin: nil)

    begin
      txt = res[0][0]
      counting_output = if txt.nil?
                          { 'error': 'Could not parse response from container' }
                        else
                          JSON.parse(txt)
                        end

      if counting_output['error']
        @error = counting_output['error']
      else
        @results = counting_output
      end
    rescue JSON::ParserError
      @error = 'Unknown runtime error occurred during line-counting.'
    ensure
      finalise_cache # even if failed

      # mark job complete
      cache_record = LocCache.find_by(vcs_url: @vcs_url)
      cache_record['running'] = false
      cache_record.save!
    end

  end

  # do the actual caching, if necessary
  private def finalise_cache
    # created during initial cache check
    cache = LocCache.find_by(vcs_url: @vcs_url)
    cache['latest_commit'] = @sha # will be nil for private non-specified
    cache['json_cache'] = @error ? { 'error': @error }.to_json : @results.to_json
    cache.save!
  end

end
