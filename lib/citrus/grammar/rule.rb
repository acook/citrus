module Citrus
  module Grammar
    # A Rule is an object that is used by a grammar to create matches on an
    # Input during parsing.
    module Rule
      # Returns a new Rule object depending on the type of object given.
      def self.for(obj)
        case obj
        when Rule     then obj
        when Symbol   then Alias.new(obj)
        when String   then StringTerminal.new(obj)
        when Regexp   then Terminal.new(obj)
        when Array    then Sequence.new(obj)
        when Range    then Choice.new(obj.to_a)
        when Numeric  then StringTerminal.new(obj.to_s)
        else
          raise ArgumentError, "Invalid rule object: #{obj.inspect}"
        end
      end

      # The grammar this rule belongs to, if any.
      attr_accessor :grammar

      # Sets the name of this rule.
      def name=(name)
        @name = name.to_sym
      end

      # The name of this rule.
      attr_reader :name

      # Sets the label of this rule.
      def label=(label)
        @label = label.to_sym
      end

      # A label for this rule. If a rule has a label, all matches that it creates
      # will be accessible as named captures from the scope of their parent match
      # using that label.
      attr_reader :label

      # Specifies a module that will be used to extend all Match objects that
      # result from this rule. If +mod+ is a Proc, it is used to create an
      # anonymous module with a +value+ method.
      def extension=(mod)
        if Proc === mod
          mod = Module.new { define_method(:value, &mod) }
        end

        raise ArgumentError, "Extension must be a Module" unless Module === mod

        @extension = mod
      end

      # The module this rule uses to extend new matches.
      attr_reader :extension

      # The default set of options to use when calling #parse.
      def default_options # :nodoc:
        { :consume  => true,
          :memoize  => false,
          :offset   => 0
        }
      end

      # Attempts to parse the given +string+ and return a Match if any can be
      # made. +options+ may contain any of the following keys:
      #
      # consume::   If this is +true+ a ParseError will be raised unless the
      #             entire input string is consumed. Defaults to +true+.
      # memoize::   If this is +true+ the matches generated during a parse are
      #             memoized. See MemoizedInput for more information. Defaults to
      #             +false+.
      # offset::    The offset in +string+ at which to start parsing. Defaults
      #             to 0.
      def parse(source, options={})
        opts = default_options.merge(options)

        input = (opts[:memoize] ? MemoizedInput : Input).new(source)
        string = input.string
        input.pos = opts[:offset] if opts[:offset] > 0

        events = input.exec(self)
        length = events[-1]

        if !length || (opts[:consume] && length < (string.length - opts[:offset]))
          raise ParseError, input
        end

        Match.new(input, events, opts[:offset])
      end

      # Tests whether or not this rule matches on the given +string+. Returns the
      # length of the match if any can be made, +nil+ otherwise. Accepts the same
      # +options+ as #parse.
      def test(string, options={})
        parse(string, options).length
      rescue ParseError
        nil
      end

      # Tests the given +obj+ for case equality with this rule.
      def ===(obj)
        !test(obj).nil?
      end

      # Returns +true+ if this rule is a Terminal.
      def terminal?
        false
      end

      # Returns +true+ if this rule should extend a match but should not appear in
      # its event stream.
      def elide?
        false
      end

      # Returns +true+ if this rule needs to be surrounded by parentheses when
      # using #to_embedded_s.
      def needs_paren? # :nodoc:
        is_a?(Nonterminal) && rules.length > 1
      end

      # Returns the Citrus notation of this rule as a string.
      def to_s
        if label
          "#{label}:" + (needs_paren? ? "(#{to_citrus})" : to_citrus)
        else
          to_citrus
        end
      end

      # This alias allows strings to be compared to the string representation of
      # Rule objects. It is most useful in assertions in unit tests, e.g.:
      #
      #     assert_equal('"a" | "b"', rule)
      #
      alias_method :to_str, :to_s

      # Returns the Citrus notation of this rule as a string that is suitable to
      # be embedded in the string representation of another rule.
      def to_embedded_s # :nodoc:
        if name
          name.to_s
        else
          needs_paren? && label.nil? ? "(#{to_s})" : to_s
        end
      end

      def ==(other)
        case other
        when Rule
          to_s == other.to_s
        else
          super
        end
      end

      alias_method :eql?, :==

        def inspect # :nodoc:
          to_s
        end

      def extend_match(match) # :nodoc:
        match.extend(extension) if extension
      end

      # FIXME: Make the code understand the Grammar namespace
      def self.const_missing(name)
        Citrus::Grammar.const_get name
      end
    end
  end
end

