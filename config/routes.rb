Rails.application.routes.draw do
  get "entrar", to: "sessions#new", as: :login
  post "entrar", to: "sessions#create"
  delete "sair", to: "sessions#destroy", as: :logout
  get "cadastro", to: "registrations#new", as: :signup
  post "cadastro", to: "registrations#create"

  root "dashboard#show"
  resources :study_cycles, only: [:index, :create, :update, :destroy], path: "ciclos" do
    member { patch :activate }
  end
  resources :cycle_subjects, only: [:index, :create, :edit, :update], path: "disciplinas" do
    member { patch :archive; patch :move_up; patch :move_down; patch :apply_suggestion }
  end
  resources :study_sessions, only: [:index, :new, :create, :edit, :update, :destroy], path: "sessoes"
end
