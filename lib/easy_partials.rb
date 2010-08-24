module EasyPartials

  METHOD_REGEXP = /^_/

  def self.shared_directories
    @shared_directories || ["shared"]
  end

  def self.shared_directories=(arglist)
    @shared_directories = arglist
  end
end

require "easy_partials/object_additions"
require "easy_partials/helper_additions"
require 'easy_partials/controller_additions'
