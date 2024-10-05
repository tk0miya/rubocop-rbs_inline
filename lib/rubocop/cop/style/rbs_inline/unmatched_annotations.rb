# frozen_string_literal: true

require 'rbs/inline'

module RuboCop
  module Cop
    module Style
      module RbsInline
        # IRB::Inline annotations comments for parameters should be matched to the parameters.
        #
        # @example
        #   # bad
        #   # @rbs unknown: String
        #   def method(arg); end
        #
        #   # good
        #   # @rbs arg: String
        #   def method(arg); end
        #
        class UnmatchedAnnotations < Base
          include RangeHelp

          MSG = 'target parameter not found.'

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

          def on_investigation_end #: void
            result.each do |comment|
              comment.each_annotation do |annotation|
                case annotation
                when RBS::Inline::AST::Annotations::VarType
                  add_offense_for(annotation) unless annotation.name.start_with?('@')
                when RBS::Inline::AST::Annotations::BlockType, RBS::Inline::AST::Annotations::ReturnType
                  add_offense_for(annotation)
                end
              end
            end

            super
          end

          private

          # @rbs node: Parser::AST::Node
          def process(node) #: void
            arguments = arguments_for(node)

            comment = result.find { |r| r.comments.map(&:location).map(&:start_line).include? node.location.line - 1 }
            return unless comment

            result.delete(comment)
            comment.each_annotation do |annotation|
              case annotation
              when RBS::Inline::AST::Annotations::VarType, RBS::Inline::AST::Annotations::BlockType
                add_offense_for(annotation) unless arguments.include?(annotation_name(annotation))
              end
            end
          end

          # @rbs node: Parser::AST::Node
          def arguments_for(node) #: Array[String] # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
            args_for(node).children.flat_map do |argument|
              name = argument.children[0]&.to_s
              case argument.type
              when :arg, :optarg, :kwarg, :kwoptarg
                [name]
              when :restarg
                if name
                  ["*#{name}", '*']
                else
                  ['*']
                end
              when :kwrestarg
                if name
                  ["**#{name}", '**']
                else
                  ['**']
                end
              when :blockarg
                if name
                  ['&', "&#{name}"]
                else
                  ['&', '&block']
                end
              else
                raise
              end
            end
          end

          # @rbs node: Parser::AST::Node
          def args_for(node) #: Parser::AST::Node
            case node.type
            when :defs
              node.children[2]
            else
              node.children[1]
            end
          end

          def parse_comments #: Array[RBS::Inline::AnnotationParser::ParsingResult]
            parsed_result = Prism.parse(processed_source.buffer.source)
            RBS::Inline::AnnotationParser.parse(parsed_result.comments)
          end

          # @rbs annotation: RBS::Inline::AST::Annotations::BlockType |
          #                  RBS::Inline::AST::Annotations::ReturnType |
          #                  RBS::Inline::AST::Annotations::VarType
          def annotation_name(annotation) #: String
            case annotation
            when RBS::Inline::AST::Annotations::BlockType
              "&#{annotation.name}"
            when RBS::Inline::AST::Annotations::ReturnType
              'return'
            else
              annotation.name.to_s
            end
          end

          # @rbs annotation: RBS::Inline::AST::Annotations::BlockType |
          #                  RBS::Inline::AST::Annotations::ReturnType |
          #                  RBS::Inline::AST::Annotations::VarType
          def add_offense_for(annotation) #: void # rubocop:disable Metrics/AbcSize
            name = annotation_name(annotation)
            loc = annotation.source.comments.first.location
            source = processed_source.buffer.source.dup.force_encoding('ASCII')
            text = source[loc.start_offset...loc.end_offset] or raise
            comment = text.force_encoding(processed_source.buffer.source.encoding)
            start_offset = loc.start_offset + (comment.index(name) || 0)
            range = range_between(character_offset(start_offset), character_offset(start_offset + name.size))
            add_offense(range)
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
