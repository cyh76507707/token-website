Rails.application.routes.draw do
  root 'home#index'

  get '/:locale', to: 'home#index'
end
