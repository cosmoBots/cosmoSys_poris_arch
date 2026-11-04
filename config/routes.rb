scope 'projects/:project_id/poris-arch', module: 'cosmosys_poris_arch' do
  get '/', to: 'bindings#index', as: :poris_arch_bindings
  post '/', to: 'bindings#create'
  get '/:id', to: 'bindings#show', as: :poris_arch_binding
  post '/:id', to: 'bindings#update'
  post '/:id/parameters', to: 'bindings#add_parameter', as: :poris_arch_parameters
  post '/:id/parameters/:link_id/remove', to: 'bindings#remove_parameter', as: :poris_arch_remove_parameter
  post '/:id/commands/:command_id', to: 'bindings#command_policy', as: :poris_arch_command_policy
end
