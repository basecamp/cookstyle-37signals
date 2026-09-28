require "test_helper"

class UnderscoreRunListTest < CopTest
  def cop_class = RuboCop::Cop::Cookbook::UnderscoreRunList

  def test_underscore_recipes_in_run_lists
    assert_equal [ 1, 2 ], lines(<<~RUBY, path: "/cookbooks/db_example/policyfiles/mysql-production.rb")
      run_list "db_example::_mysql"
      named_run_list :mysql, [ "db_example::mysql_production", "db_example::_backups" ]
    RUBY
  end

  def test_role_recipes_in_run_lists
    assert_empty offenses(<<~RUBY, path: "/cookbooks/db_example/policyfiles/mysql-production.rb")
      name "mysql-production"
      run_list "db_example::mysql_production"
      cookbook "db_example", path: ".."
    RUBY
  end
end
