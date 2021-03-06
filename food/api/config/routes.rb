Rails.application.routes.draw do
  if Rails.env.development?
    default_url_options({
      protocol: 'https',
      host: ENV["HOST"],
      port: ENV["PORT"] })
  else
    default_url_options({
      protocol: 'https',
      host: ENV["HOST"]})
  end

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  resources :users, only: :update

  %i[
    categories
    nabes
    authors
  ].each do |resource_name|
    resources resource_name, only: :index
  end

  resources :places, only: %i[ index show ]

  resources :bookmarks, only: %i[ index show ]
  patch '/bookmarks(/:id)', controller: :bookmarks, action: :update


  # static pages
  get "/privacy", to: redirect("privacy.html")
  get "/tos", to: redirect("tos.html")

  get "/about", to: redirect(
    (ENV["APP_ABOUT_URL"] ||
     "https://medium.com/the-lenfest-local-lab"))

  get "/here", to: redirect(
    (ENV["APP_MARKETING_URL"] ||
     "https://testflight.apple.com/join/vqlIFhxI"))

  get "force_exception" => "application#force_exception"
end
