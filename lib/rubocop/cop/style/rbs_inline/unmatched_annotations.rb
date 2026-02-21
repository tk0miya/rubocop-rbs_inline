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
        class UnmatchedAnnotations < Base # rubocop:disable Metrics/ClassLength
          include CommentParser
          include RangeHelp
          include SourceCodeHelper

          MSG = 'target parameter not found.'

          def on_new_investigation #: void
            super
            parse_comments
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
            parsed_comments.each do |comment|
              comment.each_annotation do |annotation|
                case annotation
                when RBS::Inline::AST::Annotations::BlockType,
                     RBS::Inline::AST::Annotations::ReturnType,
                     RBS::Inline::AST::Annotations::VarType
                  add_offense_for(annotation)
                end
              end
            end

            super
          end

          private

          # @rbs node: Parser::AST::Node
          def process(node) #: void # rubocop:disable Metrics/CyclomaticComplexity
            arguments = arguments_for(node)

            comment = parsed_comments.find do |r|
              r.comments.map(&:location).map(&:start_line).include?(node.location.line - 1)
            end
            return unless comment

            parsed_comments.delete(comment)
            comment.each_annotation do |annotation|
              case annotation
              when RBS::Inline::AST::Annotations::IvarType
                add_offense_for(annotation)
              when RBS::Inline::AST::Annotations::VarType, RBS::Inline::AST::Annotations::BlockType
                add_offense_for(annotation) unless arguments.include?(annotation_name(annotation))
              end
            end
          end

          # @rbs node: Parser::AST::Node
          def arguments_for(node) #: Array[String] # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
            args_for(node).children.flat_map do |argument| # rubocop:disable Metrics/BlockLength
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
              when :forward_arg
                ['...']
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

          # @rbs annotation: RBS::Inline::AST::Annotations::BlockType |
          #                  RBS::Inline::AST::Annotations::IvarType |
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
          #                  RBS::Inline::AST::Annotations::IvarType |
          #                  RBS::Inline::AST::Annotations::ReturnType |
          #                  RBS::Inline::AST::Annotations::VarType
          def add_offense_for(annotation) #: void # rubocop:disable Metrics/AbcSize
            name = annotation_name(annotation)
            loc = annotation.source.comments.first&.location or raise
            source = processed_source.buffer.source.dup.force_encoding('ASCII')
            text = source[loc.start_offset...loc.end_offset] or raise
            comment = text.force_encoding(processed_source.buffer.source.encoding)
            start_offset = loc.start_offset + (comment.index(name) || 0)
            range = range_between(character_offset(start_offset), character_offset(start_offset + name.size))
            add_offense(range)
          end
        end
      end
    end
  end
end
