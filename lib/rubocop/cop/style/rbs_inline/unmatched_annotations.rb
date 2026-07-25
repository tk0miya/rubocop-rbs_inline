# frozen_string_literal: true

require "rbs/inline"

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
          prepend FileFilter
          include CommentParser
          include RangeHelp
          include SourceCodeHelper

          MSG = "target parameter not found."

          attr_reader :processed_comments #: Set[RBS::Inline::AnnotationParser::ParsingResult] -- matched to a def node

          def on_new_investigation #: void
            super
            @processed_comments = Set.new
            parse_comments
          end

          # @rbs node: RuboCop::AST::DefNode
          def on_def(node) #: void
            process(node)
          end

          # @rbs node: RuboCop::AST::DefNode
          def on_defs(node) #: void
            process(node)
          end

          def on_investigation_end #: void
            parsed_comments.each do |comment|
              next if processed?(comment)

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

          # @rbs node: RuboCop::AST::DefNode
          def process(node) #: void
            arguments = arguments_for(node)

            comment = leading_comment_for(node)
            return unless comment

            mark_processed(comment)
            comment.each_annotation do |annotation|
              case annotation
              when RBS::Inline::AST::Annotations::IvarType
                add_offense_for(annotation)
              when RBS::Inline::AST::Annotations::VarType, RBS::Inline::AST::Annotations::BlockType
                add_offense_for(annotation) unless arguments.include?(annotation_name(annotation))
              end
            end
          end

          # @rbs node: RuboCop::AST::DefNode
          def leading_comment_for(node) #: RBS::Inline::AnnotationParser::ParsingResult?
            parsed_comments.find do |comment|
              next if processed?(comment)

              comment.comments.map(&:location).map(&:start_line).include?(node.location.line - 1)
            end
          end

          # @rbs comment: RBS::Inline::AnnotationParser::ParsingResult
          def mark_processed(comment) #: void
            processed_comments << comment
          end

          # @rbs comment: RBS::Inline::AnnotationParser::ParsingResult
          def processed?(comment) #: bool
            processed_comments.include?(comment)
          end

          # @rbs node: RuboCop::AST::DefNode
          def arguments_for(node) #: Array[String] # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
            args_for(node).children.flat_map do |argument| # rubocop:disable Metrics/BlockLength
              name = argument.children[0]&.to_s
              case argument.type
              when :arg, :optarg, :kwarg, :kwoptarg
                [name]
              when :restarg
                if name
                  ["*#{name}", "*"]
                else
                  ["*"]
                end
              when :kwrestarg
                if name
                  ["**#{name}", "**"]
                else
                  ["**"]
                end
              when :blockarg
                if name
                  ["&", "&#{name}"]
                else
                  ["&", "&block"]
                end
              when :forward_arg
                ["..."]
              else
                raise
              end
            end
          end

          # @rbs node: RuboCop::AST::DefNode
          def args_for(node) #: RuboCop::AST::Node
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
              "return"
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
            source = processed_source.buffer.source.dup.force_encoding("ASCII")
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
