Rails.application.routes.draw do
  root "channels#index"
  resources :channels, except: [:edit, :update]

  get 'sign_in', to: 'session#new', as: 'sign_in'
  delete 'sign_out', to: 'session#destroy', as: 'sign_out'
  get 'auth/:provider/callback', to: 'session#create'
end
