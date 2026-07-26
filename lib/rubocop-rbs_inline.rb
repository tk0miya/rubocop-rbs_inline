# frozen_string_literal: true

require "rubocop"

require_relative "rubocop/rbs_inline"
require_relative "rubocop/rbs_inline/plugin"
require_relative "rubocop/rbs_inline/version"

require_relative "rubocop/cop/rbs_inline_cops"

# Report deprecated parameters of this gem while RuboCop validates the configuration.
RuboCop::ConfigObsoletion.files << File.expand_path("../config/obsoletion.yml", File.dirname(__FILE__))
