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
          MSG = 'Invalid RBS annotation comment found.'

          ANNOTATION_KEYWORDS = %w[return inherits override use module-self generic in out
                                   unchecked self skip yields module class].freeze #: Array[String]
          SIGNATURE_PATTERN = '\(.*\)\s*(\??\s*{.*?}\s*)?->\s*.*'

          # refs: https://github.com/soutaro/rbs-inline/blob/main/lib/rbs/inline/annotation_parser/tokenizer.rb
          RBS_INLINE_KEYWORDS = %w[inherits override use module-self generic skip module class].freeze #: Array[String]

          def on_new_investigation #: void
            comments = consume_embedded_rbs(processed_source.comments)
            comments.each do |comment|
              add_offense(comment) if comment.text =~ /\A#\s+#{SIGNATURE_PATTERN}/
              add_offense(comment) if comment.text =~ /\A#\s+:\s*#{SIGNATURE_PATTERN}/

              add_offense(comment) if comment.text =~ /\A#:\s+@rbs\s+/
              if comment.text =~ /\A#\s*rbs\s+(#{RBS_INLINE_KEYWORDS.join('|')}|\S+:|%a{.*}|#{SIGNATURE_PATTERN})/
                add_offense(comment)
              end
            end
          end

          private

          # @rbs comments: Array[Parser::Source::Comment]
          def consume_embedded_rbs(comments) #: Array[Parser::Source::Comment] # rubocop:disable Metrics/MethodLength
            in_embedded = false
            indent = 1
            line = 0
            comments.select do |comment|
              case comment.text
              when /\A#(\s+)@rbs!(\s+|\Z)/
                in_embedded = true
                indent = Regexp.last_match(1).to_s.size
                line = comment.loc.line
                false
              when /\A#(\s{#{indent + 1},}.*|\s*)\Z/
                if in_embedded && comment.loc.line == line + 1
                  line += 1
                  false
                else
                  true
                end
              else
                in_embedded = false
                true
              end
            end
          end
        end
      end
    end
  end
end
