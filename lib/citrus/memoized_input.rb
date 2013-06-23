module Citrus

  # A MemoizedInput is an Input that caches segments of the event stream for
  # particular rules in a parse. This technique (also known as "Packrat"
  # parsing) guarantees parsers will operate in linear time but costs
  # significantly more in terms of time and memory required to perform a parse.
  # For more information, please read the paper on Packrat parsing at
  # http://pdos.csail.mit.edu/~baford/packrat/icfp02/.
  class MemoizedInput < Input
    def initialize(string)
      super(string)
      @cache = {}
      @cache_hits = 0
    end

    # A nested hash of rules to offsets and their respective matches.
    attr_reader :cache

    # The number of times the cache was hit.
    attr_reader :cache_hits

    def reset # :nodoc:
      @cache.clear
      @cache_hits = 0
      super
    end

    # Returns +true+ when using memoization to cache match results.
    def memoized?
      true
    end

  private

    def apply_rule(rule, position, events) # :nodoc:
      memo = @cache[rule] ||= {}

      if memo[position]
        @cache_hits += 1
        c = memo[position]
        unless c.empty?
          events.concat(c)
          self.pos += events[-1]
        end
      else
        index = events.size
        rule.exec(self, events)

        # Memoize the result so we can use it next time this same rule is
        # executed at this position.
        memo[position] = events.slice(index, events.size)
      end

      events
    end
  end

end
