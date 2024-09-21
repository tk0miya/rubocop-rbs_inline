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

            annotations = annotation_for(node).join("\n")
            parsed = parse(annotations)
            parsed.annotations.each do |annotation|
              case annotation
              when RBS::Inline::AST::Annotations::VarType
                add_offense_for(annotations, annotation) unless arguments.include?(annotation.name.to_s)
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

          def annotation_for(node)
            annotations = []
            line = node.loc.line - 2
            while (comment = processed_source.lines[line]) =~ /^\s*#/
              annotations << comment
              line -= 1
            end
            empty_lines = node.loc.line - 1 - annotations.size
            ([''] * empty_lines) + annotations
          end

          def parse(buffer)
            parse_result = Prism.parse(buffer)
            annotations = RBS::Inline::AnnotationParser.parse(parse_result.comments)
            annotations.first
          end

          def add_offense_for(buffer, annotation)
            loc = annotation.source.comments.first.location
            comment = buffer[loc.start_offset...loc.end_offset]
            pos = comment.index(annotation.name.to_s)
            range = range_between(loc.start_offset + pos, loc.start_offset + pos + annotation.name.size)
            add_offense(range)
          end
        end
      end
    end
  end
end
