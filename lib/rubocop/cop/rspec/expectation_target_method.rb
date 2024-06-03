# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks ExpectationTarget method.
      #
      # @example
      #   # bad
      #   expect(something).kind_of? Foo
      #   is_expected == 42
      #
      #   # good
      #   expect(something).to be_a Foo
      #   is_expected.to eq 42
      #
      class ExpectationTargetMethod < Base
        MSG = 'Use `.to`, `.not_to` or `.to_not` to set an expectation.'
        RESTRICT_ON_SEND = %i[expect is_expected].freeze

        # @!method expect?(node)
        def_node_matcher :expect?, <<~PATTERN
          {
            (send nil? :expect ...)
            (send nil? :is_expected)
          }
        PATTERN

        # @!method expect_block?(node)
        def_node_matcher :expect_block?, <<~PATTERN
          (block #expect? (args) _body)
        PATTERN

        # @!method expectation_without_runner?(node)
        def_node_matcher :expectation_without_runner?, <<~PATTERN
          (send {#expect? #expect_block?} !#Runners.all ...)
        PATTERN

        def on_send(node)
          return unless expect?(node)

          if node.parent&.block_type?
            check_expect(node.parent)
          else
            check_expect(node)
          end
        end

        private

        def check_expect(node)
          return unless (parent = node.parent)
          return unless expectation_without_runner?(parent)

          add_offense(parent.loc.selector)
        end
      end
    end
  end
end
