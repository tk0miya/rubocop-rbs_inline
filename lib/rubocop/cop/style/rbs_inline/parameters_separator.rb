# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        # IRB::Inline expects annotations comments for parameters are separeted with `:`or allows annotation comments.
        # This cop checks for comments that do not match the expected pattern.
        #
        # @example
        #   # bad
        #   # @rbs param String
        #
        #   # bad
        #   # @rbs :param String
        #
        #   # good
        #   # @rbs param: String
        #
        #   # good
        #   # @rbs %a{pure}
        class ParametersSeparator < Base
          include RangeHelp

          MSG = 'Use `:` as a separator between parameter name and type.'

          # refs: https://github.com/soutaro/rbs-inline/blob/main/lib/rbs/inline/annotation_parser/tokenizer.rb
          RBS_INLINE_KEYWORDS = %w[inherits override use module-self generic skip module class].freeze #: Array[String]
          RBS_INLINE_REGEXP_KEYWORDS = [/%a{(\w|-)+}/, /%a\((\w|-)+\)/, /%a\[(\w|-)+\]/].freeze #: Array[Regexp]

          def on_new_investigation #: void
            processed_source.comments.each do |comment|
              matched = comment.text.match(/\A#\s+@rbs\s+(\S+)/)

              next unless matched
              next if valid_rbs_inline_comment?(matched[1])

              add_offense(invalid_location_for(comment))
            end
          end

          private

          # @rbs matched: String?
          def valid_rbs_inline_comment?(matched) #: bool
            return true if matched.nil?
            return true if RBS_INLINE_KEYWORDS.include?(matched)
            return true if RBS_INLINE_REGEXP_KEYWORDS.any? { |regexp| matched =~ regexp }
            return true if matched.end_with?(':')

            false
          end

          # @rbs comment: Parser::Source::Comment
          def invalid_location_for(comment) #: Parser::Source::Range
            range = comment.source_range
            matched = comment.text.match(/\A#\s+@rbs\s+/) or raise
            range_between(range.begin_pos + matched[0].to_s.length, range.end_pos)
          end
        end
      end
    end
  end
end
