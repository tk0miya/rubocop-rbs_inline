# frozen_string_literal: true

require "rubocop-rbs_inline"
require "rubocop/rspec/support"

# `Mode` has no default outside `config/default.yml`, so every spec declares one.
# `opt_out` is the mode that inspects the plain sources specs are written with.
RSpec.shared_context "with Mode: opt_out" do
  let(:other_cops) { { "Style/RbsInline" => { "Mode" => "opt_out" } } }
end

# Same declaration, for the specs written against the default configuration.
module RbsInlineConfigHelper
  def rbs_inline_config
    defaults = RuboCop::ConfigLoader.default_configuration
    department = defaults["Style/RbsInline"].merge("Mode" => "opt_out")
    RuboCop::Config.new(defaults.merge("Style/RbsInline" => department))
  end
end

RSpec.configure do |config|
  config.include_context "with Mode: opt_out", :config
  config.include RbsInlineConfigHelper

  config.disable_monkey_patching!
  config.raise_errors_for_deprecations!
  config.raise_on_warning = true
  config.fail_if_no_examples = true

  config.order = :random
  Kernel.srand config.seed
end
