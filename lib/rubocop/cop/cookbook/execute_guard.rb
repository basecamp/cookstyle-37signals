module RuboCop
  module Cop
    module Cookbook
      # Shell resources run on every converge unless a guard tells Chef when to skip them.
      #
      # @example
      #   # bad
      #   execute "mkfs.ext4 -L backups /dev/sdb"
      #
      #   # good
      #   execute "mkfs.ext4 -L backups /dev/sdb" do
      #     not_if "blkid /dev/sdb"
      #   end
      #
      #   # good, runs only when notified
      #   execute "systemctl daemon-reload" do
      #     action :nothing
      #   end
      class ExecuteGuard < Base
        include Cookstyle37signals::ResourceHelpers

        MSG = "Guard `%<resource>s` with `not_if`, `only_if` or `creates`, or set `action :nothing`, so it does not run on every converge."
        GUARDS = %i[ not_if only_if creates ].freeze

        def on_send(node)
          if node.receiver.nil? && node.arguments.any? && resources.include?(node.method_name) && !guarded?(node)
            add_offense(node.loc.selector, message: format(MSG, resource: node.method_name))
          end
        end

        private
          def resources
            @resources ||= cop_config.fetch("Resources").map(&:to_sym)
          end

          def guarded?(node)
            GUARDS.any? { |guard| property?(node, guard) } || only_action?(node, :nothing)
          end
      end
    end
  end
end
