# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Utility module for accessing processed source code information
        # @rbs module-self RuboCop::Cop::Base
        module SourceCodeHelper
          include RangeHelp

          # Convert byte offset to character offset
          # @rbs byte_offset: Integer
          def character_offset(byte_offset) #: Integer
            source = processed_source.buffer.source.dup.force_encoding('ASCII')
            text = source[...byte_offset] or raise
            text.force_encoding(processed_source.buffer.source.encoding).size
          rescue StandardError
            byte_offset
          end

          # @rbs line: Integer
          def comment_at(line) #: Parser::Source::Comment?
            processed_source.comments.find { _1.location.line == line }
          end

          # @rbs line_number: Integer
          def source_code_at(line_number) #: String
            processed_source.buffer.source.lines[line_number - 1] || ''
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

          # Convert Prism::Location to Parser::Source::Range
          # @rbs location: Prism::Location
          def location_to_range(location) #: Parser::Source::Range
            range_between(character_offset(location.start_offset), character_offset(location.end_offset))
          end

          # Convert Prism::Comment to Parser::Source::Range
          # @rbs comment: Prism::Comment
          def comment_range(comment) #: Parser::Source::Range
            location_to_range(comment.location)
          end

          # Convert RBS::Inline annotation to Parser::Source::Range
          # @rbs annotation: RBS::Inline::AST::Annotations::t
          def annotation_range(annotation) #: Parser::Source::Range?
            comments = annotation.source.comments
            first = comments.first&.location
            last = comments.last&.location
            return unless first && last

            range_between(character_offset(first.start_offset), character_offset(last.end_offset))
          end
        end
      end
    end
  end
end
