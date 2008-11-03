require 'test_helper'
require 'catalog_test_helper'

class MediaTypeTest < ActiveSupport::TestCase
  include CatalogTestHelper
  def setup
    @model = MediaType
  end
end
