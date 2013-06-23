module Citrus
  module Grammar
    # A Choice is a Nonterminal where only one rule must match. The Citrus
    # notation is two or more expressions separated by a vertical bar, e.g.:
    #
    #     expr | expr
    #
    class Choice
      include Nonterminal

      # Returns an array of events for this rule on the given +input+.
      def exec(input, events=[])
        events << self

        index = events.size
        n = 0
        m = rules.length

        while n < m && input.exec(rules[n], events).size == index
          n += 1
        end

        if index < events.size
          events << CLOSE
          events << events[-2]
        else
          events.pop
        end

        events
      end

      # Returns +true+ if this rule should extend a match but should not appear in
      # its event stream.
      def elide? # :nodoc:
        true
      end

      # Returns the Citrus notation of this rule as a string.
      def to_citrus # :nodoc:
        rules.map {|r| r.to_embedded_s }.join(' | ')
      end
    end
  end
end
