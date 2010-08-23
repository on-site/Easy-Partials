module EasyPartials
  def self.shared_directories
    @ep_shared_directories || ["shared"]
  end

  def self.shared_directories=(arglist)
    @ep_shared_directories = arglist
  end
end

require "easy_partials/object_additions"
require "easy_partials/helpr_additions"
require 'easy_partials/controller_additions'

