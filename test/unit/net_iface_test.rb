require 'test_helper'
require 'catalog_test_helper'

class NetIfaceTest < ActiveSupport::TestCase
  include CatalogTestHelper
  def setup
    @model = NetIface
  end
end
