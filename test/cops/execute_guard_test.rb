require "test_helper"

class ExecuteGuardTest < CopTest
  def cop_class = RuboCop::Cop::Cookbook::ExecuteGuard

  def test_unguarded_shell_resources
    assert_equal [ 1, 3, 7 ], lines(<<~RUBY)
      execute "systemctl daemon-reload"

      bash "install yq" do
        code "wget -O /usr/bin/yq https://example.com/yq"
      end

      execute "bundle install" do
        action :run
      end
    RUBY
  end

  def test_guarded_shell_resources
    assert_empty offenses(<<~RUBY)
      execute "mkfs.ext4 -L backups /dev/sdb" do
        not_if "blkid /dev/sdb"
      end

      execute "filebeat modules enable redis" do
        creates "/etc/filebeat/modules.d/redis.yml"
      end

      bash "reload" do
        code "systemctl reload nginx"
        only_if { ::File.exist?("/run/nginx.pid") }
      end

      execute "systemctl daemon-reload" do
        action :nothing
      end

      execute "apt-get update" do
        action [ :nothing ]
      end
    RUBY
  end

  def test_other_resources_and_references
    assert_empty offenses(<<~RUBY)
      package "rsync"
      execute
      notifies :run, "execute[systemctl daemon-reload]"
    RUBY
  end

  def test_message_names_the_resource
    assert_equal [ "Guard `bash` with `not_if`, `only_if` or `creates`, or set `action :nothing`, so it does not run on every converge." ],
      messages(%(bash "install yq"))
  end
end
