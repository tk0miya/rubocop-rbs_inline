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

          attr_reader :result

          def on_new_investigation
            super
            @result = parse_comments
          end

          def on_def(node)
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

          def on_investigation_end
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

          def arguments_for(node) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
            node.children[1].children.flat_map do |argument|
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
              end
            end
          end

          def parse_comments
            parsed_result = Prism.parse(processed_source.buffer.source)
            RBS::Inline::AnnotationParser.parse(parsed_result.comments)
          end

          def annotation_name(annotation)
            case annotation
            when RBS::Inline::AST::Annotations::BlockType
              "&#{annotation.name}"
            when RBS::Inline::AST::Annotations::ReturnType
              'return'
            else
              annotation.name.to_s
            end
          end

          def add_offense_for(annotation) # rubocop:disable Metrics/AbcSize
            name = annotation_name(annotation)
            loc = annotation.source.comments.first.location
            source = processed_source.buffer.source.dup.force_encoding('ASCII')
            comment = source[loc.start_offset...loc.end_offset].force_encoding(processed_source.buffer.source.encoding)
            start_offset = loc.start_offset + comment.index(name)
            range = range_between(character_offset(start_offset), character_offset(start_offset + name.size))
            add_offense(range)
          end

          def character_offset(byte_offset)
            source = processed_source.buffer.source.dup.force_encoding('ASCII')
            source[...byte_offset].force_encoding(processed_source.buffer.source.encoding).size
          rescue StandardError
            byte_offset
          end
        end
      end
    end
  end
end
