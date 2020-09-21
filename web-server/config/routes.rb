Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root 'pages#show_home'

  # loc: allow any chars for provider, except a slash
  get '/api/loc/:provider/:user/:repo' => 'api#loc', :constraints => { provider: %r{[^/]+} }
  get '/(*url)', to: 'pages#not_found'
end
