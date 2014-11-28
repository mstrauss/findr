module Findr

  # +StrategyProxy+
  # based on [AbstractInterface by Mark Bates](http://metabates.com/2011/02/07/building-interfaces-and-abstract-classes-in-ruby/)
  # and on [Contractual by Joseph Weissman](https://rubygems.org/gems/contractual)
  module StrategyProxy

    class MethodNotImplementedError < NoMethodError; end

    def self.included(klass)
      klass.send(:include, StrategyProxy::Methods)
      klass.send(:extend,  StrategyProxy::Methods)
      klass.send(:extend,  StrategyProxy::ClassMethods)
    end

    module Methods

      def does_not_implement_method(klass, method_name = nil)
        if method_name.nil?
          caller.first.match(/in \`(.+)\'/)
          method_name = $1
        end
        raise MethodNotImplementedError.new("#{klass.class.name} needs to implement '#{method_name}' for StrategyProxy #{self.class.name}!")
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

    end

  end

end
