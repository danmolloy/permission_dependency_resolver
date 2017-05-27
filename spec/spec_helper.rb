require File.expand_path("../../lib/invalid_base_permissions_error", __FILE__)
require File.expand_path("../../lib/invalid_dependency_structure_error", __FILE__)
require File.expand_path("../../lib/permission_dependency_resolver", __FILE__)

RSpec.configure do |config|
  config.color = true
  config.add_formatter 'documentation'
end
