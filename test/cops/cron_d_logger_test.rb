require "test_helper"

class CronDLoggerTest < CopTest
  def cop_class = RuboCop::Cop::Cookbook::CronDLogger

  def test_unlogged_commands
    assert_equal [ 2, 6, 10 ], lines(<<~'RUBY')
      cron_d "discarded" do
        command "/usr/local/bin/backup &> /dev/null"
      end

      cron_d "mailed" do
        command "/usr/local/bin/backup"
      end

      cron_d "stdout-only" do
        command "/usr/local/bin/backup | logger -t backup"
      end
    RUBY
  end

  def test_logged_commands
    assert_empty offenses(<<~'RUBY')
      cron_d "redis-backup" do
        command "/usr/local/bin/redis_backup #{node["redis_master_name"]} 2>&1 | logger -t redis-backup"
      end

      cron_d "prune-docker-images" do
        command %[(echo "--- Docker prune"; docker image prune -a --force) 2>&1 | /usr/bin/logger -p user.info -t docker-cleanup]
      end
    RUBY
  end

  def test_deleted_crons_and_commands_from_variables
    assert_empty offenses(<<~'RUBY')
      cron_d "redis-backup" do
        action :delete
        command "/usr/local/bin/redis_backup"
      end

      cron_d "built-elsewhere" do
        command backup_command
      end
    RUBY
  end

  def test_severity_is_info
    assert_equal [ :info ], offenses(%(cron_d "backup" do\n  command "backup"\nend\n)).map { |offense| offense.severity.name }
  end
end
