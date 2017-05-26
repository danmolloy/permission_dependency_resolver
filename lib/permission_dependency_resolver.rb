require 'tsort'

class PermissionDependencyResolver
  include TSort
  def initialize(dependencies)
    @dependencies = dependencies
  end

  def can_grant?(existing, perm_to_be_granted)
    raise InvalidBasePermissionsError unless are_valid?(existing)
    @dependencies[perm_to_be_granted].all?{|dep| existing.include?(dep)}
  end

  def can_deny?(existing, perm_to_be_denied)
    raise InvalidBasePermissionsError unless are_valid?(existing)
    existing.none?{|perm| @dependencies[perm].include?(perm_to_be_denied)}
  end

  def sort(permissions)
    subset = @dependencies.select{|k, v| permissions.include?(k)}
    PermissionDependencyResolver.new(subset).tsort
  end

  

  private
  def tsort_each_child(node, &block)
    @dependencies[node].each(&block)
  end

  def tsort_each_node(&block)
    @dependencies.each_key(&block)
  end

  def are_valid?(permissions)
    permissions.each do |perm|
      @dependencies[perm].each do |dep|
        return false unless permissions.include?(dep)
      end
    end
  end
end
