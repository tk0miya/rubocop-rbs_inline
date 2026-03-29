# frozen_string_literal: true

D = Steep::Diagnostic

target :lib do
  signature 'sig'

  check 'lib'

  configure_code_diagnostics(D::Ruby.strict) do |hash|
    hash[D::Ruby::ImplicitBreakValueMismatch] = nil
  end
  implicitly_returns_nil!
end
