require "rubocop"

require_relative "cookstyle_37signals/cookbook_name"
require_relative "cookstyle_37signals/resource_helpers"

Dir[File.join(__dir__, "rubocop/cop/cookbook/*.rb")].sort.each { |cop| require cop }
