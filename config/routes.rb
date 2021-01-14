Rails.application.routes.draw do
  root to: "home#detect_language"
  get "/wake_up", to: "home#wake_up"

  scope "(:locale)", locale: /en|es/ do
    resource :session, only: %i[ new create destroy ]
    resources :users, only: %i[ new create ]
    resource :contact, controller: :contact, only: %i[ show create ]

    root to: "home#show", as: :home_root

    get "*path", to: "home#not_found", constraints: ->(request) do
      !request.xhr? && request.format.html?
    end
  end

  get "*path", to: "home#detect_language", constraints: ->(request) do
    !request.xhr? && request.format.html?
  end
end
