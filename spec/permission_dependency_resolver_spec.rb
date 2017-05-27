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
  let(:complex_permission_dependencies) do
    simple_permission_dependencies.merge({
      'audit' => ['create', 'delete'],
      'batch_update' => ['edit', 'create']
    })
  end
  let(:simple_pdr)  {PermissionDependencyResolver.new(simple_permission_dependencies)}
  let(:complex_pdr) {PermissionDependencyResolver.new(complex_permission_dependencies)}

  describe '#can_grant?' do
    it 'validates whether permissions can be granted given simple dependencies' do
      expect(simple_pdr.can_grant?(['view'], 'edit')).to eq true
      expect(simple_pdr.can_grant?(['view'], 'delete')).to eq false
      expect(simple_pdr.can_grant?(['view', 'edit'], 'alter_tags')).to eq true
      expect(simple_pdr.can_grant?(['view'], 'create')).to eq true
    end
    it 'validates whether permissions can be granted given complex dependencies' do
      expect(complex_pdr.can_grant?(['view', 'edit', 'delete'], 'batch_update')).to eq false
      expect(complex_pdr.can_grant?(['view', 'edit', 'create'], 'batch_update')).to eq true
      expect(complex_pdr.can_grant?(['view', 'edit', 'delete'], 'audit')).to eq false
      expect(complex_pdr.can_grant?(['view', 'edit', 'delete', 'create'], 'audit')).to eq true
    end
    it 'throws an exception when validating permissions if existing permissions are invalid' do
      expect{ complex_pdr.can_grant?(['edit', 'create'], 'alter_tags') }.to raise_error(InvalidBasePermissionsError)
    end
  end

  describe '#can_deny?' do
    it 'validates whether permissions can be denied given simple dependencies' do
      expect(simple_pdr.can_deny?(['view', 'edit'], 'view')).to eq false
      expect(simple_pdr.can_deny?(['view', 'edit'], 'edit')).to eq true
      expect(simple_pdr.can_deny?(['view', 'edit', 'create'], 'edit')).to eq true
      expect(simple_pdr.can_deny?(['view', 'edit', 'delete'], 'edit')).to eq false
    end
    it 'validates whether permissions can be denied given complex dependencies' do
      expect(complex_pdr.can_deny?(['view', 'edit', 'create', 'delete', 'audit'], 'audit')).to eq true
      expect(complex_pdr.can_deny?(['view', 'edit', 'create', 'delete', 'audit'], 'delete')).to eq false
      expect(complex_pdr.can_deny?(['view', 'edit', 'create', 'batch_update'], 'batch_update')).to eq true
      expect(complex_pdr.can_deny?(['view', 'edit', 'create', 'batch_update'], 'view')).to eq false
    end
    it 'throws an exception when validating permissions if existing permissions are invalid' do
      expect{ complex_pdr.can_deny?(['create', 'delete'], 'audit') }.to raise_error(InvalidBasePermissionsError)
    end
  end

  describe '#sort' do
    it 'can sort permissions in dependency order given simple dependencies' do
      valid_orderings = [
        ['view', 'create', 'edit', 'alter_tags'],
        ['view', 'edit', 'create', 'alter_tags'],
        ['view', 'edit', 'alter_tags', 'create']
      ]
      expect(simple_pdr.sort(['edit', 'delete', 'view'])).to eq ['view', 'edit', 'delete']
      expect(valid_orderings).to include(simple_pdr.sort(['create', 'alter_tags', 'view', 'edit']))
    end
    it 'can sort permissions in dependency order given complex dependencies' do
      valid_orderings = [
        ['view', 'edit', 'create', 'delete', 'audit'],
        ['view', 'create', 'edit', 'delete', 'audit'],
        ['view', 'edit', 'delete', 'create', 'audit']
      ]
      expect(valid_orderings).to include(complex_pdr.sort(['audit', 'create', 'delete', 'view', 'edit']))
    end
  end
end
