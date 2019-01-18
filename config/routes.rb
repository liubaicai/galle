Rails.application.routes.draw do
    # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
    
    root 'control_panel#index'

    get 'users/login'
    get 'users/logout'
    post 'users/login' => 'users#login_post'
    post 'users/logout' => 'users#logout_post'
    
    resources :servers
    resources :projects
    resources :publishers
    resources :project_extend_files

    get 'status/cpu'

    get 'live/checkserver' => 'live#check_server'
    get 'live/checkoutproject' => 'live#checkout_project'
    get 'live/publishproject' => 'live#publish_project'
  
end
  