class LaboratoriesController < ApplicationController
  def list
    @laboratories = Laboratory.find(:all)
  end
end
