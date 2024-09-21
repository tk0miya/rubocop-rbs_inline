# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        # IRB::Inline expects annotations comments for parameters are separeted with `:`.
        # This cop checks for comments that do not match the expected pattern.
        #
        # @example
        #   # bad
        #   # @rbs param String
        #
        #   # good
        #   # @rbs param: String
        #
        class ParametersSeparator < Base
          include RangeHelp

          MSG = 'Use `:` as a separator between parameter name and type.'

          # refs: https://github.com/soutaro/rbs-inline/blob/main/lib/rbs/inline/annotation_parser/tokenizer.rb
          RBS_INLINE_KEYWORDS = %w[inherits override use module-self generic skip module class]

          def on_new_investigation

            processed_source.comments.each do |comment|
              if matched = comment.text.match(/\A#\s+@rbs\s+(\S+)/)
                next if RBS_INLINE_KEYWORDS.include?(matched[1])

                add_offense(invalid_location_for(comment)) unless matched[1].include?(':')
              end
            end
          end

          private

          def invalid_location_for(comment)
            range = comment.source_range
            matched = comment.text.match(/\A#\s+@rbs\s+/)
            range_between(range.begin_pos + matched[0].length, range.end_pos)
          end
        end
      end
    end
  end
end