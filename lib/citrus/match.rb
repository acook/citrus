module Citrus
  # The base class for all matches. Matches are organized into a tree where any
  # match may contain any number of other matches. Nodes of the tree are lazily
  # instantiated as needed. This class provides several convenient tree
  # traversal methods that help when examining and interpreting parse results.
  class Match
    def initialize(input, events=[], offset=0)
      @input = input
      @offset = offset

      if events.length > 0
        elisions = []

        while events[0].elide?
          elisions.unshift(events.shift)
          events.slice!(-2, events.length)
        end

        events[0].extend_match(self)

        elisions.each do |rule|
          rule.extend_match(self)
        end
      else
        # Create a default stream of events for the given string.
        string = input.to_str
        events = [Grammar::Rule.for(string), CLOSE, string.length]
      end

      @events = events
    end

    # The original Input this Match was generated on.
    attr_reader :input

    # The index of this match in the #input.
    attr_reader :offset

    # The array of events for this match.
    attr_reader :events

    # Returns the length of this match.
    def length
      events.last
    end

    # Convenient shortcut for +input.source+
    def source
      (input.respond_to?(:source) && input.source) || input
    end

    # Returns the slice of the source text that this match captures.
    def string
      @string ||= input.to_str[offset, length]
    end

    # Returns a hash of capture names to arrays of matches with that name,
    # in the order they appeared in the input.
    def captures
      process_events! unless @captures
      @captures
    end

    # Returns an array of all immediate submatches of this match.
    def matches
      process_events! unless @matches
      @matches
    end

    # A shortcut for retrieving the first immediate submatch of this match.
    def first
      matches.first
    end

    # Allows methods of this match's string to be called directly and provides
    # a convenient interface for retrieving the first match with a given name.
    def method_missing(sym, *args, &block)
      if string.respond_to?(sym)
        string.__send__(sym, *args, &block)
      else
        captures[sym].first
      end
    end

    alias_method :to_s, :string

    # This alias allows strings to be compared to the string value of Match
    # objects. It is most useful in assertions in unit tests, e.g.:
    #
    #     assert_equal("a string", match)
    #
    alias_method :to_str, :to_s

    # The default value for a match is its string value. This method is
    # overridden in most cases to be more meaningful according to the desired
    # interpretation.
    alias_method :value, :to_s

    # Returns this match plus all sub #matches in an array.
    def to_a
      [self] + matches
    end

    # Returns the capture at the given +key+. If it is an Integer (and an
    # optional length) or a Range, the result of #to_a with the same arguments
    # is returned. Otherwise, the value at +key+ in #captures is returned.
    def [](key, *args)
      case key
      when Integer, Range
        to_a[key, *args]
      else
        captures[key]
      end
    end

    def ==(other)
      case other
      when String
        string == other
      when Match
        string == other.to_s
      else
        super
      end
    end

    alias_method :eql?, :==

      def inspect
        string.inspect
      end

    # Prints the entire subtree of this match using the given +indent+ to
    # indicate nested match levels. Useful for debugging.
    def dump(indent=' ')
      lines = []
      stack = []
      offset = 0
      close = false
      index = 0
      last_length = nil

      while index < @events.size
        event = @events[index]

        if close
          os = stack.pop
          start = stack.pop
          rule = stack.pop

          space = indent * (stack.size / 3)
          string = self.string.slice(os, event)
          lines[start] = "#{space}#{string.inspect} rule=#{rule}, offset=#{os}, length=#{event}"

          last_length = event unless last_length

          close = false
        elsif event == CLOSE
          close = true
        else
          if last_length
            offset += last_length
            last_length = nil
          end

          stack << event
          stack << index
          stack << offset
        end

        index += 1
      end

      puts lines.compact.join("\n")
    end

    private

    # Initializes both the @captures and @matches instance variables.
    def process_events!
      @captures = captures_hash
      @matches = []

      capture!(@events[0], self)
      @captures[0] = self

      stack = []
      offset = 0
      close = false
      index = 0
      last_length = nil
      capture = true

      while index < @events.size
        event = @events[index]

        if close
          start = stack.pop

          if Grammar::Rule === start
            rule = start
            os = stack.pop
            start = stack.pop

            match = Match.new(input, @events[start..index], @offset + os)
            capture!(rule, match)

            if stack.size == 1
              @matches << match
              @captures[@matches.size] = match
            end

            capture = true
          end

          last_length = event unless last_length

          close = false
        elsif event == CLOSE
          close = true
        else
          stack << index

          # We can calculate the offset of this rule event by adding back the
          # last match length.
          if last_length
            offset += last_length
            last_length = nil
          end

          if capture && stack.size != 1
            stack << offset
            stack << event

            # We should not create captures when traversing a portion of the
            # event stream that is masked by a proxy in the original rule
            # definition.
            capture = false if Grammar::Proxy === event
          end
        end

        index += 1
      end
    end

    def capture!(rule, match)
      # We can lookup matches that were created by proxy by the name of
      # the rule they are proxy for.
      if Grammar::Proxy === rule
        if @captures.key?(rule.rule_name)
          @captures[rule.rule_name] << match
        else
          @captures[rule.rule_name] = [match]
        end
      end

      # We can lookup matches that were created by rules with labels by
      # that label.
      if rule.label
        if @captures.key?(rule.label)
          @captures[rule.label] << match
        else
          @captures[rule.label] = [match]
        end
      end
    end

    # Returns a new Hash that is to be used for @captures. This hash normalizes
    # String keys to Symbols, returns +nil+ for unknown Numeric keys, and an
    # empty Array for all other unknown keys.
    def captures_hash
      Hash.new do |hash, key|
        case key
        when String
          hash[key.to_sym]
        when Numeric
          nil
        else
          []
        end
      end
    end
  end
end

