require 'docker'
require 'net/http'
require 'uri'
require 'json'

# Controller for the API
class ApiController < ApplicationController
  # removing this for safety issues for now
  # def loc_specified
  #   if params['vcs_url']
  #     @vcs_url = params['vcs_url']
  #     @sha = params['latest_commit']
  #     loc_impl
  #   else
  #     @error = 'You must either specify the vcs url by slash-separation, or as a direct parameter'
  #     render 'api/err.json', status: 400
  #   end
  # end

  def loc_std
    @private = (params['private'] == 'true') || (params['private'] == '1')
    @provider = params['provider']
    @user = params['user']
    @repo = params['repo']
    @vcs_url = if @private
                 "git@#{@provider}:#{@user}/#{@repo}"
               else
                 "https://#{@provider}/#{@user}/#{@repo}"
               end
    @sha = params['latest_commit'] # nullable
    loc_impl
  end

  private def loc_impl
    # todo rate limiting

    json_cache = init_cache
    @results = JSON.parse(json_cache) if json_cache

    cache_record = LocCache.find_by(vcs_url: @vcs_url)

    if @cache_hit
      render 'api/loc.json', status: cache_record['running'] ? 202 : 200
    elsif @sha
      # queue counting job
      LocJob.perform_later @vcs_url, @sha
      cache_record['running'] = true
      cache_record.save!
      render 'api/loc.json', status: 202
    else
      # no sha available and no cache
      @results = nil
      render 'api/loc.json', status: 200
    end
  end

  # Do all kinds of cache checks
  private def init_cache
    # if sha already passed or private repo, skip external calls
    unless @sha || @private
      # only applies to well-known providers
      @cache_hit = false # by default
      return unless @provider == 'github.com' || @provider == 'bitbucket.org' || @provider == 'gitlab.com'

      begin
        if @provider == 'github.com'
          res = Net::HTTP.get URI("https://api.github.com/repos/#{@user}/#{@repo}/commits")
          @sha = JSON.parse(res)[0]['sha']
        elsif @provider == 'bitbucket.org'
          res = Net::HTTP.get URI("https://api.bitbucket.org/2.0/repositories/#{@user}/#{@repo}/commits")
          @sha = JSON.parse(res)['values'][0]['hash']
        elsif @provider == 'gitlab.com'
          res = Net::HTTP.get URI("https://gitlab.com/api/v4/projects/#{@owner}%2F#{@repo}/repository/commits")
          @sha = JSON.parse(res)[0]['id']
        end
      rescue JSON::ParserError, NoMethodError, Net::OpenTimeout, Net::TimeOutError
        return nil # either 404 or flaky VCS API
      end
    end

    row = LocCache.find_by(vcs_url: @vcs_url)
    if row
      @cached_sha = row['latest_commit']
      jcache = row['json_cache']
      if row['running']
        @cache_hit = true
        jcache
      else
        @cache_hit = @private && !@sha ? true : @cached_sha == @sha # force true if private and no sha provided
        jcache
      end
    else
      LocCache.create(vcs_url: @vcs_url, latest_commit: nil, json_cache: nil)
      @cache_hit = false
      nil
    end

  end

  # get the VCS provider, owner, and repo from a url. Note only works for the big boy providers
  # private def ontleed_vcs(url)
  #   # I know this isn't full proof, but life's too short
  #   return unless url.include?('github.com') || url.include?('bitbucket.org') || url.include?('gitlab.com')
  #
  #   if url.start_with? 'https://'
  #     sep1 = url.index('/', 8)
  #     sep2 = url.index('/', sep1 + 1)
  #     [url[8..sep1-1], url[sep1+1..sep2-1], url[sep2+1..]]
  #   elsif url.start_with? 'http://'
  #     sep1 = url.index('/', 7)
  #     sep2 = url.index('/', sep1 + 1)
  #     [url[7..sep1-1], url[sep1+1..sep2-1], url[sep2+1..]]
  #   elsif url.start_with? 'git@'
  #     sep1 = url.index(':', 4)
  #     sep2 = url.index('/', sep1 + 1)
  #     [url[4..sep1-1], url[sep1+1..sep2-1], url[sep2+1..]]
  #   end  # else nil
  # end
end
