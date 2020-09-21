require 'docker'

class ApiController < ApplicationController
  def loc_specified
    if params['vcs_url']
      @vcs_url = params['vcs_url']
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
    loc_impl
  end

  private def loc_impl
    # todo rate limiting
    # todo caching (public only)
    # todo vcs_url parameter
    # todo increase timeout

    tag = Rails.env == 'production' ? 'stable' : 'unstable'
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
      end
    rescue JSON::ParseError
      @error = 'Unknown runtime error occurred during line-counting.'
    end

    render 'api/loc.json', status: @error ? 400 : 200
  end
end
