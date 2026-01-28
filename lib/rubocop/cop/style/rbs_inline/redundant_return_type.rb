# frozen_string_literal: true

require 'rbs/inline'

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Checks for redundant return type annotations when both `@rbs return` and
        # inline signature `#:` are used for the same method.
        #
        # Using both annotations for return type is redundant and can cause confusion
        # about which one takes precedence.
        #
        # @example PreferredStyle: inline_signature (default)
        #   # bad
        #   # @rbs return: String
        #   def method(arg) #: (Integer) -> String
        #   end
        #
        #   # good - use only inline signature
        #   def method(arg) #: (Integer) -> String
        #   end
        #
        # @example PreferredStyle: return_annotation
        #   # bad
        #   # @rbs return: String
        #   def method(arg) #: (Integer) -> String
        #   end
        #
        #   # good - use only @rbs return annotation
        #   # @rbs arg: Integer
        #   # @rbs return: String
        #   def method(arg)
        #   end
        #
        class RedundantReturnType < Base
          extend AutoCorrector
          include RangeHelp

          MSG_REDUNDANT_RETURN = 'Redundant `@rbs return` annotation. ' \
                                 'The return type is already specified in the inline signature `#:`.'
          MSG_REDUNDANT_SIGNATURE = 'Redundant inline signature `#:`. ' \
                                    'The return type is already specified in `@rbs return` annotation.'

          SIGNATURE_PATTERN = /\A#:\s*\(.*\)\s*(\??\s*\{.*?\}\s*)?->\s*.+/

          def on_new_investigation #: void
            @parsed_comments = parse_comments
          end

          # @rbs node: Parser::AST::Node
          def on_def(node) #: void
            process(node)
          end

          # @rbs node: Parser::AST::Node
          def on_defs(node) #: void
            process(node)
          end

          private

          attr_reader :parsed_comments #: Array[RBS::Inline::AnnotationParser::ParsingResult]

          # @rbs node: Parser::AST::Node
          def process(node) #: void
            return_annotation = find_return_annotation(node)
            signature_comment = find_signature_comment(node)

            return unless return_annotation && signature_comment

            if prefer_inline_signature?
              add_offense_for_return_annotation(return_annotation, signature_comment)
            else
              add_offense_for_signature(signature_comment, return_annotation)
            end
          end

          # @rbs node: Parser::AST::Node
          def find_return_annotation(node) #: RBS::Inline::AST::Annotations::ReturnType?
            method_line = node.location.line
            comment = parsed_comments.find do |r|
              r.comments.any? { |c| c.location.start_line == method_line - 1 }
            end
            return unless comment

            comment.each_annotation.find do |annotation|
              annotation.is_a?(RBS::Inline::AST::Annotations::ReturnType)
            end
          end

          # @rbs node: Parser::AST::Node
          def find_signature_comment(node) #: Parser::Source::Comment?
            method_line = node.location.line

            # Check inline comment on the same line as method definition
            inline_comment = processed_source.comments.find do |comment|
              comment.location.line == method_line && comment.text.match?(SIGNATURE_PATTERN)
            end
            return inline_comment if inline_comment

            # Check comment on the line before method definition
            processed_source.comments.find do |comment|
              comment.location.line == method_line - 1 && comment.text.match?(SIGNATURE_PATTERN)
            end
          end

          # @rbs annotation: RBS::Inline::AST::Annotations::ReturnType
          # @rbs _signature_comment: Parser::Source::Comment
          def add_offense_for_return_annotation(annotation, _signature_comment) #: void
            loc = annotation.source.comments.first&.location or return
            source = processed_source.buffer.source.dup.force_encoding('ASCII')
            text = source[loc.start_offset...loc.end_offset] or return
            comment_text = text.force_encoding(processed_source.buffer.source.encoding)

            # Find the position of 'return' in the comment
            return_index = comment_text.index('return')
            return unless return_index

            start_offset = loc.start_offset + return_index
            range = range_between(character_offset(start_offset), character_offset(start_offset + 6))

            add_offense(range, message: MSG_REDUNDANT_RETURN) do |corrector|
              comment_range = find_comment_range(annotation)
              corrector.remove(comment_range) if comment_range
            end
          end

          # @rbs signature_comment: Parser::Source::Comment
          # @rbs _return_annotation: RBS::Inline::AST::Annotations::ReturnType
          def add_offense_for_signature(signature_comment, _return_annotation) #: void
            add_offense(signature_comment.location.expression, message: MSG_REDUNDANT_SIGNATURE) do |corrector|
              remove_range = signature_range_with_surrounding(signature_comment)
              corrector.remove(remove_range)
            end
          end

          # @rbs annotation: RBS::Inline::AST::Annotations::ReturnType
          def find_comment_range(annotation) #: Parser::Source::Range?
            loc = annotation.source.comments.first&.location or return

            # Find the RuboCop comment object that corresponds to this annotation
            target_line = loc.start_line
            comment = processed_source.comments.find { |c| c.location.line == target_line }
            return unless comment

            # Include the newline after the comment if it exists
            comment_end = comment.location.expression.end_pos
            source_length = processed_source.buffer.source.length

            if comment_end < source_length && processed_source.buffer.source[comment_end] == "\n"
              range_between(comment.location.expression.begin_pos, comment_end + 1)
            else
              comment.location.expression
            end
          end

          # @rbs comment: Parser::Source::Comment
          def signature_range_with_surrounding(comment) #: Parser::Source::Range
            # For inline comments, just remove the comment part
            # For standalone comments, remove the whole line including newline
            comment_start = comment.location.expression.begin_pos
            comment_end = comment.location.expression.end_pos
            source = processed_source.buffer.source

            # Check if this is an inline comment (has code before it on the same line)
            line_start = source.rindex("\n", comment_start - 1)
            line_start = line_start ? line_start + 1 : 0
            text_before = source[line_start...comment_start]

            if text_before.strip.empty?
              # Standalone comment - remove the whole line
              if comment_end < source.length && source[comment_end] == "\n"
                range_between(line_start, comment_end + 1)
              else
                range_between(line_start, comment_end)
              end
            else
              # Inline comment - remove just the comment (with leading space)
              space_start = comment_start
              space_start -= 1 while space_start > line_start && source[space_start - 1] == ' '
              range_between(space_start, comment_end)
            end
          end

          def prefer_inline_signature? #: bool
            cop_config['PreferredStyle'] != 'return_annotation'
          end

          def parse_comments #: Array[RBS::Inline::AnnotationParser::ParsingResult]
            parsed_result = Prism.parse(processed_source.buffer.source)
            RBS::Inline::AnnotationParser.parse(parsed_result.comments)
          end

          # @rbs byte_offset: Integer
          def character_offset(byte_offset) #: Integer
            source = processed_source.buffer.source.dup.force_encoding('ASCII')
            text = source[...byte_offset] or raise
            text.force_encoding(processed_source.buffer.source.encoding).size
          rescue StandardError
            byte_offset
          end
        end
      end
    end
  end
end
