module RuboCop
  module Cop
    module Cookbook
      # `cron_d` writes a self-contained file to /etc/cron.d, which is easier to inspect and to
      # remove than an entry in a user's crontab.
      #
      # @example
      #   # bad
      #   cron "redis-backup" do
      #     command "/usr/local/bin/redis_backup 2>&1 | logger -t redis-backup"
      #   end
      #
      #   # good
      #   cron_d "redis-backup" do
      #     command "/usr/local/bin/redis_backup 2>&1 | logger -t redis-backup"
      #   end
      class CronD < Base
        MSG = "Use the `cron_d` resource instead of `cron`."
        RESTRICT_ON_SEND = %i[ cron ].freeze

        def on_send(node)
          if node.receiver.nil? && node.arguments.any?
            add_offense(node.loc.selector)
          end
        end
      end
    end
  end
end
