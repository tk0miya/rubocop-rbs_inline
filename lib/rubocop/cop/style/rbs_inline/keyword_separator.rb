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
          include RangeHelp

          MSG = 'Do not use `:` after the keyword.'

          # refs: https://github.com/soutaro/rbs-inline/blob/main/lib/rbs/inline/annotation_parser/tokenizer.rb
          RBS_INLINE_KEYWORDS = %w[inherits override use module-self generic skip module class].freeze #: Array[String]

          def on_new_investigation #: void
            processed_source.comments.each do |comment|
              if (matched = comment.text.match(/\A#\s+@rbs\s+(#{RBS_INLINE_KEYWORDS.join('|')}):/))
                add_offense(invalid_location_for(comment, matched))
              end
            end
          end

          private

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
