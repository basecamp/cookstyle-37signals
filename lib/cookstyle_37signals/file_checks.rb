module Cookstyle37signals
  # Checks the files in a cookbook that Cookstyle does not inspect: templates and the static
  # files that cookbook_file copies to a node.
  class FileChecks
    Offense = Struct.new(:path, :line, :severity, :message) do
      def to_s
        "#{path}:#{line}: #{severity == :error ? "E" : "W"}: #{message}"
      end
    end

    HEADER = "Chef managed content"
    HEADER_LINES = 5
    RENDER = /render\(?\s*["']([^"']+)["']/
    UNINTERPOLATED_NAME = /\#\{(cookbook_name|recipe_name)\}/

    # Formats with no comment syntax, so a template cannot carry the header.
    HEADERLESS_EXTENSIONS = %w[ json sync-metadata ].freeze

    attr_reader :root

    def initialize(root)
      @root = File.expand_path(root)
    end

    # Checks the given paths, or every template and static file when none are given.
    def check(paths = [])
      candidates = if paths.empty?
        Dir.glob([ "templates/**/*", "files/**/*" ], base: root)
      else
        paths.map { |path| relative(path) }
      end

      candidates.select { |path| File.file?(File.join(root, path)) }.sort.flat_map { |path| check_file(path) }
    end

    private
      def check_file(path)
        if path.start_with?("templates/") && path.end_with?(".erb")
          check_template(path)
        elsif path.start_with?("files/")
          check_static_file(path)
        else
          []
        end
      end

      def check_template(path)
        if needs_header?(path) && !header?(path)
          [ Offense.new(path, 1, :warning, "Start the template with the \"Caution: #{HEADER}\" header.") ]
        else
          []
        end
      end

      def check_static_file(path)
        offenses = lines(path).each_with_index.filter_map do |line, index|
          if (match = line.match(UNINTERPOLATED_NAME))
            Offense.new(path, index + 1, :error, "cookbook_file copies this file verbatim, so \#{#{match[1]}} is not interpolated. Write the name out.")
          end
        end

        if script?(path) && !header?(path)
          offenses << Offense.new(path, 2, :warning, "Add the \"Caution: #{HEADER}\" header after the shebang line.")
        end

        offenses
      end

      def needs_header?(path)
        extension = File.basename(path, ".erb").split(".").last
        !HEADERLESS_EXTENSIONS.include?(extension) && !lines(path).empty? && !partial?(path)
      end

      # A template rendered inside another template shares that template's header.
      def partial?(path)
        name = path.delete_prefix("templates/").split("/", 2).last
        partial_names.any? { |partial| partial == name || partial.end_with?("/#{File.basename(path)}") }
      end

      def partial_names
        @partial_names ||= Dir.glob("templates/**/*.erb", base: root).flat_map do |template|
          File.read(File.join(root, template)).scan(RENDER).flatten
        end
      end

      # A template can take its header from a partial that it renders at the top.
      def header?(path)
        lines(path).first(HEADER_LINES).any? do |line|
          line.include?(HEADER) || rendered_templates(line).any? { |partial| header?(partial) }
        end
      end

      def rendered_templates(line)
        line.scan(RENDER).flatten.flat_map { |name| Dir.glob("templates/**/#{name}", base: root) }
      end

      def script?(path)
        lines(path).first&.start_with?("#!")
      end

      # Binary files have no lines to check.
      def lines(path)
        @lines ||= {}
        @lines[path] ||= begin
          content = File.binread(File.join(root, path)).force_encoding(Encoding::UTF_8)
          if content.valid_encoding?
            content.lines
          else
            []
          end
        end
      end

      def relative(path)
        File.expand_path(path).delete_prefix("#{root}/")
      end
  end
end
