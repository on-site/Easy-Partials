module EasyPartials

  # This module is automatically included into all controllers.
  module ControllerAdditions
    module ClassMethods

      # Add additional partial locations for the auto finding of partials
      # (via the <% _partial_name %> mechanism).  This can be a single
      # partial directory, or a list of them.  Each value should be a
      # directory relative to the views directory, and should NOT contain
      # a trailing "/".  The order the directories are added is the order
      # they will be checked, however the local path will still be checked
      # first (the global shared directory will be checked after all these
      # additional directories).
      #
      # For example:
      #
      #   additional_partials "shared/forms"
      #   additional_partials "shared/accounting", "shared_accounting"
      def additional_partials(*locations)
        before_filter do |controller|
          controller.instance_variable_set :@additional_partials, (locations + EasyPartials.shared_directories).flatten.uniq
        end
      end

    end

    def self.included(base)
      base.extend ClassMethods
    end
  end

end

if defined? ActionController
  ActionController::Base.class_eval do
    include EasyPartials::ControllerAdditions
  end
end
