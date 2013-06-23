module Citrus
  module Grammar
    # A ButPredicate is a Nonterminal that consumes all characters until its rule
    # matches. It must match at least one character in order to succeed. The
    # Citrus notation is any expression preceded by a tilde, e.g.:
    #
    #     ~expr
    #
    class ButPredicate
      include Nonterminal

      DOT_RULE = Rule.for(DOT)

      def initialize(rule='')
        super([rule])
      end

      # Returns the Rule object this rule uses to match.
      def rule
        rules[0]
      end

      # Returns an array of events for this rule on the given +input+.
      def exec(input, events=[])
        length = 0

        until input.test(rule)
          len = input.exec(DOT_RULE)[-1]
          break unless len
          length += len
        end

        if length > 0
          events << self
          events << CLOSE
          events << length
        end

        events
      end

      # Returns the Citrus notation of this rule as a string.
      def to_citrus # :nodoc:
        '~' + rule.to_embedded_s
      end
    end
  end
end
