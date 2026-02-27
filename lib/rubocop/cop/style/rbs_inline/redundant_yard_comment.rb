# frozen_string_literal: true

require 'rbs/inline'

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Checks for redundant YARD type comments when RBS inline annotations exist.
        #
        # When both YARD documentation (`@param`, `@return`, `@option`, `@yield`,
        # `@yieldparam`, `@yieldreturn`) and RBS::Inline annotations are present for the
        # same method, the YARD type information is considered redundant since RBS provides
        # the canonical type specification.
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
        #   # bad - YARD @option when RBS annotation exists
        #   # @option opts [String] :name the name
        #   #: (Hash[Symbol, untyped]) -> void
        #   def greet(opts)
        #   end
        #
        #   # bad - YARD @yieldparam when RBS block annotation exists
        #   # @yieldparam item [String] the item
        #   #: () { (String) -> void } -> void
        #   def each(&block)
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
          MSG_YARD_OPTION = 'Redundant YARD `@option` comment. Use RBS inline annotations instead.'
          MSG_YARD_YIELD = 'Redundant YARD `@yield` comment. Use RBS inline annotations instead.'
          MSG_YARD_YIELDPARAM = 'Redundant YARD `@yieldparam` comment. Use RBS inline annotations instead.'
          MSG_YARD_YIELDRETURN = 'Redundant YARD `@yieldreturn` comment. Use RBS inline annotations instead.'

          # @rbs YARD_TAGS_FOR_PARAMS: Regexp
          YARD_TAGS_FOR_PARAMS = /\A#\s+@(?:param|option)\b/
          # @rbs YARD_TAGS_FOR_BLOCK: Regexp
          YARD_TAGS_FOR_BLOCK = /\A#\s+@(?:yield|yieldparam|yieldreturn)\b/

          # @rbs MSG_MAP: Hash[String, String]
          MSG_MAP = {
            '@param' => MSG_YARD_PARAM,
            '@return' => MSG_YARD_RETURN,
            '@option' => MSG_YARD_OPTION,
            '@yield' => MSG_YARD_YIELD,
            '@yieldparam' => MSG_YARD_YIELDPARAM,
            '@yieldreturn' => MSG_YARD_YIELDRETURN
          }.freeze

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
            check_block_redundancy(def_line)
          end

          # @rbs def_line: Integer
          def check_parameter_redundancy(def_line) #: void
            yard_comments = find_yard_comments_by_pattern(def_line, YARD_TAGS_FOR_PARAMS)
            return if yard_comments.empty?

            has_rbs_params = find_method_type_signature_comments(def_line) ||
                             find_doc_style_param_annotations(def_line)
            return unless has_rbs_params

            yard_comments.each { |comment| add_offense_for_yard(comment) }
          end

          # @rbs def_line: Integer
          def check_return_type_redundancy(def_line) #: void
            yard_return = find_yard_return_comment(def_line)
            return unless yard_return

            has_rbs_return = find_method_type_signature_comments(def_line) ||
                             find_doc_style_return_annotation(def_line) ||
                             find_trailing_comment(def_line)
            return unless has_rbs_return

            add_offense_for_yard(yard_return)
          end

          # @rbs def_line: Integer
          def check_block_redundancy(def_line) #: void
            yard_comments = find_yard_comments_by_pattern(def_line, YARD_TAGS_FOR_BLOCK)
            return if yard_comments.empty?

            has_rbs_block = find_method_type_signature_comments(def_line) ||
                            find_doc_style_block_annotation(def_line)
            return unless has_rbs_block

            yard_comments.each { |comment| add_offense_for_yard(comment) }
          end

          # Find consecutive leading comments before a method definition
          # @rbs def_line: Integer
          def find_leading_comments(def_line) #: Array[Parser::Source::Comment]
            comments = [] #: Array[Parser::Source::Comment]
            line = def_line - 1

            while line.positive?
              comment = processed_source.comments.find { |c| c.loc.expression.line == line }
              break unless comment

              comments.unshift(comment)
              line -= 1
            end

            comments
          end

          # Find YARD comments matching a pattern before a method definition
          # @rbs def_line: Integer
          # @rbs pattern: Regexp
          def find_yard_comments_by_pattern(def_line, pattern) #: Array[Parser::Source::Comment]
            find_leading_comments(def_line).select { |c| c.text.match?(pattern) }
          end

          # Find YARD @return comment before a method definition
          # @rbs def_line: Integer
          def find_yard_return_comment(def_line) #: Parser::Source::Comment?
            find_leading_comments(def_line).find { |c| c.text.match?(/\A#\s+@return\b/) }
          end

          # Find @rbs block annotation before a method definition
          # @rbs def_line: Integer
          def find_doc_style_block_annotation(def_line) #: RBS::Inline::AST::Annotations::BlockType?
            leading_annotation = find_leading_annotation(def_line)
            return unless leading_annotation

            ret = nil #: RBS::Inline::AST::Annotations::BlockType?
            leading_annotation.each_annotation do |annotation|
              ret = annotation if annotation.is_a?(RBS::Inline::AST::Annotations::BlockType)
            end
            ret
          end

          # Detect the YARD tag name from a comment and register an offense
          # @rbs comment: Parser::Source::Comment
          def add_offense_for_yard(comment) #: void
            tag = comment.text[/@(\w+)/, 1] or return
            message = MSG_MAP["@#{tag}"] or return

            add_offense(comment.loc.expression, message:) do |corrector|
              corrector.remove(range_by_whole_lines(comment.loc.expression,
                                                    include_final_newline: true))
            end
          end
        end
      end
    end
  end
end
