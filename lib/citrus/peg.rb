require 'citrus'

module Citrus
  module PEG
    include Grammar


    ## Hierarchical syntax


    rule :file do
      zero_or_more(any(:space, :require, :include, :grammar)) {
        def requires
          find(:require)
        end

        def includes
          find(:include)
        end

        def grammars
          find(:grammar)
        end
      }
    end

    rule :grammar do
      all(:grammar_keyword, :module_name, :grammar_body, :end_keyword) {
        def name
          module_name.value
        end

        def includes
          find(:include)
        end

        def root
          find(:root).last
        end

        def rules
          find(:rule)
        end
      }
    end

    rule :grammar_body do
      zero_or_more(any(:include, :root, :rule))
    end

    rule :rule do
      all(:rule_keyword, :rule_name, :rule_body, :end_keyword) {
        def name
          rule_name.value
        end

        def value
          choice.value
        end
      }
    end

    rule :rule_body do
      all(:sequence, :choice) {
        def choices
          @choices ||= [ sequence ] + choice.sequences
        end

        def values
          choices.map {|s| s.value }
        end

        def value
          choices.length > 1 ? Choice.new(values) : values[0]
        end
      }
    end

    rule :choice do
      zero_or_more([ :bar, :sequence ]) {
        def sequences
          matches.map {|m| m.matches[1] }
        end
      }
    end

    rule :sequence do
      zero_or_more(:prefix) {
        def values
          matches.map {|m| m.value }
        end

        def value
          matches.length > 1 ? Sequence.new(values) : values[0]
        end
      }
    end

    rule :prefix do
      all(zero_or_one(:qualifier), :appendix) {
        def value
          rule = appendix.value
          qualifier = matches[0].first
          rule = qualifier.wrap(rule) if qualifier
          rule
        end
      }
    end

    rule :appendix do
      all(:suffix, zero_or_one(:modifier)) {
        def value
          rule = suffix.value
          modifier = matches[1].first
          rule = modifier.wrap(rule) if modifier
          rule
        end
      }
    end

    rule :suffix do
      all(:primary, zero_or_one(:quantifier)) {
        def value
          rule = primary.value
          quantifier = matches[1].first
          rule = quantifier.wrap(rule) if quantifier
          rule
        end
      }
    end

    rule :primary do
      any(:proxy, :rule_body_paren, :terminal) {
        def value
          first.value
        end
      }
    end

    rule :rule_body_paren do
      all(:lparen, :rule_body, :rparen) {
        def value
          rule_body.value
        end
      }
    end


    ## Lexical syntax


    rule :require do
      all(:require_keyword, :quoted_string) {
        def value
          quoted_string.value
        end
      }
    end

    rule :include do
      all(:include_keyword, :module_list) {
        def values
          module_list.values
        end
      }
    end

    rule :module_list do
      all(:module_name, zero_or_more([ :comma, :module_name ])) {
        def module_names
          find(:module_name)
        end

        def values
          module_names.map {|m| m.value }
        end
      }
    end

    rule :root do
      all(:root_keyword, :rule_name) {
        def value
          rule_name.value
        end
      }
    end

    rule :rule_name do
      all(/[a-z][a-zA-Z0-9_]*/, :space) {
        def value
          first.text
        end
      }
    end

    rule :proxy do
      all(notp(:end_keyword), :rule_name) {
        def value
          Rule.create(rule_name.value.to_sym)
        end
      }
    end

    rule :terminal do
      any(:quoted_string, :character_class, :anything_symbol, :regular_expression) {
        def value
          Rule.create(first.value)
        end
      }
    end

    rule :quoted_string do
      all(/(["'])(?:\\?.)*?\1/, :space) {
        def value
          eval(first.text)
        end
      }
    end

    rule :character_class do
      all(/\[(?:\\?.)*?\]/, :space) {
        def value
          Regexp.new(first.text)
        end
      }
    end

    rule :anything_symbol do
      all('.', :space) {
        def value
          /./m # The dot matches newlines.
        end
      }
    end

    rule :regular_expression do
      all(/\/(?:\\?.)*?\/[imxouesn]*/, :space) {
        def value
          eval(first.text)
        end
      }
    end

    rule :qualifier do
      any(:and, :not, :label) {
        def wrap(rule)
          first.wrap(rule)
        end
      }
    end

    rule :and do
      all('&', :space) {
        def wrap(rule)
          AndPredicate.new(rule)
        end
      }
    end

    rule :not do
      all('!', :space) {
        def wrap(rule)
          NotPredicate.new(rule)
        end
      }
    end

    rule :label do
      all(/[a-zA-Z0-9_]+/, :space, ':', :space) {
        def value
          first.text
        end

        def wrap(rule)
          Label.new(value, rule)
        end
      }
    end

    rule :modifier do
      any(:tag, :block) {
        def wrap(rule)
          rule.match_module = first.value
          rule
        end
      }
    end

    rule :tag do
      all(:lt, :module_name, :gt) {
        def value
          eval(module_name.value, TOPLEVEL_BINDING)
        end
      }
    end

    rule :block do
      all(:lcurly, zero_or_more(any(:block, /[^{}]/)), :rcurly) {
        def value
          eval('Proc.new ' + text)
        end
      }
    end

    rule :quantifier do
      any(:question, :plus, :repeat) {
        def min; first.min end
        def max; first.max end

        def wrap(rule)
          Repeat.new(min, max, rule)
        end
      }
    end

    rule :question do
      all('?', :space) {
        def min; 0 end
        def max; 1 end
      }
    end

    rule :plus do
      all('+', :space) {
        def min; 1 end
        def max; Infinity end
      }
    end

    rule :repeat do
      all(/[0-9]*/, '*', /[0-9]*/, :space) {
        def min
          matches[0] == '' ? 0 : matches[0].text.to_i
        end

        def max
          matches[2] == '' ? Infinity : matches[2].text.to_i
        end
      }
    end

    rule :module_name do
      all(one_or_more([ zero_or_one('::'), :constant ]), :space) {
        def value
          first.text
        end
      }
    end

    rule :constant do
      /[A-Z][a-zA-Z0-9_]*/
    end

    rule(:require_keyword)  { [ 'require', :space ] }
    rule(:include_keyword)  { [ 'include', :space ] }
    rule(:grammar_keyword)  { [ 'grammar', :space ] }
    rule(:root_keyword)     { [ 'root', :space ] }
    rule(:rule_keyword)     { [ 'rule', :space ] }
    rule(:end_keyword)      { [ 'end', :space ] }
    rule(:lparen)           { [ '(', :space ] }
    rule(:rparen)           { [ ')', :space ] }
    rule(:lcurly)           { [ '{', :space ] }
    rule(:rcurly)           { [ '}', :space ] }
    rule(:comma)            { [ ',', :space ] }
    rule(:bar)              { [ '|', :space ] }
    rule(:lt)               { [ '<', :space ] }
    rule(:gt)               { [ '>', :space ] }

    rule :white do
      /[ \t\n\r]/
    end

    rule :comment do
      /#.*/
    end

    rule :space do
      zero_or_more(any(:white, :comment))
    end
  end
end