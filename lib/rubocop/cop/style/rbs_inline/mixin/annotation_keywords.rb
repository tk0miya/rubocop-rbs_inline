# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      module RbsInline
        # Provides the list of keywords that may follow `# @rbs` in an annotation comment.
        #
        # refs: https://github.com/soutaro/rbs-inline/blob/main/lib/rbs/inline/annotation_parser/tokenizer.rb
        module AnnotationKeywords
          RBS_INLINE_KEYWORDS = %w[inherits override use module-self generic skip module class].freeze #: Array[String]
        end
      end
    end
  end
end
