Rails.application.routes.draw do
  get 'authentication_details/authentication_details'
  get 'attendant_details/attendat_details'
  get 'financial_details/financial_info'
  get 'messages/send'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  namespace :api do
      get 'authentication_details/authentication_details'
      get 'attendant_details/attendat_details'
      get 'financial_details/financial_info'
      get 'messages/send'
      post 'login', to: 'authentication#login'
      get 'atendimentos/search', to: 'atendimentos#search'
      get 'atendimentos/search/contract/:contract_number', to: 'atendimentos#search_by_contract'
      get 'atendimentos/search/cpf/:cpf', to: 'atendimentos#search_by_cpf'
      get 'atendimentos/search/name/:name', to: 'atendimentos#search_by_name'
      post 'send/message', to: 'messages#send_message'
      get 'contracts', to: 'contracts#search'
      get 'contracts/:contract/details', to: 'contracts#details'
      get '/financial_info/:contract_id', to: 'financial_details#financial_info'
      get '/assignments/:contract_id', to: 'attendant_details#attendant_details'
      get '/equipment/:connection', to: 'authentication_details#authentication_details'
      post '/equipment/execute_command', to: 'equipment_command#execute_command'
      post '/olt_command/', to: 'olt_command#execute_command', as: 'olt_command'
      get '/equipamento/:id', to: 'olt_connection#equipment_ip'
      get '/olt_id/:equipment_serial_number', to: 'olt_title#find_id_by_serial'
      get '/valid_olts', to: 'olt_valid_list#valid_olts'
      get '/get_id', to: 'connection_integration_voalle#get_id'
      get '/pon_analitycs', to: 'pon_analitycs#execute_command'
      # Adicione mais rotas aqui conforme necessário
  end

  namespace :signin do
    post 'login', to: 'login#create'
  end  

end


