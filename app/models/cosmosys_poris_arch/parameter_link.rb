module CosmosysPorisArch
  class ParameterLink < ActiveRecord::Base
    self.table_name = 'cosmosys_poris_arch_parameter_links'
    belongs_to :binding, class_name: 'CosmosysPorisArch::Binding'
    belongs_to :parameter, class_name: 'Issue'
    belongs_to :dof, class_name: 'Issue'
    validates :dof_id, uniqueness: {scope: [:binding_id, :parameter_id]}
    validate :valid_mapping

    def converted_value(row)
      option = row['value_id'] && Issue.find_by(id: row['value_id'])
      raise ArgumentError, "#{parameter.csid}: no selected value of this parameter" unless option && option.parent_id == parameter.id
      # Both ranges and enumerations arrive as confirmed runtime data. The
      # bridge neither resolves project variables nor stores a second mapping.
      input = row['data'] if %w[float enum].include?(option.pr_value_kind)
      number = Float(input, exception: false) unless input.nil?
      unless number&.finite?
        raise ArgumentError, "#{parameter.csid} (#{parameter.subject}): selected value has no numeric translation " \
          "(selected: #{option.subject} [#{option.csid}]; kind: #{option.pr_value_kind}; " \
          "runtime data: #{row['data'].inspect[0, 120]})"
      end
      product = multiplier * number
      value = product + offset
      if value.finite?
        return value if value.between?(dof.arch_min, dof.arch_max)

        # Cancellation in m*x+h can leave a few floating-point bits beyond a
        # boundary (especially zero). Snap only that arithmetic roundoff, at
        # the scale of the operands and the approached boundary, not CAD step.
        boundary = value < dof.arch_min ? dof.arch_min : dof.arch_max
        tolerance = 8 * Float::EPSILON * [product.abs, offset.abs, boundary.abs].max
        return boundary if (value - boundary).abs <= tolerance
      end
      raise ArgumentError, "#{dof.csid}: converted value #{value} is outside CAD limits"
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
      coefficients = [multiplier_before_type_cast, offset_before_type_cast].map { |value| Float(value, exception: false) }
      errors.add(:base, 'Conversion coefficients must be finite') unless coefficients.all? { |value| value&.finite? }
    end
  end
end
