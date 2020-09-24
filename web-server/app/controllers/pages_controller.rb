class PagesController < ApplicationController
  def show_home
    @title = 'LoCulator'
    @host = Rails.application.config.cfg['host_domain']
    render template: 'pages/home'
  end

  def docs
    @title = 'LoCulator Documentation'
    @host = Rails.application.config.cfg['host_domain']
    pubkey_path = Rails.application.config.cfg['ssh_key_path'] + '/' +
                  Rails.application.config.cfg['ssh_key_name'] + '.pub'
    @public_key = File.read(pubkey_path)
    render template: 'pages/docs'
  end

  def not_found
    render file: 'public/404.html', status: :not_found
  end
end
