module Cookstyle37signals
  # The name declared in the metadata.rb of the cookbook that contains a file.
  module CookbookName
    NAME_PATTERN = /^\s*name\s+["']([^"']+)["']/

    def self.for(path)
      @names ||= {}
      directory = File.dirname(File.expand_path(path))
      @names.fetch(directory) { @names[directory] = find(directory) }
    end

    def self.find(directory)
      loop do
        metadata = File.join(directory, "metadata.rb")
        if File.exist?(metadata)
          return File.read(metadata)[NAME_PATTERN, 1]
        end

        parent = File.dirname(directory)
        return nil if parent == directory
        directory = parent
      end
    end
  end
end
