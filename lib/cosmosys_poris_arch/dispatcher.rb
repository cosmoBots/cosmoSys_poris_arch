module CosmosysPorisArch
  # Produces validated, session-local actuation batches. No global CAD pose,
  # hardware calls, broker or persisted item defaults are changed here.
  class Dispatcher
    def initialize(project:, user:, state:, operations:)
      @project, @user, @state, @operations = project, user, state, operations
    end

    def call
      return [] unless @operations.all? { |operation| operation['accepted'] }
      state = @state.index_by { |row| row.fetch('node_id').to_i }
      bindings = Binding.where(system_id: state.keys).includes(:system, :component)
      bindings.filter_map do |binding|
        next unless binding.visible_to?(@user)
        next unless @user.admin? || @user.allowed_to?(:view_poris_model, binding.system.project)
        next unless triggered?(binding)
        begin
          raise ArgumentError, binding.errors.full_messages.join('; ') unless binding.valid?
          links = binding.parameter_links.includes(:parameter, :dof).to_a
          raise ArgumentError, 'No parameter mappings configured' if links.empty?
          values = {}
          links.each do |link|
            raise ArgumentError, 'A mapped item is not visible' unless link.parameter.visible?(@user) && link.dof.visible?(@user)
            raise ArgumentError, link.errors.full_messages.join('; ') unless link.valid?
            row = state.fetch(link.parameter_id) { raise ArgumentError, "#{link.parameter.csid}: parameter not in runtime" }
            # Consume the reconciled runtime, never the panel's draft or stale
            # data left in an Unknown row. Unknown means no actuation, not zero.
            next if row['mode_id'].to_s == "unknown:#{link.parameter_id}"
            if values.key?(link.dof.csid)
              raise ArgumentError, "#{link.dof.csid}: multiple active parameters target this CAD degree of freedom"
            end
            values[link.dof.csid] = link.converted_value(row)
          end
          next if values.empty?
          {'binding_id' => binding.id, 'component_csid' => binding.component.csid, 'status' => 'prepared', 'values' => values}
        rescue ArgumentError => error
          {'binding_id' => binding.id, 'status' => 'rejected', 'reason' => error.message}
        end
      end
    end

    private

    def triggered?(binding)
      commands = @operations.select { |operation| operation['type'] == 'invoke_command' }
      return true if binding.trigger == 'commit' # A command request may include a commit: one batch only.
      allowed_ids = binding.system_items.select(:id)
      commands.any? do |operation|
        command = Issue.find_by(id: operation['command_id'])
        next false unless command && allowed_ids.exists?(id: command.id)
        binding.command_policies.find_by(command_id: command.id)&.actuation != false
      end
    end
  end
end
