require 'redmine'

Redmine::Plugin.register :cosmosys_poris_arch do
  directory File.expand_path(__dir__)
  name 'cosmoSys PORIS Architecture'
  author 'cosmoBots.eu'
  description 'Optional bindings between PORIS runtimes and architectural CAD degrees of freedom.'
  version '0.1.0'
  requires_redmine_plugin :cosmosys, version_or_higher: '0.2.8'
  requires_redmine_plugin :cosmosys_arch, version_or_higher: '0.1.3'
  requires_redmine_plugin :cosmosys_poris, version_or_higher: '0.2.4'
  permission :view_poris_arch, {'cosmosys_poris_arch/bindings' => %i[index show]}, public: true, read: true
  permission :manage_poris_arch, {'cosmosys_poris_arch/bindings' => %i[create update add_parameter remove_parameter command_policy]}, require: :member
  menu :project_menu, :cosmosys_poris_arch, {controller: 'cosmosys_poris_arch/bindings', action: 'index'},
    caption: 'PORIS ↔ CAD', param: :project_id, permission: :view_poris_arch,
    if: proc { |project| %w[architecture poris].include?(project&.csys_project_profile) }
end

require_dependency File.expand_path('lib/cosmosys_poris_arch/dispatcher', __dir__)
CosmosysPoris::RuntimeExecutionAdapters.register(:architecture) do |**context|
  CosmosysPorisArch::Dispatcher.new(**context).call
end
