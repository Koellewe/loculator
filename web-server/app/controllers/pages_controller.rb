class PagesController < ApplicationController
  def show_home
    @title = 'LoCulator'
    render template: "pages/home"
  end
end
