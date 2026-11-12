require_dependency File.join(Redmine::Plugin.find(:cosmosys_arch).directory, 'lib/cosmosys_arch/cad_viewer')

module CosmosysPorisArch
  class BindingsController < ApplicationController
    include CosmosysArch::CadViewer
    helper_method :cad_preview_file_path
    before_action :find_project
    before_action :authorize
    before_action :find_binding, except: %i[index create]
    before_action :require_edit, except: %i[index show create]
    rescue_from ActiveRecord::RecordInvalid, ArgumentError, with: :invalid_binding
    rescue_from CosmosysArch::CadModel::Invalid do |error|
      render_error message: error.message, status: 422
    end

    def index
      ids = @project.root.self_and_descendants.select(:id)
      @bindings = Binding.joins(:system).where(issues: {project_id: ids}).includes(:system, :component).select { |b| b.visible_to?(User.current) }
    end

    def create
      binding = Binding.new(system: resolve_csid(params.require(:system_csid)), component: resolve_csid(params.require(:component_csid)), trigger: params[:trigger].presence || 'command')
      raise Unauthorized unless binding.editable_by?(User.current)
      binding.save!
      redirect_to poris_arch_binding_path(@project, binding)
    end

    def show
      @parameters = @binding.system_items.includes(:tracker).select { |i| i.cosmosys_item_kind_key == 'poris_param' && i.visible?(User.current) }
      @dofs = @binding.component_items.includes(:tracker).select { |i| i.cosmosys_item_kind_key == 'arch_dof' && i.visible?(User.current) }
      @commands = @binding.system_items.includes(:tracker).select { |i| i.cosmosys_item_kind_key == 'poris_cmd' && i.visible?(User.current) }
      runtime = CosmosysPoris::RuntimeModel.new(@binding.system.project, user: User.current)
      store = CosmosysPoris::RuntimeSessionStore.new(session, user: User.current).read
      runtime.restore(store.fetch(@binding.system.project_id.to_s, []))
      @runtime_state = runtime.state
      @model_xml = CosmosysPoris::ModelXmlExporter.new(@binding.system.project, user: User.current, scope: 'node_down', issue: @binding.system).render
      @issue = @binding.component
      prepare_architecture_view
      response.headers['Cache-Control'] = 'private, no-store'
    end

    def update
      @binding.update!(trigger: params.require(:trigger))
      redirect_to poris_arch_binding_path(@project, @binding)
    end

    def add_parameter
      @binding.parameter_links.create!(parameter_link_attributes)
      redirect_to poris_arch_binding_path(@project, @binding)
    end

    def update_parameter
      link = @binding.parameter_links.find(params[:link_id])
      raise Unauthorized unless link.parameter.visible?(User.current) && link.dof.visible?(User.current)

      link.update!(parameter_link_attributes)
      redirect_to poris_arch_binding_path(@project, @binding)
    end

    def remove_parameter
      @binding.parameter_links.find(params[:link_id]).destroy!
      redirect_to poris_arch_binding_path(@project, @binding)
    end

    def command_policy
      policy = @binding.command_policies.find_or_initialize_by(command: resolve_command)
      policy.actuation = ActiveModel::Type::Boolean.new.cast(params.require(:actuation))
      policy.save!
      redirect_to poris_arch_binding_path(@project, @binding)
    end

    private

    def find_project
      @project = Project.find(params[:project_id])
    end

    def find_binding
      @binding = Binding.find(params[:id])
      raise ActiveRecord::RecordNotFound unless @binding.system.project.root.id == @project.root.id && @binding.visible_to?(User.current)
    end

    def require_edit
      raise Unauthorized unless @binding.editable_by?(User.current)
    end

    def resolve_csid(csid)
      matches = Issue.where(project_id: @project.root.self_and_descendants.select(:id), csid: csid).to_a
      raise ArgumentError, "CSID unavailable or ambiguous: #{csid}" unless matches.one? && matches.first.visible?(User.current)
      matches.first
    end

    def parameter_link_attributes
      {parameter: resolve_csid(params.require(:parameter_csid)), dof: resolve_csid(params.require(:dof_csid)),
        multiplier: params.require(:multiplier), offset: params.require(:offset)}
    end

    def resolve_command
      command = @binding.system_items.find(params[:command_id])
      raise Unauthorized unless command.visible?(User.current)
      command
    end

    def invalid_binding(error)
      flash[:error] = error.message
      redirect_to(@binding ? poris_arch_binding_path(@project, @binding) : poris_arch_bindings_path(@project))
    end
  end
end
