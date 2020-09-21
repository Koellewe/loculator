require 'docker'

class ApiController < ApplicationController
  def loc
    # todo rate limiting
    # todo caching
    # todo vcs_url parameter

    vcs_url = if params['private'] == 'true' or params['private'] == '1'
                "git@#{params['provider']}:#{params['user']}/#{params['repo']}"
              else
                "https://#{params['provider']}/#{params['user']}/#{params['repo']}"
              end

    @jsonout = {'vcs_url' => vcs_url}

    tag = Rails.env == 'production' ? 'stable' : 'unstable'
    ssh_path = Rails.application.config.cfg['ssh_key_path']
    # counter = Docker::Image.create('fromImage' => "koellewe/loculator:#{tag}")
    counter = Docker::Container.create('Image' => "koellewe/loculator:#{tag}",
                                       'Env' => ["VCS_URL=#{vcs_url}"],
                                       'HostConfig' => { 'Binds' => ["#{ssh_path}:/mnt/creds"] }
                                       )

    res = counter.tap(&:start).attach(stdin: nil)

    # res = `docker run -e "VCS_URL=#{vcs_url}" -v "#{config.cfg['ssh_key_path']}:/mnt/creds" koellewe/loculator:#{tag}`

    @jsonout['res'] = res

    render 'api/default.json'
  end
end
