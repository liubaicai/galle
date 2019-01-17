Rails.application.routes.draw do
    # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
    
    root 'control_panel#index'
    get 'users/login'
    post 'users/login' => 'users#login_post'
    post 'users/logout' => 'users#logout_post'
    
    resources :servers
    resources :projects

    get 'live/checkserver' => 'live#check_server'
    get 'live/checkproject' => 'live#check_project'
  
end
  