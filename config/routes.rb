Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  #
  get "/saml/metadata" => "saml#metadata"
  get "/saml/auth" => "saml#auth"
end
