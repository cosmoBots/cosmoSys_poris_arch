require_dependency File.join(Redmine::Plugin.find(:cosmosys_arch).directory, 'app/helpers/cosmosys_arch/cad_items_helper')

module CosmosysPorisArch
  module RuntimeViewHelper
    def render_poris_runtime_cad(project)
      runtime = CosmosysPoris::RuntimeModel.new(project, user: User.current)
      stored = CosmosysPoris::RuntimeSessionStore.new(controller.session, user: User.current).read
      runtime.restore(stored.fetch(project.id.to_s, []))
      state = runtime.state
      bindings = Binding.where(system_id: state.map { |row| row.fetch('node_id') }).includes(:system, :component).order(:id).select do |binding|
        binding.visible_to?(User.current) && User.current.allowed_to?(:view_poris_model, binding.system.project)
      end
      return if bindings.empty?
      binding = params[:cad_binding_id].present? ? bindings.find { |entry| entry.id.to_s == params[:cad_binding_id].to_s } : bindings.first
      return unless binding

      assigns = CosmosysArch::CadItemsHelper::Presentation.new(binding.component).assigns.merge(:@architecture_inline_issue => binding.component)
      singleton_class.prepend(CosmosysArch::CadItemsHelper::InlineFileUrl) unless singleton_class < CosmosysArch::CadItemsHelper::InlineFileUrl
      previous = assigns.keys.to_h { |name| [name, [instance_variable_defined?(name), instance_variable_get(name)]] }
      begin
        assigns.each { |name, value| instance_variable_set(name, value) }
        batch = Dispatcher.new(project: project, user: User.current, state: state, operations: [], observation: true).call.find { |entry| entry['binding_id'] == binding.id }
        render partial: 'cosmosys_poris_arch/runtime_view', locals: {project: project, binding: binding, bindings: bindings, initial_batch: batch}
      ensure
        previous.each do |name, (defined, value)|
          defined ? instance_variable_set(name, value) : remove_instance_variable(name)
        end
      end
    rescue Unauthorized
      nil
    rescue CosmosysArch::CadModel::Invalid => error
      content_tag(:p, error.message, class: 'warning')
    end
  end

  class RuntimeViewHooks < Redmine::Hook::ViewListener
    render_on :view_cosmosys_poris_runtime, partial: 'hooks/cosmosys_poris_arch/runtime_view'
  end
end

ActionView::Base.include(CosmosysPorisArch::RuntimeViewHelper)
