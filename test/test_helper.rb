require "minitest/autorun"
require "tmpdir"
require "yaml"
require "cookstyle"
require "cookstyle-37signals"

class CopTest < Minitest::Test
  DEFAULT_CONFIG = YAML.load_file(File.expand_path("../config/default.yml", __dir__))

  private
    def offenses(source, path: "/cookbooks/example/recipes/default.rb")
      investigate(source, path).offenses
    end

    def messages(source, **options)
      offenses(source, **options).map(&:message)
    end

    def lines(source, **options)
      offenses(source, **options).map(&:line)
    end

    # The stdin option keeps the team from writing the corrected source to the file.
    def autocorrect(source, path: "/cookbooks/example/recipes/default.rb")
      report = investigate(source, path, autocorrect: true, stdin: source)
      corrector = RuboCop::Cop::Corrector.new(report.processed_source)
      report.correctors.compact.each { |cop_corrector| corrector.merge!(cop_corrector) }
      corrector.rewrite
    end

    def investigate(source, path, options = {})
      cop_config = DEFAULT_CONFIG.fetch(cop_class.cop_name).except("Include")
      config = RuboCop::Config.new({ cop_class.cop_name => cop_config }, File.join(File.dirname(path), ".rubocop.yml"))
      processed_source = RuboCop::ProcessedSource.new(source, 3.1, path)
      RuboCop::Cop::Team.mobilize([ cop_class ], config, **options, raise_error: true).investigate(processed_source)
    end
end
