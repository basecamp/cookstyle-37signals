require "test_helper"

class CronDTest < CopTest
  def cop_class = RuboCop::Cop::Cookbook::CronD

  def test_cron_resource
    assert_equal [ 1 ], lines(<<~RUBY)
      cron "redis-backup" do
        command "/usr/local/bin/redis_backup 2>&1 | logger -t redis-backup"
      end
    RUBY
  end

  def test_cron_d_resource_and_attributes
    assert_empty offenses(<<~RUBY)
      cron_d "redis-backup" do
        command "/usr/local/bin/redis_backup 2>&1 | logger -t redis-backup"
      end

      node["cron"]["mailto"]
    RUBY
  end
end
