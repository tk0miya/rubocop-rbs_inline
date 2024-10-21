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
          include RangeHelp
          include RBS::Inline::AST::Annotations
          include RBS::Inline::AST::Members

          MSG = 'Invalid annotation found.'

          def on_new_investigation #: void # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
            results = parse_comments
            results.each do |result|
              result.each_annotation do |annotation|
                location = annotation.source.comments.first&.location or raise
                range = range_between(character_offset(location.start_offset), character_offset(location.end_offset))

                case annotation
                when Application
                  add_offense(range) unless annotation.types
                when BlockType, IvarType, SpecialVarTypeAnnotation, VarType
                  add_offense(range) unless annotation.type
                when Generic
                  add_offense(range) unless annotation.type_param
                when ModuleSelf
                  add_offense(range) if annotation.self_types.empty?
                when SyntaxErrorAssertion
                  add_offense(range)
                when Embedded
                  comment = annotation.source.comments.fetch(0)
                  parsing_result = RBS::Inline::AnnotationParser::ParsingResult.new(comment)
                  embedded = RBSEmbedded.new(parsing_result, annotation)
                  add_offense(range) if embedded.members.is_a?(RBS::ParsingError)
                end
              end
            end
          end

          private

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
