# frozen_string_literal: true

require 'rubocop'

require_relative 'rubocop/rbs_inline'
require_relative 'rubocop/rbs_inline/version'
require_relative 'rubocop/rbs_inline/inject'

RuboCop::RbsInline::Inject.defaults!

require_relative 'rubocop/cop/rbs_inline_cops'
