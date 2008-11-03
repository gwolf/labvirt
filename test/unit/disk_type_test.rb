require 'test_helper'
require 'catalog_test_helper'

class DiskTypeTest < ActiveSupport::TestCase
  include CatalogTestHelper
  def setup
    @model = DiskType
  end
end
