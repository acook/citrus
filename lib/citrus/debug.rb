require_relative '../citrus'

module Citrus
  module Debug
    def self.capture
      readme, writeme = IO.pipe
      pid = fork do
        $stdout.reopen writeme
        readme.close

        yield
      end

      writeme.close
      output = readme.read
      Process.waitpid(pid)

      output
    end
  end

  module Grammar
    module GrammarMethods
      def debug_parse(string, options={})
        rule_name = options.delete(:root) || root
        raise Error, "No root rule specified" unless rule_name
        rule = rule(rule_name)
        raise Error, "No rule named \"#{rule_name}\"" unless rule

        rule.debug_rule_parse(string, options)
      end
      #alias_method :old_parse, :parse
      #alias_method :parse, :debug_parse
    end

    module Rule
      def debug_rule_parse string, options = {}
        opts = default_options.merge(options)

        input = (opts[:memoize] ? MemoizedInput : Input).new(string)
        input.pos = opts[:offset] if opts[:offset] > 0

        events = input.exec(self)
        length = events[-1]

        #if !length || (opts[:consume] && length < (string.length - opts[:offset]))
        #  raise ParseError, input
        #end

        match = Match.new(string.slice(opts[:offset], length), events)

        [match, input, events]
      end
      #alias_method :old_parse, :parse
      #alias_method :parse, :debug_rule_parse
    end
  end

  class Match
    def color_debug_dump
      output = debug_dump

      CodeRay.scan(output, :ruby).encode CodeRay::Encoders::Terminal.new
    end

    def debug_dump(indent=' ')
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
          lines[start] = "#{space}#{string.inspect} rule: #{rule}, offset: #{os}, length: #{event}"

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

      lines.compact.join("\n")
    end
  end
end
