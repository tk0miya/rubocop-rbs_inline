# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        # RBS::Inline expects annotation comments for keywords to not use a `:` separator,
        # and for parameters to use a `:` separator.
        #
        # @example
        #   # bad (keyword followed by colon)
        #   # @rbs module-self: String
        #
        #   # bad (parameter without colon)
        #   # @rbs param String
        #
        #   # bad (parameter with leading colon instead of trailing)
        #   # @rbs :param String
        #
        #   # good
        #   # @rbs module-self String
        #
        #   # good
        #   # @rbs param: String
        #
        #   # good
        #   # @rbs %a{pure}
        class AnnotationSeparator < Base
          extend AutoCorrector
          include CommentParser
          include RangeHelp

          KEYWORD_MSG = 'Do not use `:` after the keyword.' #: String
          PARAMETER_MSG = 'Use `:` as a separator between parameter name and type.' #: String

          # refs: https://github.com/soutaro/rbs-inline/blob/main/lib/rbs/inline/annotation_parser/tokenizer.rb
          RBS_INLINE_KEYWORDS = %w[inherits override use module-self generic skip module class].freeze #: Array[String]
          # `override` and `skip` are standalone markers that take no arguments.
          # Even before a method definition they may not be followed by `:` alone,
          # because `# @rbs override:` (no type) is not a valid parameter annotation.
          # Only `# @rbs override: SomeType` (with a type) is valid as a parameter annotation.
          NO_ARGUMENT_KEYWORDS = %w[override skip].freeze #: Array[String]
          RBS_INLINE_REGEXP_KEYWORDS = [/%a\{(\w|-)+\}/, /%a\((\w|-)+\)/, /%a\[(\w|-)+\]/].freeze #: Array[Regexp]

          # @rbs @method_annotation_lines: Set[Integer]

          def on_new_investigation #: void
            super
            parse_comments
            @method_annotation_lines = Set.new #: Set[Integer]
            check_parameters_separator
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
            check_keyword_separator
            super
          end

          private

          def check_parameters_separator #: void
            processed_source.comments.each do |comment|
              matched = comment.text.match(/\A(?<prefix>#\s+@rbs\s+)(?<keyword>\S+)/)

              next unless matched
              next if valid_parameter_comment?(matched[:keyword])

              add_offense(parameter_offense_location(comment, matched), message: PARAMETER_MSG) do |corrector|
                corrector.replace(parameter_keyword_range(comment, matched), corrected_keyword(matched[:keyword]))
              end
            end
          end

          def check_keyword_separator #: void
            processed_source.comments.each do |comment|
              matched = comment.text.match(/\A#\s+@rbs\s+(#{RBS_INLINE_KEYWORDS.join('|')}):/)
              next unless matched
              next if valid_method_annotation?(comment)

              range = keyword_colon_location(comment, matched)
              add_offense(range, message: KEYWORD_MSG) do |corrector|
                corrector.remove(range)
              end
            end
          end

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

          # @rbs matched: String?
          def valid_parameter_comment?(matched) #: bool
            return true if matched.nil?
            return true if RBS_INLINE_KEYWORDS.include?(matched)
            return true if RBS_INLINE_REGEXP_KEYWORDS.any? { |regexp| matched =~ regexp }
            return true if matched.end_with?(':')

            false
          end

          # @rbs comment: Parser::Source::Comment
          # @rbs matched: MatchData
          def parameter_offense_location(comment, matched) #: Parser::Source::Range
            range = comment.source_range
            range_between(range.begin_pos + matched[:prefix].length, range.end_pos)
          end

          # @rbs comment: Parser::Source::Comment
          # @rbs matched: MatchData
          def parameter_keyword_range(comment, matched) #: Parser::Source::Range
            range = comment.source_range
            keyword_begin = range.begin_pos + matched[:prefix].length
            range_between(keyword_begin, keyword_begin + matched[:keyword].length)
          end

          # @rbs keyword: String
          def corrected_keyword(keyword) #: String
            "#{keyword.delete_prefix(':')}:"
          end

          # @rbs comment: Parser::Source::Comment
          # @rbs matched: MatchData
          def keyword_colon_location(comment, matched) #: Parser::Source::Range
            captured = matched[0] or raise
            begin_pos = comment.source_range.begin_pos + captured.length - 1
            range_between(begin_pos, begin_pos + 1)
          end
        end
      end
    end
  end
end
