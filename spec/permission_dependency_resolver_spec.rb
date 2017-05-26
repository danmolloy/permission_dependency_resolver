require 'spec_helper'

describe PermissionDependencyResolver do

  let(:simple_permission_dependencies) do
    {
      'view' => [],
      'edit' => ['view'],
      'alter_tags' => ['edit'],
      'create' => ['view'],
      'delete' => ['edit']
    }
  end

  it 'validates whether permissions can be granted given simple dependencies' do
    pdr = PermissionDependencyResolver.new(simple_permission_dependencies)
    expect(pdr.can_grant?(['view'], 'edit')).to eq true
    expect(pdr.can_grant?(['view'], 'delete')).to eq false
    expect(pdr.can_grant?(['view', 'edit'], 'alter_tags')).to eq true
    expect(pdr.can_grant?(['view'], 'create')).to eq true
  end

  it 'can sort permissions in dependency order given simple dependencies' do
    pdr = PermissionDependencyResolver.new(simple_permission_dependencies)

    expect(pdr.sort(['edit', 'delete', 'view'])).to eq ['view', 'edit', 'delete']
    valid_orderings = [['view', 'create', 'edit', 'alter_tags'],
                       ['view', 'edit', 'create', 'alter_tags'],
                       ['view', 'edit', 'alter_tags', 'create']]
    expect(valid_orderings).to include(pdr.sort(['create', 'alter_tags', 'view', 'edit']))
  end

  it 'validates whether permissions can be denied given simple dependencies' do
    pdr = PermissionDependencyResolver.new(simple_permission_dependencies)

    expect(pdr.can_deny?(['view', 'edit'], 'view')).to eq false
    expect(pdr.can_deny?(['view', 'edit'], 'edit')).to eq true
    expect(pdr.can_deny?(['view', 'edit', 'create'], 'edit')).to eq true
    expect(pdr.can_deny?(['view', 'edit', 'delete'], 'edit')).to eq false
  end

  let(:complex_permission_dependencies) do
    simple_permission_dependencies.merge({
      'audit' => ['create', 'delete'],
      'batch_update' => ['edit', 'create']
    })
  end

  it 'validates whether permissions can be granted given complex dependencies' do
    pdr = PermissionDependencyResolver.new(complex_permission_dependencies)
    expect(pdr.can_grant?(['view', 'edit', 'delete'], 'batch_update')).to eq false
    expect(pdr.can_grant?(['view', 'edit', 'create'], 'batch_update')).to eq true
    expect(pdr.can_grant?(['view', 'edit', 'delete'], 'audit')).to eq false
    expect(pdr.can_grant?(['view', 'edit', 'delete', 'create'], 'audit')).to eq true
  end

  it 'throws an exception when validating permissions if existing permissions are invalid' do
    pdr = PermissionDependencyResolver.new(complex_permission_dependencies)
    expect{ pdr.can_grant?(['edit', 'create'], 'alter_tags') }.to raise_error(InvalidBasePermissionsError)
    expect{ pdr.can_deny?(['create', 'delete'], 'audit') }.to raise_error(InvalidBasePermissionsError)
  end

  it 'can sort permissions in dependency order given complex dependencies' do
    pdr = PermissionDependencyResolver.new(complex_permission_dependencies)
    possible_orderings = [
      ['view', 'edit', 'create', 'delete', 'audit'],
      ['view', 'create', 'edit', 'delete', 'audit'],
      ['view', 'edit', 'delete', 'create', 'audit']
    ]
    expect(possible_orderings).to include(pdr.sort(['audit', 'create', 'delete', 'view', 'edit']))
  end

end
