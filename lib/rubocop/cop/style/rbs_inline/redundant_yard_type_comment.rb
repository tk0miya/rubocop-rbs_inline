# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Checks for YARD type comments (@param, @return) that are redundant
        # when RBS inline type annotations are also present.
        #
        # When migrating from YARD to RBS inline, having both type documentation
        # systems creates duplication. This cop detects such cases and can
        # auto-correct by removing the YARD type comments, optionally merging
        # descriptions into RBS annotations.
        #
        # @example
        #   # bad - YARD and RBS type comments coexist
        #   # @param name [String] the name
        #   # @rbs name: String
        #   def greet(name); end
        #
        #   # good - autocorrected (description merged)
        #   # @rbs name: String -- the name
        #   def greet(name); end
        #
        #   # bad - YARD @return with RBS return type
        #   # @return [Integer]
        #   # @rbs return: Integer
        #   def count; end
        #
        #   # good - only RBS type comments
        #   # @rbs name: String
        #   def greet(name); end
        #
        #   # good - only YARD comments (no RBS)
        #   # @param name [String] the name
        #   def greet(name); end
        #
        class RedundantYardTypeComment < Base
          extend AutoCorrector
          include RangeHelp

          MSG = 'Redundant YARD type comment. Use RBS inline annotation instead.'
          MSG_WITH_MERGE = 'Redundant YARD type comment. Description merged into RBS annotation.'

          # YARD comment patterns with capture groups for name, type, and description
          # @rbs!
          #   type yard_kind = :param | :return | :yield | :yieldparam | :yieldreturn

          YARD_PATTERNS = {
            param: /\A#\s*@param\s+(\S+)\s+\[([^\]]+)\](?:\s+(.+))?\z/,
            return: /\A#\s*@return\s+\[([^\]]+)\](?:\s+(.+))?\z/,
            yield: /\A#\s*@yield\s+\[([^\]]+)\](?:\s+(.+))?\z/,
            yieldparam: /\A#\s*@yieldparam\s+(\S+)\s+\[([^\]]+)\](?:\s+(.+))?\z/,
            yieldreturn: /\A#\s*@yieldreturn\s+\[([^\]]+)\](?:\s+(.+))?\z/
          }.freeze #: Hash[yard_kind, Regexp]

          # RBS comment pattern: # @rbs name: Type -- description
          RBS_PARAM_PATTERN = /\A#\s+@rbs\s+(\S+?):\s*(.+?)(?:\s+--\s+(.+))?\z/ #: Regexp

          # @rbs node: Parser::AST::Node
          def on_def(node) #: void
            process(node)
          end

          # @rbs node: Parser::AST::Node
          def on_defs(node) #: void
            process(node)
          end

          private

          # @rbs node: Parser::AST::Node
          def process(node) #: void
            method_line = node.location.line
            preceding_comments = find_preceding_comments(method_line)
            return if preceding_comments.empty?

            yard_comments = preceding_comments.filter_map { |c| parse_yard_comment(c) }
            return if yard_comments.empty?

            rbs_comments = preceding_comments.filter_map { |c| parse_rbs_comment(c) }
            return if rbs_comments.empty? && !has_rbs_signature?(preceding_comments, method_line)

            yard_comments.each do |yard_info|
              rbs_info = find_matching_rbs(yard_info, rbs_comments)
              process_yard_comment(yard_info, rbs_info)
            end
          end

          # @rbs comment: Parser::Source::Comment
          # @rbs return: { comment: Parser::Source::Comment, kind: yard_kind, name: String?, type: String, description: String? }?
          def parse_yard_comment(comment)
            text = comment.text

            YARD_PATTERNS.each do |kind, pattern|
              match = text.match(pattern)
              next unless match

              case kind
              when :param, :yieldparam
                return { comment: comment, kind: kind, name: match[1], type: match[2], description: match[3] }
              when :return, :yield, :yieldreturn
                return { comment: comment, kind: kind, name: nil, type: match[1], description: match[2] }
              end
            end

            nil
          end

          # @rbs comment: Parser::Source::Comment
          # @rbs return: { comment: Parser::Source::Comment, name: String, type: String, description: String? }?
          def parse_rbs_comment(comment)
            match = comment.text.match(RBS_PARAM_PATTERN)
            return nil unless match

            { comment: comment, name: match[1], type: match[2], description: match[3] }
          end

          # @rbs yard_info: { comment: Parser::Source::Comment, kind: yard_kind, name: String?, type: String, description: String? }
          # @rbs rbs_comments: Array[{ comment: Parser::Source::Comment, name: String, type: String, description: String? }]
          # @rbs return: { comment: Parser::Source::Comment, name: String, type: String, description: String? }?
          def find_matching_rbs(yard_info, rbs_comments)
            target_name = case yard_info[:kind]
                          when :param, :yieldparam
                            yard_info[:name]
                          when :return, :yieldreturn
                            'return'
                          when :yield
                            # @yield could match &block or yields
                            return rbs_comments.find { |r| r[:name].start_with?('&') || r[:name] == 'yields' }
                          end

            rbs_comments.find { |r| r[:name] == target_name }
          end

          # @rbs yard_info: { comment: Parser::Source::Comment, kind: yard_kind, name: String?, type: String, description: String? }
          # @rbs rbs_info: { comment: Parser::Source::Comment, name: String, type: String, description: String? }?
          def process_yard_comment(yard_info, rbs_info) #: void
            yard_comment = yard_info[:comment]
            yard_description = yard_info[:description]

            # If no matching RBS found but we know RBS exists, just remove YARD
            unless rbs_info
              add_offense(yard_comment, message: MSG) do |corrector|
                remove_comment_line(corrector, yard_comment)
              end
              return
            end

            rbs_comment = rbs_info[:comment]
            rbs_description = rbs_info[:description]

            if yard_description && !rbs_description
              # YARD has description, RBS doesn't - merge description into RBS
              add_offense(yard_comment, message: MSG_WITH_MERGE) do |corrector|
                merge_description_into_rbs(corrector, yard_comment, rbs_comment, yard_description)
              end
            else
              # Either both have descriptions or only RBS has one - just remove YARD
              add_offense(yard_comment, message: MSG) do |corrector|
                remove_comment_line(corrector, yard_comment)
              end
            end
          end

          # @rbs method_line: Integer
          def find_preceding_comments(method_line) #: Array[Parser::Source::Comment]
            comments = processed_source.comments.select do |comment|
              comment.loc.line < method_line
            end

            # Find consecutive comments immediately before the method
            result = [] #: Array[Parser::Source::Comment]
            comments.reverse_each do |comment|
              expected_line = result.empty? ? method_line - 1 : result.last.loc.line - 1
              break unless comment.loc.line == expected_line

              result << comment
            end

            result.reverse
          end

          # @rbs preceding_comments: Array[Parser::Source::Comment]
          # @rbs method_line: Integer
          def has_rbs_signature?(preceding_comments, method_line) #: bool
            preceding_comments.any? do |c|
              c.loc.line == method_line - 1 && c.text.match?(/\A#:/)
            end
          end

          # @rbs corrector: RuboCop::Cop::Corrector
          # @rbs yard_comment: Parser::Source::Comment
          # @rbs rbs_comment: Parser::Source::Comment
          # @rbs description: String
          def merge_description_into_rbs(corrector, yard_comment, rbs_comment, description) #: void
            # Remove YARD comment
            remove_comment_line(corrector, yard_comment)

            # Add description to RBS comment
            rbs_end_pos = rbs_comment.source_range.end_pos
            corrector.insert_after(rbs_comment.source_range, " -- #{description}")
          end

          # @rbs corrector: RuboCop::Cop::Corrector
          # @rbs comment: Parser::Source::Comment
          def remove_comment_line(corrector, comment) #: void
            range = comment_with_surrounding_whitespace(comment)
            corrector.remove(range)
          end

          # @rbs comment: Parser::Source::Comment
          def comment_with_surrounding_whitespace(comment) #: Parser::Source::Range
            source = processed_source.buffer.source
            begin_pos = comment.source_range.begin_pos
            end_pos = comment.source_range.end_pos

            # Include leading whitespace on the same line
            while begin_pos.positive? && source[begin_pos - 1] =~ /[ \t]/
              begin_pos -= 1
            end

            # Include trailing newline if present
            end_pos += 1 if source[end_pos] == "\n"

            range_between(begin_pos, end_pos)
          end
        end
      end
    end
  end
end
