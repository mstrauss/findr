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
        raise MethodNotImplementedError.new("#{klass.class.name} needs to implement '#{method_name}' for StrategyProxy #{self.name}!")
      end

    end

    module ClassMethods

      def provides(method_name, *args)
        puts "providing method #{method_name} with args #{args.inspect}"
        this = self
        self.class_eval do
          define_method(method_name) do |*arg|
            begin
              @strategy.send(method_name, *arg)
            rescue NoMethodError
              this.does_not_implement_method(@strategy, method_name)
            end
          end
        end
      end

    end

  end

end
