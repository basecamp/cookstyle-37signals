module RuboCop
  module Cop
    module Cookbook
      # Include recipes from the same cookbook without repeating the cookbook's name.
      #
      # @example
      #   # bad, in the db_example cookbook
      #   include_recipe "db_example::_mysql"
      #
      #   # good
      #   include_recipe "::_mysql"
      class LocalIncludeRecipe < Base
        extend AutoCorrector

        MSG = "Include recipes from this cookbook as `%<local>s`."
        RESTRICT_ON_SEND = %i[ include_recipe ].freeze

        def on_send(node)
          if (recipe = node.first_argument)&.str_type? && (local = local_name(recipe.value))
            add_offense(recipe, message: format(MSG, local: local)) do |corrector|
              corrector.replace(recipe, recipe.source.sub(recipe.value, local))
            end
          end
        end

        private
          def local_name(recipe)
            cookbook, name = recipe.split("::", 2)

            if cookbook == own_cookbook
              "::#{name || "default"}"
            end
          end

          def own_cookbook
            Cookstyle37signals::CookbookName.for(processed_source.file_path)
          end
      end
    end
  end
end
