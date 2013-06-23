module Citrus
  module Grammar
    # A Sequence is a Nonterminal where all rules must match. The Citrus notation
    # is two or more expressions separated by a space, e.g.:
    #
    #     expr expr
    #
    class Sequence
      include Nonterminal

      # Returns an array of events for this rule on the given +input+.
      def exec(input, events=[])
        events << self

        index = events.size
        start = index - 1
        length = n = 0
        m = rules.length

        while n < m && input.exec(rules[n], events).size > index
          length += events[-1]
          index = events.size
          n += 1
        end

        if n == m
          events << CLOSE
          events << length
        else
          events.slice!(start, index)
        end

        events
      end

      # Returns the Citrus notation of this rule as a string.
      def to_citrus # :nodoc:
        rules.map {|r| r.to_embedded_s }.join(' ')
      end
    end
  end
end
