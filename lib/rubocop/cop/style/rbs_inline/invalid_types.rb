# frozen_string_literal: true

require 'rbs/inline'

module RuboCop
  module Cop
    module Style
      module RbsInline
        # IRB::Inline expects the types of annotation comments are valid syntax.
        # This cop checks for comments that do not match the expected pattern.
        #
        # @example
        #   # bad
        #   # @rbs arg: Hash[Symbol,
        #   # @rbs &block: String
        #   def method(arg); end
        #
        #   # good
        #   # @rbs arg: Hash[Symbol, String]
        #   # @rbs &block: () -> void
        #   def method(arg); end
        #
        class InvalidTypes < Base
          include CommentParser
          include RangeHelp
          include RBS::Inline::AST::Annotations
          include RBS::Inline::AST::Members

          MSG = 'Invalid annotation found.'

          def on_new_investigation #: void
            parse_comments.each do |result|
              result.each_annotation do |annotation|
                add_offense(annotation_range(annotation)) if invalid_annotation?(annotation)
              end
            end
          end

          private

          # @rbs annotation: RBS::Inline::AST::Annotations::t
          def annotation_range(annotation) #: Parser::Source::Range
            location = annotation.source.comments.first&.location or raise
            range_between(character_offset(location.start_offset), character_offset(location.end_offset))
          end

          # @rbs annotation: RBS::Inline::AST::Annotations::t
          def invalid_annotation?(annotation) #: bool
            case annotation
            when Application then !annotation.types
            when BlockType, IvarType, SpecialVarTypeAnnotation, VarType then !annotation.type
            when Generic then !annotation.type_param
            when ModuleSelf then annotation.self_types.empty?
            when SyntaxErrorAssertion then true
            when Embedded then invalid_embedded?(annotation)
            else false
            end
          end

          # @rbs annotation: RBS::Inline::AST::Annotations::Embedded
          def invalid_embedded?(annotation) #: bool
            comment = annotation.source.comments.fetch(0)
            parsing_result = RBS::Inline::AnnotationParser::ParsingResult.new(comment)
            RBSEmbedded.new(parsing_result, annotation).members.is_a?(RBS::ParsingError)
          end
        end
      end
    end
  end
end
