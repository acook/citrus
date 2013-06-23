module Citrus
  module Grammar
    # An Alias is a Proxy for a rule in the same grammar. It is used in rule
    # definitions when a rule calls some other rule by name. The Citrus notation
    # is simply the name of another rule without any other punctuation, e.g.:
    #
    #     name
    #
    class Alias
      include Proxy

      # Returns the Citrus notation of this rule as a string.
      def to_citrus # :nodoc:
        rule_name.to_s
      end

      private

      # Searches this proxy's grammar and any included grammars for a rule with
      # this proxy's #rule_name. Raises an error if one cannot be found.
      def resolve!
        rule = grammar.rule(rule_name)

        unless rule
          raise Error, "No rule named \"#{rule_name}\" in grammar #{grammar}"
        end

        rule
      end
    end
  end
end
