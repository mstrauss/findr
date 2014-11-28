module Findr
  # +StrategyProxy+
  # based on [AbstractInterface by Mark Bates](http://metabates.com/2011/02/07/building-interfaces-and-abstract-classes-in-ruby/)
  # and on [Contractual by Joseph Weissman](https://rubygems.org/gems/contractual)
  #
  # +include StrategyProxy+ to declare a class to be a +StrategyProxy+.
  # Also you need to define +@strategy+ in the initializer of your class and +@@strategy++ if you want to use +singleton_provides+.
  module StrategyProxy

    class MethodNotImplementedError < NoMethodError; end

    def self.included(klass)
      klass.send(:include, StrategyProxy::Methods)
      klass.send(:extend,  StrategyProxy::Methods)
      klass.send(:extend,  StrategyProxy::ClassMethods)
    end

    module Methods
      def does_not_implement_method(klass, method_name = nil)
        klass_name = klass.kind_of?(Class) ? klass.name : klass.class.name
        raise MethodNotImplementedError.new("#{klass_name} needs to implement '#{method_name}' for StrategyProxy #{self.class.name}!")
      end
    end

    module ClassMethods
      def provides(method_name, *argument_names)
        arglist = argument_names.map(&:to_sym).join(',')
        method_string = <<-END_METHOD
          def #{method_name}(#{arglist})
            @strategy.#{method_name}(#{arglist})
          rescue NoMethodError
            does_not_implement_method(@strategy, '#{method_name}')
          end
        END_METHOD
        class_eval method_string
      end

      # before using +singleton_provides+ you must define +@@strategy+ BEFORE FIRST USE of the defined singleton methods
      def singleton_provides(method_name, *argument_names)
        arglist = argument_names.map(&:to_sym).join(',')
        method_string = <<-END_METHOD
          def self.#{method_name}(#{arglist})
            @@strategy.#{method_name}(#{arglist})
          rescue NoMethodError
            does_not_implement_method(@@strategy, 'self.#{method_name}')
          end
        END_METHOD
        class_eval method_string
      end
    end

  end
end
