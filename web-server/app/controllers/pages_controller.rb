class PagesController < ApplicationController
  def show_home
    @title = 'LoCulator'
    @host = Rails.application.config.cfg['host_domain']
    render template: 'pages/home'
  end

  def not_found
    render file: 'public/404.html', status: :not_found
  end
end
