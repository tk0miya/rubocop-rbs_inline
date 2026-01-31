# frozen_string_literal: true

require 'rbs/inline'

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Checks for redundant argument type annotations when both
        # annotation comments (`#:`) and `@rbs` parameter comments
        # specify argument types for the same method.
        #
        # Supports two styles:
        # - `annotation_comment`: Prefers `#:` annotation comments with parameter types
        # - `rbs_param_comment`: Prefers `# @rbs param:` annotations for parameter types
        #
        # @example EnforcedStyle: annotation_comment (default)
        #   # bad
        #   # @rbs a: Integer
        #   #: (Integer) -> void
        #   def method(a)
        #   end
        #
        #   # good
        #   #: (Integer) -> void
        #   def method(a)
        #   end
        #
        #   # good
        #   # @rbs a: Integer
        #   def method(a) #: void
        #   end
        #
        # @example EnforcedStyle: rbs_param_comment
        #   # bad
        #   # @rbs a: Integer
        #   #: (Integer) -> void
        #   def method(a)
        #   end
        #
        #   # good
        #   # @rbs a: Integer
        #   def method(a) #: void
        #   end
        #
        #   # good
        #   #: (Integer) -> void
        #   def method(a)
        #   end
        #
        class RedundantArgumentType < Base
          extend AutoCorrector
          include ConfigurableEnforcedStyle
          include RangeHelp

          MSG_RBS_PARAM = 'Redundant `@rbs` parameter annotation.'
          MSG_ANNOTATION = 'Redundant annotation comment.'

          attr_reader :result #: Array[RBS::Inline::AnnotationParser::ParsingResult]

          def on_new_investigation #: void
            super
            @result = parse_comments
          end

          # @rbs node: Parser::AST::Node
          def on_def(node) #: void
            process(node)
          end
          alias on_defs on_def

          private

          # @rbs node: Parser::AST::Node
          def process(node) #: void
            def_line = node.location.line
            annotation_comments = find_annotation_comments(def_line)
            param_annotations = find_param_annotations(def_line)

            unless annotation_comments && param_annotations
              correct_style_detected
              return
            end

            redundant = find_redundant_annotations(annotation_comments, param_annotations)

            if redundant.empty?
              correct_style_detected
              return
            end

            case style
            when :annotation_comment
              redundant.each { |a| add_offense_for_rbs_param(a) }
            when :rbs_param_comment
              add_offense_for_annotation(annotation_comments)
            end
          end

          # @rbs comments: Array[Parser::Source::Comment]
          def add_offense_for_annotation(comments) #: void
            first = comments.first or return
            last = comments.last or return
            range = first.loc.expression.join(last.loc.expression)
            add_offense(range, message: MSG_ANNOTATION) do
              unexpected_style_detected(:annotation_comment)
            end
          end

          # @rbs annotation: RBS::Inline::AST::Annotations::VarType | RBS::Inline::AST::Annotations::BlockType
          def add_offense_for_rbs_param(annotation) #: void
            loc = annotation.source.comments.first&.location or return
            range = range_between(character_offset(loc.start_offset), character_offset(loc.end_offset))
            add_offense(range, message: MSG_RBS_PARAM) do |corrector|
              unexpected_style_detected(:rbs_param_comment)
              next unless style == :annotation_comment

              corrector.remove(range_by_whole_lines(range, include_final_newline: true))
            end
          end

          # @rbs annotation_comments: Array[Parser::Source::Comment]
          # @rbs param_annotations: Array[RBS::Inline::AST::Annotations::VarType | RBS::Inline::AST::Annotations::BlockType]
          def find_redundant_annotations(annotation_comments, param_annotations) #: Array[RBS::Inline::AST::Annotations::VarType | RBS::Inline::AST::Annotations::BlockType]
            text = annotation_comments.map { |c| c.text.sub(/\A#:\s?/, '') }.join(' ').strip
            has_positional_params = text.match?(/\A\(\s*[^)\s]/)
            has_block_type = text.include?('{')

            param_annotations.select do |a|
              case a
              when RBS::Inline::AST::Annotations::VarType
                has_positional_params
              when RBS::Inline::AST::Annotations::BlockType
                has_block_type
              else
                false
              end
            end
          end

          # @rbs def_line: Integer
          def find_annotation_comments(def_line) #: Array[Parser::Source::Comment]?
            leading_annotation = find_leading_annotation(def_line)
            return unless leading_annotation

            annotation_lines = leading_annotation.comments
                                                 .select { |c| c.location.slice.start_with?('#:') }
                                                 .map { |c| c.location.start_line }
            return if annotation_lines.empty?

            comments = processed_source.comments.select do |c|
              annotation_lines.include?(c.loc.expression.line)
            end
            comments.empty? ? nil : comments
          end

          # @rbs def_line: Integer
          def find_param_annotations(def_line) #: Array[RBS::Inline::AST::Annotations::VarType | RBS::Inline::AST::Annotations::BlockType]?
            leading_annotation = find_leading_annotation(def_line)
            return unless leading_annotation

            annotations = [] #: Array[RBS::Inline::AST::Annotations::VarType | RBS::Inline::AST::Annotations::BlockType]
            leading_annotation.each_annotation do |annotation|
              case annotation
              when RBS::Inline::AST::Annotations::VarType, RBS::Inline::AST::Annotations::BlockType
                annotations << annotation
              end
            end
            annotations.empty? ? nil : annotations
          end

          # @rbs def_line: Integer
          def find_leading_annotation(def_line) #: RBS::Inline::AnnotationParser::ParsingResult?
            result.find do |r|
              last_comment = r.comments.last or next
              last_comment.location.start_line + 1 == def_line
            end
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
