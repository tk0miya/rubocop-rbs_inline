# frozen_string_literal: true

require 'rbs/inline'

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Checks for redundant YARD type comments when RBS inline annotations exist.
        #
        # When both YARD documentation (`@param`, `@return`) and RBS::Inline annotations
        # are present for the same method, the YARD type information is considered redundant
        # since RBS provides the canonical type specification.
        #
        # @safety
        #   Autocorrection is unsafe because YARD comments may contain additional
        #   documentation beyond just type information (parameter descriptions, examples, notes).
        #   Removing YARD comments will lose this additional documentation.
        #
        # @example
        #   # bad - YARD @param when RBS annotation exists
        #   # @param name [String] the name
        #   #: (String) -> void
        #   def greet(name)
        #   end
        #
        #   # bad - YARD @return when RBS annotation exists
        #   # @return [String] the greeting
        #   #: () -> String
        #   def greet
        #   end
        #
        #   # bad - both YARD @param and @return with RBS
        #   # @param name [String] the name
        #   # @return [String] the greeting
        #   #: (String) -> String
        #   def greet(name)
        #   end
        #
        #   # good - only RBS annotations
        #   #: (String) -> String
        #   def greet(name)
        #   end
        #
        #   # good - only YARD comments (no RBS)
        #   # @param name [String] the name
        #   # @return [String] the greeting
        #   def greet(name)
        #   end
        #
        class RedundantYardComment < Base
          extend AutoCorrector
          include CommentParser
          include RangeHelp

          MSG_YARD_PARAM = 'Redundant YARD `@param` comment. Use RBS inline annotations instead.'
          MSG_YARD_RETURN = 'Redundant YARD `@return` comment. Use RBS inline annotations instead.'

          def on_new_investigation #: void
            super
            parse_comments
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
            check_parameter_redundancy(def_line)
            check_return_type_redundancy(def_line)
          end

          # @rbs def_line: Integer
          def check_parameter_redundancy(def_line) #: void
            yard_params = find_yard_param_comments(def_line)
            return if yard_params.empty?

            # Check if ANY RBS parameter annotations exist
            has_rbs_params = find_method_type_signature_comments(def_line) ||
                             find_doc_style_param_annotations(def_line)

            return unless has_rbs_params

            # Both exist - register offense on each YARD param
            yard_params.each { |comment| add_offense_for_yard_param(comment) }
          end

          # @rbs def_line: Integer
          def check_return_type_redundancy(def_line) #: void
            yard_return = find_yard_return_comment(def_line)
            return unless yard_return

            # Check if ANY RBS return annotation exists
            has_rbs_return = find_method_type_signature_comments(def_line) ||
                             find_doc_style_return_annotation(def_line) ||
                             find_trailing_comment(def_line)

            return unless has_rbs_return

            # Both exist - register offense
            add_offense_for_yard_return(yard_return)
          end

          # Find consecutive leading comments before a method definition
          # @rbs def_line: Integer
          def find_leading_comments(def_line) #: Array[Parser::Source::Comment]
            comments = [] #: Array[Parser::Source::Comment]
            line = def_line - 1

            # Walk backwards collecting consecutive comment lines
            while line.positive?
              comment = processed_source.comments.find { |c| c.loc.expression.line == line }
              break unless comment

              comments.unshift(comment)
              line -= 1
            end

            comments
          end

          # Find YARD @param comments before a method definition
          # @rbs def_line: Integer
          def find_yard_param_comments(def_line) #: Array[Parser::Source::Comment]
            leading_comments = find_leading_comments(def_line)
            leading_comments.select { |c| c.text.match?(/\A#\s+@param\b/) }
          end

          # Find YARD @return comment before a method definition
          # @rbs def_line: Integer
          def find_yard_return_comment(def_line) #: Parser::Source::Comment?
            leading_comments = find_leading_comments(def_line)
            leading_comments.find { |c| c.text.match?(/\A#\s+@return\b/) }
          end

          # @rbs comment: Parser::Source::Comment
          def add_offense_for_yard_param(comment) #: void
            add_offense(comment.loc.expression, message: MSG_YARD_PARAM) do |corrector|
              corrector.remove(range_by_whole_lines(comment.loc.expression,
                                                    include_final_newline: true))
            end
          end

          # @rbs comment: Parser::Source::Comment
          def add_offense_for_yard_return(comment) #: void
            add_offense(comment.loc.expression, message: MSG_YARD_RETURN) do |corrector|
              corrector.remove(range_by_whole_lines(comment.loc.expression,
                                                    include_final_newline: true))
            end
          end
        end
      end
    end
  end
end
