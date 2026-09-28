require "test_helper"

class LocalIncludeRecipeTest < CopTest
  def cop_class = RuboCop::Cop::Cookbook::LocalIncludeRecipe

  def setup
    @cookbook = Dir.mktmpdir
    File.write(File.join(@cookbook, "metadata.rb"), %(name "db_example"\nversion "1.0.0"\n))
    @recipe = File.join(@cookbook, "recipes", "_mysql.rb")
  end

  def teardown
    FileUtils.remove_entry(@cookbook)
  end

  def test_includes_that_name_this_cookbook
    assert_equal [ 1, 2 ], lines(<<~RUBY, path: @recipe)
      include_recipe "db_example::_mysql_server" # Sets up the MySQL server
      include_recipe "db_example"
    RUBY
  end

  def test_local_and_other_cookbook_includes
    assert_empty offenses(<<~RUBY, path: @recipe)
      include_recipe "::_mysql_server"
      include_recipe "base_ubuntu::_common"
      include_recipe "db_example_extras::_tools"
      include_recipe "\#{cookbook_name}::_tools"
    RUBY
  end

  def test_autocorrect
    assert_equal <<~RUBY, autocorrect(<<~RUBY, path: @recipe)
      include_recipe "::_mysql_server" # Sets up the MySQL server
      include_recipe '::default'
    RUBY
      include_recipe "db_example::_mysql_server" # Sets up the MySQL server
      include_recipe 'db_example'
    RUBY
  end

  def test_message
    assert_equal [ "Include recipes from this cookbook as `::_mysql_server`." ], messages(%(include_recipe "db_example::_mysql_server"), path: @recipe)
  end
end
