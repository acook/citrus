module Citrus

  # A base class for all Citrus errors.
  class Error < StandardError; end

  # Raised when Citrus.require can't find the file to load.
  class LoadError < Error; end

  # Raised when a parse fails.
  class ParseError < Error
    # The +input+ given here is an instance of Citrus::Input.
    def initialize(input)
      @offset = input.max_offset
      @line_offset = input.line_offset(offset)
      @line_number = input.line_number(offset)
      @line = input.line(offset)

      message = "Failed to parse input on line #{line_number}"
      message << " at offset #{line_offset}\n#{detail}"

      super(message)
    end

    # The 0-based offset at which the error occurred in the input, i.e. the
    # maximum offset in the input that was successfully parsed before the error
    # occurred.
    attr_reader :offset

    # The 0-based offset at which the error occurred on the line on which it
    # occurred in the input.
    attr_reader :line_offset

    # The 1-based number of the line in the input where the error occurred.
    attr_reader :line_number

    # The text of the line in the input where the error occurred.
    attr_reader :line

    # Returns a string that, when printed, gives a visual representation of
    # exactly where the error occurred on its line in the input.
    def detail
      "#{line}\n#{' ' * line_offset}^"
    end
  end

  # Raised when Citrus::File.parse fails.
  class SyntaxError < Error
    # The +error+ given here is an instance of Citrus::ParseError.
    def initialize(error)
      message = "Malformed Citrus syntax on line #{error.line_number}"
      message << " at offset #{error.line_offset}\n#{error.detail}"

      super(message)
    end
  end
end
