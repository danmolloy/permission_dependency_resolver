require 'tsort'

class PermissionDependencyResolver
  include TSort
  def initialize(deps)
    raise InvalidDependencyStructureError unless well_structured?(deps) && !cyclic?(deps)
    @deps = deps
  end

  def can_grant?(existing, perm_to_be_granted)
    raise InvalidBasePermissionsError unless are_valid?(existing)
    @deps[perm_to_be_granted].all?{|dep| existing.include?(dep)}
  end

  def can_deny?(existing, perm_to_be_denied)
    raise InvalidBasePermissionsError unless are_valid?(existing)
    existing.none?{|perm| @deps[perm].include?(perm_to_be_denied)}
  end

  def sort(permissions)
    @to_sort = @deps.select{|k, v| permissions.include?(k)}
    self.tsort
  end



  private
  def tsort_each_child(node, &block)
    @to_sort[node].each(&block)
  end

  def tsort_each_node(&block)
    @to_sort.each_key(&block)
  end

  def are_valid?(permissions)
    permissions.each do |perm|
      @deps[perm].each do |dep|
        return false unless permissions.include?(dep)
      end
    end
  end

  def cyclic?(deps)
    @to_sort = deps
    begin
      self.tsort
    rescue TSort::Cyclic
      return true
    end
    false
  end

  def well_structured?(deps)
    deps.is_a?(Hash) && deps.all?{|k, v| k.is_a?(String) && v.is_a?(Array)}
  end
end
