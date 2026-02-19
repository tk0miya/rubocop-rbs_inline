# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Utility module for accessing processed source code information
        # @rbs module-self RuboCop::Cop::Base
        module SourceCodeHelper
          # Convert byte offset to character offset
          # @rbs byte_offset: Integer
          def character_offset(byte_offset) #: Integer
            source = processed_source.buffer.source.dup.force_encoding('ASCII')
            text = source[...byte_offset] or raise
            text.force_encoding(processed_source.buffer.source.encoding).size
          rescue StandardError
            byte_offset
          end

          # @rbs line_number: Integer
          def blank_line?(line_number) #: bool
            line = processed_source.buffer.source.lines[line_number - 1]
            line.nil? || line.strip.empty?
          end

          # @rbs line_number: Integer
          def line_range(line_number) #: Parser::Source::Range
            processed_source.buffer.line_range(line_number)
          end

          # Convert Prism::Comment to Parser::Source::Range
          # @rbs comment: Prism::Comment
          def comment_range(comment) #: Parser::Source::Range
            start_offset = character_offset(comment.location.start_offset)
            end_offset = character_offset(comment.location.end_offset)

            Parser::Source::Range.new(
              processed_source.buffer,
              start_offset,
              end_offset
            )
          end
        end
      end
    end
  end
end
