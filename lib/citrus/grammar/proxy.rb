module Citrus
  module Grammar
    # A Proxy is a Rule that is a placeholder for another rule. It stores the
    # name of some other rule in the grammar internally and resolves it to the
    # actual Rule object at runtime. This lazy evaluation permits creation of
    # Proxy objects for rules that may not yet be defined.
    module Proxy
      include Rule

      def initialize(rule_name='<proxy>')
        self.rule_name = rule_name
      end

      # Sets the name of the rule this rule is proxy for.
      def rule_name=(rule_name)
        @rule_name = rule_name.to_sym
      end

      # The name of this proxy's rule.
      attr_reader :rule_name

      # Returns the underlying Rule for this proxy.
      def rule
        @rule ||= resolve!
      end

      # Returns an array of events for this rule on the given +input+.
      def exec(input, events=[])
        index = events.size

        if input.exec(rule, events).size > index
          # Proxy objects insert themselves into the event stream in place of the
          # rule they are proxy for.
          events[index] = self
        end

        events
      end

      # Returns +true+ if this rule should extend a match but should not appear in
      # its event stream.
      def elide? # :nodoc:
        rule.elide?
      end

      def extend_match(match) # :nodoc:
        # Proxy objects preserve the extension of the rule they are proxy for, and
        # may also use their own extension.
        rule.extend_match(match)
        super
      end
    end
  end
end

