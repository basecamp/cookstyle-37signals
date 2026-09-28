module RuboCop
  module Cop
    module Cookbook
      # A resource that receives a secret from a data bag or vault item sets `sensitive true`, so
      # Chef does not print the secret in the converge output or in a diff.
      #
      # The cop follows local variables assigned from a secret reader, and block parameters of
      # a call on such a variable. It cannot follow a secret through a method call, so it misses
      # some resources and reports some that receive only the non-secret part of an item.
      #
      # @example
      #   # bad
      #   password = vault_item("credentials", "mysql")["password"]
      #
      #   file "/etc/mysql/debian.cnf" do
      #     content "password = #{password}"
      #   end
      #
      #   # good
      #   file "/etc/mysql/debian.cnf" do
      #     content "password = #{password}"
      #     sensitive true
      #   end
      class SensitiveSecret < Base
        include Cookstyle37signals::ResourceHelpers

        MSG = "Set `sensitive true` on this `%<resource>s`, which uses a secret."
        SECRET_CLASSES = %w[ EncryptedDataBagItem Item ].freeze

        def on_new_investigation
          @secret_variables = nil
        end

        def on_send(node)
          if node.receiver.nil? && node.arguments.any? && resources.include?(node.method_name)
            if (block = resource_block(node)) && secret?(block.body) && !sensitive?(node)
              add_offense(node.loc.selector, message: format(MSG, resource: node.method_name))
            end
          end
        end

        private
          def resources
            @resources ||= cop_config.fetch("Resources").map(&:to_sym)
          end

          def readers
            @readers ||= cop_config.fetch("SecretReaders").map(&:to_sym)
          end

          def sensitive?(node)
            resource_properties(node, :sensitive).any? { |property| !property.first_argument&.false_type? }
          end

          def secret?(node)
            if node
              node.each_node(:send, :lvar).any? { |child| secret_read?(child) || secret_variable?(child) }
            else
              false
            end
          end

          def secret_read?(node)
            if node.send_type?
              (node.receiver.nil? && readers.include?(node.method_name)) || secret_class_load?(node)
            else
              false
            end
          end

          def secret_class_load?(node)
            node.method?(:load) && node.receiver&.const_type? && SECRET_CLASSES.include?(node.receiver.short_name.to_s)
          end

          def secret_variable?(node)
            node.lvar_type? && secret_variables.include?(node.children.first)
          end

          def secret_variables
            @secret_variables ||= find_secret_variables
          end

          def find_secret_variables
            @secret_variables = Set.new
            ast = processed_source.ast

            if ast
              loop do
                found = @secret_variables.size
                ast.each_node(:lvasgn) { |assignment| taint(assignment.name) if secret?(assignment.expression) }
                ast.each_node(:op_asgn, :or_asgn, :and_asgn) { |assignment| taint(assignment.name) if assignment.lhs.lvasgn_type? && secret?(assignment.expression) }
                ast.each_node(:block) { |block| block.arguments.each_node(:arg) { |argument| taint(argument.name) } if secret?(block.send_node) }
                break if @secret_variables.size == found
              end
            end

            @secret_variables
          end

          def taint(name)
            @secret_variables << name
          end
      end
    end
  end
end
