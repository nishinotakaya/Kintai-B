  Rails.application.routes.draw do
  

    root 'static_pages#top'
    get '/signup', to: 'staffrs#new'
  
    # ログイン機能
    get    '/login', to: 'sessions#new'
    post   '/login', to: 'sessions#create'
    delete '/logout', to: 'sessions#destroy'
    
  
    resources :staffs do
      member do
       
       
      end
    end
    post '/import', to: 'users#import', as: 'import'
    
    resources :clients do#利用者
      member do
        get 'edit_basic_info'
        patch 'update_basic_info'
      end
      
      resources :monitorings, only: :update do #モニタリング
        member do #idが付く！memberは特定のデータにアクションを利用する
        get 'monitoring_basic_info' #モニタリング編集
        post 'create_monitoring_basic_info'
        get 'monitoring_basic_info_affter' #過去のモニタリング
        end
      end    
    end
    
      
                   
    
  end
    
      
      
    