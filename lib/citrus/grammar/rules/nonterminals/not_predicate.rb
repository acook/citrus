module Citrus
  module Grammar
    # A NotPredicate is a Nonterminal that contains a rule that must not match.
    # Upon success an empty match is returned and no input is consumed. The Citrus
    # notation is any expression preceded by an exclamation mark, e.g.:
    #
    #     !expr
    #
    class NotPredicate
      include Nonterminal

      def initialize(rule='')
        super([rule])
      end

      # Returns the Rule object this rule uses to match.
      def rule
        rules[0]
      end

      # Returns an array of events for this rule on the given +input+.
      def exec(input, events=[])
        unless input.test(rule)
          events << self
          events << CLOSE
          events << 0
        end

        events
      end

      # Returns the Citrus notation of this rule as a string.
      def to_citrus # :nodoc:
        '!' + rule.to_embedded_s
      end
    end
  end
end
