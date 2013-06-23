module Citrus
  module Grammar
    # A Terminal is a Rule that matches directly on the input stream and may not
    # contain any other rule. Terminals are essentially wrappers for regular
    # expressions. As such, the Citrus notation is identical to Ruby's regular
    # expression notation, e.g.:
    #
    #     /expr/
    #
    # Character classes and the dot symbol may also be used in Citrus notation for
    # compatibility with other parsing expression implementations, e.g.:
    #
    #     [a-zA-Z]
    #     .
    #
    # Character classes have the same semantics as character classes inside Ruby
    # regular expressions. The dot matches any character, including newlines.
    class Terminal
      include Rule

      def initialize(regexp=/^/)
        @regexp = regexp
      end

      # The actual Regexp object this rule uses to match.
      attr_reader :regexp

      # Returns an array of events for this rule on the given +input+.
      def exec(input, events=[])
        match = input.scan(@regexp)

        if match
          events << self
          events << CLOSE
          events << match.length
        end

        events
      end

      # Returns +true+ if this rule is case sensitive.
      def case_sensitive?
        !@regexp.casefold?
      end

      def ==(other)
        case other
        when Regexp
          @regexp == other
        else
          super
        end
      end

      alias_method :eql?, :==

        # Returns +true+ if this rule is a Terminal.
        def terminal? # :nodoc:
          true
        end

      # Returns the Citrus notation of this rule as a string.
      def to_citrus # :nodoc:
        @regexp.inspect
      end
    end
  end
end
