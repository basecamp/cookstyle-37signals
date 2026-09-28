module RuboCop
  module Cop
    module Cookbook
      # Underscore-prefixed recipes are building blocks for the role recipes. A policy's run list
      # names the top-level recipe for its environment.
      #
      # @example
      #   # bad
      #   run_list "db_example::_mysql"
      #
      #   # good
      #   run_list "db_example::mysql_production"
      class UnderscoreRunList < Base
        MSG = "Put a top-level role recipe in the run list, not the underscore recipe `%<recipe>s`."
        RESTRICT_ON_SEND = %i[ run_list named_run_list ].freeze
        UNDERSCORE_RECIPE = /::_/

        def on_send(node)
          if node.receiver.nil?
            node.arguments.flat_map { |argument| argument.each_node(:str).to_a }.each do |recipe|
              if recipe.value.match?(UNDERSCORE_RECIPE)
                add_offense(recipe, message: format(MSG, recipe: recipe.value))
              end
            end
          end
        end
      end
    end
  end
end
