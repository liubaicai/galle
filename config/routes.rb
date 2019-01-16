Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  
  root 'control_panel#index'
  get 'user/login'
  post 'user/login' => 'user#login_post'
  post 'user/logout' => 'user#logout_post'

end
