module Citrus
  module Grammar
    # A Repeat is a Nonterminal that specifies a minimum and maximum number of
    # times its rule must match. The Citrus notation is an integer, +N+, followed
    # by an asterisk, followed by another integer, +M+, all of which follow any
    # other expression, e.g.:
    #
    #     expr N*M
    #
    # In this notation +N+ specifies the minimum number of times the preceding
    # expression must match and +M+ specifies the maximum. If +N+ is ommitted,
    # it is assumed to be 0. Likewise, if +M+ is omitted, it is assumed to be
    # infinity (no maximum). Thus, an expression followed by only an asterisk may
    # match any number of times, including zero.
    #
    # The shorthand notation <tt>+</tt> and <tt>?</tt> may be used for the common
    # cases of <tt>1*</tt> and <tt>*1</tt> respectively, e.g.:
    #
    #     expr+
    #     expr?
    #
    class Repeat
      include Nonterminal

      def initialize(rule='', min=1, max=Infinity)
        raise ArgumentError, "Min cannot be greater than max" if min > max
        super([rule])
        @min = min
        @max = max
      end

      # Returns the Rule object this rule uses to match.
      def rule
        rules[0]
      end

      # Returns an array of events for this rule on the given +input+.
      def exec(input, events=[])
        events << self

        index = events.size
        start = index - 1
        length = n = 0

        while n < max && input.exec(rule, events).size > index
          length += events[-1]
          index = events.size
          n += 1
        end

        if n >= min
          events << CLOSE
          events << length
        else
          events.slice!(start, index)
        end

        events
      end

      # The minimum number of times this rule must match.
      attr_reader :min

      # The maximum number of times this rule may match.
      attr_reader :max

      # Returns the operator this rule uses as a string. Will be one of
      # <tt>+</tt>, <tt>?</tt>, or <tt>N*M</tt>.
      def operator
        @operator ||= case [min, max]
                      when [0, 0] then ''
                      when [0, 1] then '?'
                      when [1, Infinity] then '+'
                      else
                        [min, max].map {|n| n == 0 || n == Infinity ? '' : n.to_s }.join('*')
                      end
      end

      # Returns the Citrus notation of this rule as a string.
      def to_citrus # :nodoc:
        rule.to_embedded_s + operator
      end
    end
  end
end
