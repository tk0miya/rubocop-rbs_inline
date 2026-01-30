# frozen_string_literal: true

require 'rbs/inline'

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Checks for redundant return type annotations when both `# @rbs return`
        # and inline `#:` comments are used on the same method definition.
        #
        # @example EnforcedStyle: inline_comment (default)
        #   # bad
        #   # @rbs return: String
        #   def method(arg) #: String
        #   end
        #
        #   # good
        #   def method(arg) #: String
        #   end
        #
        # @example EnforcedStyle: rbs_return_comment
        #   # bad
        #   # @rbs return: String
        #   def method(arg) #: String
        #   end
        #
        #   # good
        #   # @rbs return: String
        #   def method(arg)
        #   end
        #
        class RedundantReturnType < Base
          include ConfigurableEnforcedStyle
          include RangeHelp

          MSG_RBS_RETURN = 'Redundant `@rbs return` annotation. ' \
                           'The return type is already annotated with inline comment.'
          MSG_INLINE = 'Redundant inline return type annotation. ' \
                       'The return type is already annotated with `@rbs return`.'

          attr_reader :result #: Array[RBS::Inline::AnnotationParser::ParsingResult]

          def on_new_investigation #: void
            super
            @result = parse_comments
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

          # @rbs node: Parser::AST::Node
          def process(node) #: void
            def_line = node.location.line

            inline_comment = find_inline_comment(def_line)
            return_annotation = find_return_annotation(def_line)

            unless inline_comment && return_annotation
              correct_style_detected
              return
            end

            case style
            when :inline_comment
              add_offense_for_rbs_return(return_annotation)
            when :rbs_return_comment
              add_offense(inline_comment, message: MSG_INLINE) { opposite_style_detected }
            end
          end

          # @rbs annotation: RBS::Inline::AST::Annotations::ReturnType
          def add_offense_for_rbs_return(annotation) #: void
            loc = annotation.source.comments.first&.location or return
            range = range_between(character_offset(loc.start_offset), character_offset(loc.end_offset))
            add_offense(range, message: MSG_RBS_RETURN) { opposite_style_detected }
          end

          # @rbs def_line: Integer
          def find_inline_comment(def_line) #: Parser::Source::Comment?
            processed_source.comments.find do |c|
              c.loc.expression.line == def_line && c.text.match?(/\A#:/)
            end
          end

          # @rbs def_line: Integer
          def find_return_annotation(def_line) #: RBS::Inline::AST::Annotations::ReturnType?
            parsing_result = result.find do |r|
              r.comments.map(&:location).map(&:start_line).include?(def_line - 1)
            end
            return unless parsing_result

            ret = nil #: RBS::Inline::AST::Annotations::ReturnType?
            parsing_result.each_annotation do |annotation|
              ret = annotation if annotation.is_a?(RBS::Inline::AST::Annotations::ReturnType)
            end
            ret
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
