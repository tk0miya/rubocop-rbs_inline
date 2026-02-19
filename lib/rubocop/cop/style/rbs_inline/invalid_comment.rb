# frozen_string_literal: true

require 'rbs/inline/annotation_parser/tokenizer'

module RuboCop
  module Cop
    module Style
      module RbsInline
        # IRB::Inline expects annotations comments to start with `#:` or `# @rbs`.
        # This cop checks for comments that do not match the expected pattern.
        #
        # @example
        #   # bad
        #   # () -> void
        #   # : () -> void
        #   # rbs param: String
        #
        #   # good
        #   #: () -> void
        #   # @rbs param: String
        #
        class InvalidComment < Base
          extend AutoCorrector

          MSG = 'Invalid RBS annotation comment found.'

          # refs: https://github.com/soutaro/rbs-inline/blob/main/lib/rbs/inline/annotation_parser/tokenizer.rb
          RBS_INLINE_KEYWORDS = %w[inherits override use module-self generic skip module class].freeze #: Array[String]
          RBS_INLINE_KEYWORD_PATTERN = RBS_INLINE_KEYWORDS.join('|') #: String

          SIGNATURE_PATTERN = '\(.*\)\s*(\??\s*{.*?}\s*)?->\s*.*'

          MISSING_HASH_COLON = /\A#\s+#{SIGNATURE_PATTERN}/
          SPACE_BEFORE_COLON = /\A#\s+:\s*#{SIGNATURE_PATTERN}/
          MIXED_ANNOTATION   = /\A#:\s+@rbs\s+/
          MISSING_AT_SIGN    = /\A#\s*rbs\s+(#{RBS_INLINE_KEYWORD_PATTERN}|\S+:|%a\{.*\}|#{SIGNATURE_PATTERN})/

          def on_new_investigation #: void
            consume_embedded_rbs(processed_source.comments).each do |comment|
              check_comment(comment)
            end
          end

          private

          # @rbs comment: Parser::Source::Comment
          def check_comment(comment) #: void
            corrected = corrected_text(comment.text)
            return unless corrected

            add_offense(comment) do |corrector|
              corrector.replace(comment.source_range, corrected)
            end
          end

          # @rbs text: String
          def corrected_text(text) #: String?
            case text
            when MISSING_HASH_COLON then text.sub(/\A#\s+/, '#: ')
            when SPACE_BEFORE_COLON then text.sub(/\A#\s+:\s*/, '#: ')
            when MIXED_ANNOTATION   then text.sub(/\A#:\s+/, '# ')
            when MISSING_AT_SIGN    then text.sub(/\A#\s*rbs\s+/, '# @rbs ')
            end
          end

          # @rbs comments: Array[Parser::Source::Comment]
          def consume_embedded_rbs(comments) #: Array[Parser::Source::Comment]
            in_embedded = false
            indent = 1
            line = 0

            comments.reject do |comment|
              if (match = comment.text.match(/\A#(\s+)@rbs!(\s+|\Z)/))
                in_embedded = true
                indent = match[1].size
                line = comment.loc.line
                true
              elsif in_embedded && comment.loc.line == line + 1 &&
                    comment.text.match?(/\A#(\s{#{indent + 1},}.*|\s*)\Z/)
                line += 1
                true
              else
                in_embedded = false
                false
              end
            end
          end
        end
      end
    end
  end
end
