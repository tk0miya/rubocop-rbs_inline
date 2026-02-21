# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        # IRB::Inline expects annotations comments for keywords are not separeted with `:`.
        # This cop checks for comments that do not match the expected pattern.
        #
        # @example
        #   # bad
        #   # @rbs module-self: String
        #
        #   # good
        #   # @rbs module-self String
        #
        class KeywordSeparator < Base
          extend AutoCorrector
          include CommentParser
          include RangeHelp

          MSG = 'Do not use `:` after the keyword.'

          # refs: https://github.com/soutaro/rbs-inline/blob/main/lib/rbs/inline/annotation_parser/tokenizer.rb
          RBS_INLINE_KEYWORDS = %w[inherits override use module-self generic skip module class].freeze #: Array[String]
          # `override` and `skip` are standalone markers that take no arguments.
          # Even before a method definition they may not be followed by `:` alone,
          # because `# @rbs override:` (no type) is not a valid parameter annotation.
          # Only `# @rbs override: SomeType` (with a type) is valid as a parameter annotation.
          NO_ARGUMENT_KEYWORDS = %w[override skip].freeze #: Array[String]

          # @rbs @method_annotation_lines: Set[Integer]

          def on_new_investigation #: void
            super
            parse_comments
            @method_annotation_lines = Set.new #: Set[Integer]
          end

          # @rbs node: Parser::AST::Node
          def on_def(node) #: void
            collect_method_annotation_comments(node.loc.line)
          end

          # @rbs node: Parser::AST::Node
          def on_defs(node) #: void
            collect_method_annotation_comments(node.loc.line)
          end

          def on_investigation_end #: void
            processed_source.comments.each do |comment|
              matched = comment.text.match(/\A#\s+@rbs\s+(#{RBS_INLINE_KEYWORDS.join('|')}):/)
              next unless matched
              next if valid_method_annotation?(comment)

              range = invalid_location_for(comment, matched)
              add_offense(range) do |corrector|
                corrector.remove(range)
              end
            end
            super
          end

          private

          # Collect line numbers of leading annotation comments for a method definition
          # into @method_annotation_lines.
          # @rbs def_line: Integer
          def collect_method_annotation_comments(def_line) #: void
            result = find_leading_annotation(def_line) or return
            result.comments.each do |prism_comment|
              @method_annotation_lines.add(prism_comment.location.start_line)
            end
          end

          # Returns true when comment is a leading annotation for a method definition and
          # is not a no-argument keyword (`override` or `skip`) followed by `:` without a type.
          # @rbs comment: Parser::Source::Comment
          def valid_method_annotation?(comment) #: bool
            return false unless @method_annotation_lines.include?(comment.loc.line)

            !no_argument_keyword_without_type?(comment)
          end

          # Returns true when `comment` is a no-argument keyword (`override` or `skip`)
          # followed by `:` but no type.
          # @rbs comment: Parser::Source::Comment
          def no_argument_keyword_without_type?(comment) #: bool
            comment.text.match?(/\A#\s+@rbs\s+(#{NO_ARGUMENT_KEYWORDS.join('|')}):\s*\z/)
          end

          # @rbs comment: Parser::Source::Comment
          # @rbs matched: MatchData
          def invalid_location_for(comment, matched) #: Parser::Source::Range
            captured = matched[0] or raise
            begin_pos = comment.source_range.begin_pos + captured.length - 1
            range_between(begin_pos, begin_pos + 1)
          end
        end
      end
    end
  end
end
