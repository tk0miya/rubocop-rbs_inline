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
        class UnusedAnnotations < Base
          include RangeHelp

          MSG = 'target parameter not found.'

          def on_def(node)
            arguments = arguments_for(node)

            result = parse_comments
            result.first.each_annotation do |annotation|
              case annotation
              when RBS::Inline::AST::Annotations::VarType
                add_offense_for(annotation) unless arguments.include?(annotation.name.to_s)
              end
            end
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
                  ["&#{name}", '&']
                else
                  ['&']
                end
              end
            end
          end

          def parse_comments
            parsed_result = Prism.parse(processed_source.buffer.source)
            RBS::Inline::AnnotationParser.parse(parsed_result.comments)
          end

          def add_offense_for(annotation) # rubocop:disable Metrics/AbcSize
            loc = annotation.source.comments.first.location
            comment = processed_source.buffer.source[loc.start_offset...loc.end_offset]
            start_offset = loc.start_offset + comment.index(annotation.name.to_s)
            range = range_between(start_offset, start_offset + annotation.name.size)
            add_offense(range)
          end
        end
      end
    end
  end
end
