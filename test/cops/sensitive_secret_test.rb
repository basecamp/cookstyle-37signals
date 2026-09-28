require "test_helper"

class SensitiveSecretTest < CopTest
  def cop_class = RuboCop::Cop::Cookbook::SensitiveSecret

  def test_resources_that_use_a_secret
    assert_equal [ 5, 9, 14, 20 ], lines(<<~'RUBY')
      item = vault_item("credentials", "mysql")
      password = item["accounts"]["root"]
      config = "password = #{password}\n"

      file "/root/.my.cnf" do
        content config
      end

      template "/etc/app/database.yml" do
        variables(password: data_bag_item("credentials", "app")["password"])
      end

      item["users"].each do |user, secret|
        execute "create #{user}" do
          command "create-user #{user} #{secret}"
          not_if "user-exists #{user}"
        end
      end

      template "/etc/app/token" do
        variables(token: Chef::EncryptedDataBagItem.load("credentials", "token")["token"])
      end
    RUBY
  end

  def test_sensitive_resources_and_resources_without_secrets
    assert_empty offenses(<<~'RUBY')
      password = vault_item("credentials", "mysql")["password"]

      file "/root/.my.cnf" do
        content "password = #{password}"
        sensitive true
      end

      file "/etc/motd" do
        content "Welcome"
      end

      service "mysql" do
        subscribes :restart, "file[/root/.my.cnf]"
      end
    RUBY
  end

  def test_sensitive_false
    assert_equal [ 3 ], lines(<<~'RUBY')
      password = vault_item("credentials", "mysql")["password"]

      file "/root/.my.cnf" do
        content password
        sensitive false
      end
    RUBY
  end

  def test_secret_assembled_with_operator_assignment
    assert_equal [ 4 ], lines(<<~'RUBY')
      config = "[client]\n"
      config += "password = #{vault_item("credentials", "mysql")["password"]}\n"

      file "/root/.my.cnf" do
        content config
      end
    RUBY
  end
end
