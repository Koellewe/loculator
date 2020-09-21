require 'docker'
require_relative '../db'
require 'net/http'
require 'uri'
require 'json'

# Controller for the API
class ApiController < ApplicationController
  def loc_specified
    if params['vcs_url']
      @vcs_url = params['vcs_url']
      @sha = params['latest_commit']
      loc_impl
    else
      @error = 'You must either specify the vcs url by slash-separation, or as a direct parameter'
      render 'api/err.json', status: 400
    end
  end

  def loc_std
    @vcs_url = if (params['private'] == 'true') || (params['private'] == '1')
                 "git@#{params['provider']}:#{params['user']}/#{params['repo']}"
               else
                 "https://#{params['provider']}/#{params['user']}/#{params['repo']}"
               end
    @sha = params['latest_commit']
    loc_impl
  end

  private def loc_impl
    # todo rate limiting
    # todo caching (public only)
    # todo vcs_url parameter
    # todo increase timeout

    json_cache = init_cache
    if json_cache
      @results = JSON.parse(json_cache)
      render 'api/loc.json', status: 200
      return
    end

    tag = Rails.env == 'production' ? 'stable' : 'stable'
    ssh_path = Rails.application.config.cfg['ssh_key_path']

    # res = `docker run -e "VCS_URL=#{vcs_url}" -v "#{config.cfg['ssh_key_path']}:/mnt/creds" koellewe/loculator:#{tag}`
    counter = Docker::Container.create('Image' => "koellewe/loculator:#{tag}",
                                       'Env' => ["VCS_URL=#{@vcs_url}"],
                                       'HostConfig' => { 'Binds' => ["#{ssh_path}:/mnt/creds"] }
    )

    res = counter.tap(&:start).attach(stdin: nil)

    begin
      counting_output = JSON.parse(res[0][0])
      if counting_output['error']
        @error = counting_output['error']
      else
        @results = counting_output
        finalise_cache
      end
    rescue JSON::ParserError
      @error = 'Unknown runtime error occurred during line-counting.'
    end

    render 'api/loc.json', status: @error ? 400 : 200
  end

  # Do all kinds of cache checks
  private def init_cache
    # if sha already passed, skip external calls
    unless @sha
      # only applies to well-known providers
      provider, owner, repo = ontleed_vcs @vcs_url
      return unless provider

      begin
        if provider == 'github.com'
          res = Net::HTTP.get URI("https://api.github.com/repos/#{owner}/#{repo}/commits")
          @sha = JSON.parse(res)[0]['sha']
        elsif provider == 'bitbucket.org'
          res = Net::HTTP.get URI("https://api.bitbucket.org/2.0/repositories/#{owner}/#{repo}/commits")
          @sha = JSON.parse(res)['values'][0]['hash']
        elsif provider == 'gitlab.com'
          res = Net::HTTP.get URI("https://gitlab.com/api/v4/projects/#{owner}%2F#{repo}/repository/commits")
          @sha = JSON.parse(res)[0]['id']
        end
      rescue JSON::ParserError, NoMethodError
        return # probably 404
      end
      return unless @sha
    end

    @db = connect_db
    stmt = @db.prepare('SELECT latest_commit, json_cache FROM loc_cache WHERE vcs_url = ?')
    row = stmt.execute(@vcs_url).first

    if row
      @cached = true
      lc = row['latest_commit']
      row['json_cache'] if lc == @sha
    else
      @cached = false
    end

  end

  # do the actual caching, if necessary
  private def finalise_cache
    return unless @db # will only be defined if something worth caching

    if @cached
      stmt = @db.prepare('UPDATE loc_cache SET latest_commit = ?, json_cache = ? WHERE vcs_url = ?')
      stmt.execute(@sha, @results.to_json, @vcs_url)
    else
      stmt = @db.prepare('INSERT INTO loc_cache(vcs_url, latest_commit, json_cache) VALUE (?, ?, ?)')
      stmt.execute(@vcs_url, @sha, @results.to_json)
    end
    @db.close
  end

  # get the VCS provider, owner, and repo from a url. Note only works for the big boy providers
  private def ontleed_vcs(url)
    # I know this isn't full proof, but life's too short
    return unless url.include?('github.com') || url.include?('bitbucket.org') || url.include?('gitlab.com')

    if url.start_with? 'https://'
      sep1 = url.index('/', 8)
      sep2 = url.index('/', sep1 + 1)
      [url[8..sep1-1], url[sep1+1..sep2-1], url[sep2+1..]]
    elsif url.start_with? 'http://'
      sep1 = url.index('/', 7)
      sep2 = url.index('/', sep1 + 1)
      [url[7..sep1-1], url[sep1+1..sep2-1], url[sep2+1..]]
    elsif url.start_with? 'git@'
      sep1 = url.index(':', 4)
      sep2 = url.index('/', sep1 + 1)
      [url[4..sep1-1], url[sep1+1..sep2-1], url[sep2+1..]]
    end  # else nil
  end
end