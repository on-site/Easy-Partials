module EasyPartials

  module HelperAdditions

    def method_missing(method_name, *args, &block)
      method_str = method_name.to_s
      return super unless method_str.sub! METHOD_REGEXP, ''
      locations = [method_str]
      locations.push *additional_partials(method_str)

      begin
        new_method = partial_method locations, *args, &block
        meta_def_with_block method_name, &new_method
      rescue ActionView::MissingTemplate
        super
      end
    end

    def additional_partials(partial_name)
      (@additional_partials || EasyPartials.shared_directories).map { |location| "#{location}/#{partial_name}" }
    end

    # Utility method to create and invoke a Proc which will concat the
    # partial given the possible locations.  The Proc is then returned
    # so it can be added as a new method for caching purposes (otherwise
    # method_missing will have to be invoked each time the partial is
    # invoked).  The locations parameter is modified in the process.
    # This is used by method_missing.
    def partial_method(locations, *args, &block)
      raise "No possible locations!" if locations.empty?
      partial_name = locations.delete_at 0
      new_method = lambda do |block, *args|
        if params[:format] == "pdf"
          invoke_partial partial_name, *args, &block
        else
          concat_partial partial_name, *args, &block
        end
      end
      begin
        new_method.call block, *args
      rescue ActionView::MissingTemplate
        if locations.empty?
          raise
        else
          new_method = partial_method locations, *args, &block
        end
      end

      new_method
    end

    def invoke_partial(partial, *args, &block)
      locals = {}

      if args.length == 1 && args[0].is_a?(Hash)
        locals.merge! args[0]
      else
        locals.merge! :args => args
      end

      locals.merge! :body => capture(&block) if block
      locals[:body] = nil unless locals[:body]

      if locals.has_key? :collection
        return "" if locals[:collection].blank?
        render :partial => partial.to_s, :collection => locals[:collection],
               :locals => locals.except(:collection)
      else
        render :partial => partial.to_s, :locals => locals
      end

    end

    # Used to create nice templated "tags" while keeping the html out of
    # our helpers.  Additionally, this can be invoked implicitly by
    # invoking the partial as a method with "_" prepended to the name.
    #
    # Invoking the method:
    #
    #   <% concat_partial "my_partial", { :var => "value" } do %>
    #     <strong>Contents stored as a "body" local</strong>
    #   <% end %>
    #
    # Or invoking implicitly:
    #
    #   <% _my_partial :var => "value" do %>
    #     <strong>Contents stored as a "body" local</strong>
    #   <% end %>
    #
    # Note that with the implicit partials the partial will first be
    # searched for locally within the current view directory, and then
    # additional directories defined by the controller level
    # 'additional_partials' method, and finally within the views/shared
    # directory.
    def concat_partial(partial, *args, &block)
      rendered = invoke_partial partial, *args, &block
      concat rendered
    end

  end

end

module ApplicationHelper
  include EasyPartials::HelperAdditions
end
