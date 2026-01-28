# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Checks for YARD type comments (@param, @return) that are redundant
        # when RBS inline type annotations are also present.
        #
        # When migrating from YARD to RBS inline, having both type documentation
        # systems creates duplication. This cop detects such cases and can
        # auto-correct by removing the YARD type comments.
        #
        # @example
        #   # bad - YARD and RBS type comments coexist
        #   # @param name [String] the name
        #   # @rbs name: String
        #   def greet(name); end
        #
        #   # bad - YARD @return with RBS return type
        #   # @return [Integer]
        #   # @rbs return: Integer
        #   def count; end
        #
        #   # good - only RBS type comments
        #   # @rbs name: String
        #   def greet(name); end
        #
        #   # good - only YARD comments (no RBS)
        #   # @param name [String] the name
        #   def greet(name); end
        #
        class RedundantYardTypeComment < Base
          extend AutoCorrector
          include RangeHelp

          MSG = 'Redundant YARD type comment. Use RBS inline annotation instead.'

          # YARD type comment patterns
          YARD_PARAM_PATTERN = /\A#\s*@param\s+\S+\s+\[.+\]/ #: Regexp
          YARD_RETURN_PATTERN = /\A#\s*@return\s+\[.+\]/ #: Regexp
          YARD_YIELD_PATTERN = /\A#\s*@yield\s+\[.+\]/ #: Regexp
          YARD_YIELDPARAM_PATTERN = /\A#\s*@yieldparam\s+\S+\s+\[.+\]/ #: Regexp
          YARD_YIELDRETURN_PATTERN = /\A#\s*@yieldreturn\s+\[.+\]/ #: Regexp

          # @rbs node: Parser::AST::Node
          def on_def(node) #: void
            process(node)
          end

          # @rbs node: Parser::AST::Node
          def on_defs(node) #: void
            process(node)
          end

          private

          # @rbs node: Parser::AST::Node
          def process(node) #: void
            method_line = node.location.line
            preceding_comments = find_preceding_comments(method_line)
            return if preceding_comments.empty?

            yard_type_comments = preceding_comments.select { |c| yard_type_comment?(c) }
            return if yard_type_comments.empty?

            return unless has_rbs_annotation?(preceding_comments, method_line)

            yard_type_comments.each do |comment|
              add_offense(comment) do |corrector|
                remove_comment_line(corrector, comment)
              end
            end
          end

          # @rbs comment: Parser::Source::Comment
          def yard_type_comment?(comment) #: bool
            text = comment.text
            text.match?(YARD_PARAM_PATTERN) ||
              text.match?(YARD_RETURN_PATTERN) ||
              text.match?(YARD_YIELD_PATTERN) ||
              text.match?(YARD_YIELDPARAM_PATTERN) ||
              text.match?(YARD_YIELDRETURN_PATTERN)
          end

          # @rbs method_line: Integer
          def find_preceding_comments(method_line) #: Array[Parser::Source::Comment]
            comments = processed_source.comments.select do |comment|
              comment.loc.line < method_line
            end

            # Find consecutive comments immediately before the method
            result = [] #: Array[Parser::Source::Comment]
            comments.reverse_each do |comment|
              expected_line = result.empty? ? method_line - 1 : result.last.loc.line - 1
              break unless comment.loc.line == expected_line

              result << comment
            end

            result.reverse
          end

          # @rbs preceding_comments: Array[Parser::Source::Comment]
          # @rbs method_line: Integer
          def has_rbs_annotation?(preceding_comments, method_line) #: bool
            # Check for #: style signature on the line immediately before the method
            signature_comment = preceding_comments.find do |c|
              c.loc.line == method_line - 1 && c.text.match?(/\A#:/)
            end
            return true if signature_comment

            # Check for @rbs style annotations in preceding comments
            preceding_comments.any? do |comment|
              comment.text.match?(/\A#\s+@rbs\s+/)
            end
          end

          # @rbs corrector: RuboCop::Cop::Corrector
          # @rbs comment: Parser::Source::Comment
          def remove_comment_line(corrector, comment) #: void
            range = comment_with_surrounding_whitespace(comment)
            corrector.remove(range)
          end

          # @rbs comment: Parser::Source::Comment
          def comment_with_surrounding_whitespace(comment) #: Parser::Source::Range
            source = processed_source.buffer.source
            begin_pos = comment.source_range.begin_pos
            end_pos = comment.source_range.end_pos

            # Include leading whitespace on the same line
            while begin_pos.positive? && source[begin_pos - 1] =~ /[ \t]/
              begin_pos -= 1
            end

            # Include trailing newline if present
            end_pos += 1 if source[end_pos] == "\n"

            range_between(begin_pos, end_pos)
          end
        end
      end
    end
  end
end
