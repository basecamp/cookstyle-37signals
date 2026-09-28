require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "cookstyle_37signals/file_checks"

class FileChecksTest < Minitest::Test
  HEADER = "# Caution: Chef managed content. This is template resource from <%= @cookbook_name %>::<%= @recipe_name %>\n#\n"

  def setup
    @cookbook = Dir.mktmpdir
  end

  def teardown
    FileUtils.remove_entry(@cookbook)
  end

  def test_templates_without_a_header
    write "templates/default/nginx.conf.erb", HEADER + "worker_processes auto;\n"
    write "templates/default/sshd_config.erb", "Port 22\n"
    write "templates/default/dashboard.json.erb", "{}\n"
    write "templates/default/empty.erb", ""

    assert_equal [ "templates/default/sshd_config.erb:1: W: Start the template with the \"Caution: Chef managed content\" header." ], check
  end

  def test_partials_share_the_header_of_the_template_that_renders_them
    write "templates/default/user-data.erb", "<%= render 'user-data-base.erb' %>\n<%= render 'storage.erb' %>\n"
    write "templates/default/user-data-base.erb", HEADER + "#cloud-config\n"
    write "templates/default/storage.erb", "storage:\n"

    assert_empty check
  end

  def test_static_files
    write "files/backup.sh", "#!/bin/bash\n# Caution: Chef managed content. This is a resource from app_backups::_backup\nrun\n"
    write "files/restore.sh", "#!/bin/bash\nrestore\n"
    write "files/cleanup.sh", "#!/bin/bash\n# Caution: Chef managed content. This is a resource from \#{cookbook_name}::\#{recipe_name}\n"
    write "files/vendor.conf", "setting = 1\n"
    File.binwrite(File.join(@cookbook, "files/logo.png"), "\x89PNG\r\n\xFF\xFE".b)

    assert_equal [
      "files/cleanup.sh:2: E: cookbook_file copies this file verbatim, so \#{cookbook_name} is not interpolated. Write the name out.",
      "files/restore.sh:2: W: Add the \"Caution: Chef managed content\" header after the shebang line.",
    ], check
  end

  def test_given_paths_only
    write "templates/default/a.erb", "a\n"
    write "templates/default/b.erb", "b\n"

    assert_equal [ "templates/default/b.erb:1: W: Start the template with the \"Caution: Chef managed content\" header." ],
      check(File.join(@cookbook, "templates/default/b.erb"), File.join(@cookbook, "recipes/default.rb"))
  end

  private
    def write(path, content)
      FileUtils.mkdir_p(File.dirname(File.join(@cookbook, path)))
      File.write(File.join(@cookbook, path), content)
    end

    def check(*paths)
      Cookstyle37signals::FileChecks.new(@cookbook).check(paths).map(&:to_s)
    end
end
