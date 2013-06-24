require_relative '../citrus'

module Citrus
  module Grammar
    module GrammarMethods
      def debug_parse(string, options={})
        rule_name = options.delete(:root) || root
        raise Error, "No root rule specified" unless rule_name
        rule = rule(rule_name)
        raise Error, "No rule named \"#{rule_name}\"" unless rule

        rule.debug_rule_parse(string, options)
      end
      #alias_method :old_parse, :parse
      #alias_method :parse, :debug_parse
    end

    module Rule
      def debug_rule_parse string, options = {}
        opts = default_options.merge(options)

        input = (opts[:memoize] ? MemoizedInput : Input).new(string)
        input.pos = opts[:offset] if opts[:offset] > 0

        events = input.exec(self)
        length = events[-1]

        #if !length || (opts[:consume] && length < (string.length - opts[:offset]))
        #  raise ParseError, input
        #end

        match = Match.new(string.slice(opts[:offset], length), events)

        [match, input, events]
      end
      #alias_method :old_parse, :parse
      #alias_method :parse, :debug_rule_parse
    end
  end
end
