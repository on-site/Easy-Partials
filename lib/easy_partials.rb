class Object
  # Obtain the metaclass of this object instance.
  def metaclass
    class << self
      self
    end
  end

  # Define an instance method using a symbol for the method name and a
  # block for the method contents.  This makes it so a closure can be
  # used to define a singleton method.
  def meta_def(name, &block)
    metaclass.send :define_method, name, &block
  end

  # Define an instance method using a block that will accept a block
  # as the first parameter, and the rest of the arguments as the
  # second.  This requires the block to have the first parameter act
  # as the block.
  #
  # For example:
  # o.meta_def_with_block(:say_hi) { |block, name|
  #   block.call
  #   puts "hello #{name}!"
  # }
  #
  # Will create a method that can be invoked as such:
  # o.say_hi("Mike") { puts "Saying hi:" }
  #
  # Implicitly, 2 methods are created... __real__say_hi, which is
  # created using the given block, and say_hi, which will accept the
  # arguments and block and pass them to __real__say_hi in reverse
  # order.
  def meta_def_with_block(name, &block)
    meta_def "__real__#{name}".to_sym, &block
    metaclass.instance_eval "
      def #{name}(*args, &block)
        __real__#{name} block, *args
      end
    "
  end
end

module EasyPartials
  def self.shared_directories
    @ep_shared_directories || ["shared"]
  end

  def self.shared_directories=(arglist)
    @ep_shared_directories = arglist
  end
end

module ApplicationHelper

  METHOD_REGEXP = /^_/

  alias_method :original_respond_to?, :respond_to?

  def respond_to?(method_name, inc_priv = false)
    return true if method_name =~ METHOD_REGEXP

    original_respond_to?(method_name, inc_priv)
  end

  alias_method :original_method_missing, :method_missing

  def method_missing(method_name, *args, &block)
    method_str = method_name.to_s

    if method_str.sub! METHOD_REGEXP, ''
      locations = [method_str]
      locations.push *additional_partials(method_str)
      new_method = partial_method locations, *args, &block
      meta_def_with_block method_name, &new_method
    else
      original_method_missing method_name, *args, &block
    end
  end

  def additional_partials(partial_name)
    @additional_partials ||= EasyPartials.shared_directories
    @additional_partials.map { |location| "#{location}/#{partial_name}" }
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
