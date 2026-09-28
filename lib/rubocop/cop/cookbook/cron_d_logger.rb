module RuboCop
  module Cop
    module Cookbook
      # Send cron output to the journal with `2>&1 | logger -t <tag>`. Without it, cron mails the
      # output to a local mailbox that nobody reads, or the output is discarded.
      #
      # @example
      #   # bad
      #   cron_d "redis-backup" do
      #     command "/usr/local/bin/redis_backup &> /dev/null"
      #   end
      #
      #   # good
      #   cron_d "redis-backup" do
      #     command "/usr/local/bin/redis_backup 2>&1 | logger -t redis-backup"
      #   end
      class CronDLogger < Base
        include Cookstyle37signals::ResourceHelpers

        MSG = "Pipe the command's output to the journal with `2>&1 | logger -t <tag>`."
        RESTRICT_ON_SEND = %i[ cron_d ].freeze
        LOGGED = %r{2>&1\s*\|\s*(\S*/)?logger\b[^|]*\s-t\b}

        def on_send(node)
          if node.receiver.nil? && !only_action?(node, :delete)
            resource_properties(node, :command).each do |command|
              if unlogged?(command.first_argument)
                add_offense(command)
              end
            end
          end
        end

        private
          def unlogged?(value)
            if value&.type?(:str, :dstr)
              !value.source.match?(LOGGED)
            else
              false
            end
          end
      end
    end
  end
end
