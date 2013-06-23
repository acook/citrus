# encoding: UTF-8

require 'strscan'
require 'pathname'
require 'citrus/version'

# Citrus is a compact and powerful parsing library for Ruby that combines the
# elegance and expressiveness of the language with the simplicity and power of
# parsing expressions.
#
# http://mjijackson.com/citrus
module Citrus
  autoload :File, 'citrus/file'

  # A pattern to match any character, including newline.
  DOT = /./mu

  Infinity = Float::INFINITY

  CLOSE = -1

  # Returns a map of paths of files that have been loaded via #load to the
  # result of #eval on the code in that file.
  #
  # Note: These paths are not absolute unless you pass an absolute path to
  # #load. That means that if you change the working directory and try to
  # #require the same file with a different relative path, it will be loaded
  # twice.
  def self.cache
    @cache ||= {}
  end

  # Evaluates the given Citrus parsing expression grammar +code+ and returns an
  # array of any grammar modules that are created. Accepts the same +options+ as
  # GrammarMethods#parse.
  #
  #     Citrus.eval(<<CITRUS)
  #     grammar MyGrammar
  #       rule abc
  #         "abc"
  #       end
  #     end
  #     CITRUS
  #     # => [MyGrammar]
  #
  def self.eval(code, options={})
    File.parse(code, options).value
  end

  # Evaluates the given expression and creates a new Rule object from it.
  # Accepts the same +options+ as #eval.
  #
  #     Citrus.rule('"a" | "b"')
  #     # => #<Citrus::Rule: ... >
  #
  def self.rule(expr, options={})
    eval(expr, options.merge(:root => :expression))
  end

  # Loads the grammar(s) from the given +file+. Accepts the same +options+ as
  # #eval, plus the following:
  #
  # force::   Normally this method will not reload a file that is already in
  #           the #cache. However, if this option is +true+ the file will be
  #           loaded, regardless of whether or not it is in the cache. Defaults
  #           to +false+.
  #
  #     Citrus.load('mygrammar')
  #     # => [MyGrammar]
  #
  def self.load(file, options={})
    file += '.citrus' unless /\.citrus$/ === file
    force = options.delete(:force)

    if force || !cache[file]
      begin
        cache[file] = eval(::File.read(file), options)
      rescue SyntaxError => e
        e.message.replace("#{::File.expand_path(file)}: #{e.message}")
        raise e
      end
    end

    cache[file]
  end

  # Searches the <tt>$LOAD_PATH</tt> for a +file+ with the .citrus suffix and
  # attempts to load it via #load. Returns the path to the file that was loaded
  # on success, +nil+ on failure. Accepts the same +options+ as #load.
  #
  #     path = Citrus.require('mygrammar')
  #     # => "/path/to/mygrammar.citrus"
  #     Citrus.cache[path]
  #     # => [MyGrammar]
  #
  def self.require(file, options={})
    file += '.citrus' unless /\.citrus$/ === file
    found = nil

    paths = ['']
    paths += $LOAD_PATH unless Pathname.new(file).absolute?
    paths.each do |path|
      found = Dir[::File.join(path, file)].first
      break if found
    end

    if found
      Citrus.load(found, options)
    else
      raise LoadError, "Cannot find file #{file}"
    end

    found
  end

  def self.const_missing name
    Grammar.const_get name
  end
end

require 'citrus/exceptions'
require 'citrus/match'
require 'citrus/input'
require 'citrus/memoized_input'

require 'citrus/grammar'


