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


