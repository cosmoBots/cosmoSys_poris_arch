require 'json'
module CosmosysPorisArch
  class ParameterLink < ActiveRecord::Base
    self.table_name = 'cosmosys_poris_arch_parameter_links'
    belongs_to :binding, class_name: 'CosmosysPorisArch::Binding'
    belongs_to :parameter, class_name: 'Issue'
    belongs_to :dof, class_name: 'Issue'
    attribute :discrete_values, :string, default: '{}'
    validates :dof_id, uniqueness: {scope: [:binding_id, :parameter_id]}
    validate :valid_mapping

    def discrete_mapping
      JSON.parse(discrete_values)
    end

    def converted_value(row)
      option = row['value_id'] && Issue.find_by(id: row['value_id'])
      raise ArgumentError, "#{parameter.csid}: no selected value of this parameter" unless option && option.parent_id == parameter.id
      # An explicit discrete translation takes precedence. Labels are never identifiers.
      input = discrete_mapping[option&.csid]
      input = row['data'] if input.nil? && option&.pr_value_kind == 'float'
      number = Float(input, exception: false) unless input.nil?
      raise ArgumentError, "#{parameter.csid}: selected value has no numeric translation" unless number&.finite?
      value = multiplier * number + offset
      unless value.finite? && value.between?(dof.arch_min, dof.arch_max)
        raise ArgumentError, "#{dof.csid}: converted value #{value} is outside CAD limits"
      end
      value
    end

    private

    def valid_mapping
      return unless binding && parameter && dof
      unless parameter.cosmosys_item_kind_key == 'poris_param' && binding.system_items.exists?(id: parameter.id)
        errors.add(:parameter, 'must belong to the bound PORIS system')
      end
      unless dof.cosmosys_item_kind_key == 'arch_dof' && binding.component_items.exists?(id: dof.id)
        errors.add(:dof, 'must belong to the bound component subtree')
      end
      errors.add(:base, 'Conversion coefficients must be finite') unless [multiplier, offset].all? { |n| n.is_a?(Numeric) && n.finite? }
      map = discrete_mapping
      unless map.is_a?(Hash) && map.all? { |key, value| key.is_a?(String) && value.is_a?(Numeric) && value.finite? }
        errors.add(:discrete_values, 'must map PORIS value CSIDs to finite numbers')
        return
      end
      options = parameter.children.select { |i| i.cosmosys_item_kind_key == 'poris_value' }.map(&:csid)
      errors.add(:discrete_values, 'contains a value outside this parameter') unless (map.keys - options).empty?
    rescue JSON::ParserError, TypeError
      errors.add(:discrete_values, 'must be valid JSON')
    end
  end
end
