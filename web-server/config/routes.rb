Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root 'pages#show_home'
  get '/documentation' => 'pages#docs'
  get '/legal' => 'pages#legal'

  # loc: allow any chars for provider, except a slash
  get '/api/loc/:provider/:user/:repo' => 'api#loc_std', :constraints => { provider: %r{[^/]+} }
  # get '/api/loc' => 'api#loc_specified'  # disabling this for safety issues for now
  get '/(*url)', to: 'pages#not_found'
end
