module Cookstyle37signals
  # Queries on a Chef resource declaration such as `execute "name" do ... end`.
  module ResourceHelpers
    private
      # The block node of the resource, or nil when the resource is declared without a block.
      def resource_block(send_node)
        if send_node.parent&.block_type? && send_node.parent.send_node.equal?(send_node)
          send_node.parent
        end
      end

      def resource_properties(send_node, name)
        block = resource_block(send_node)
        if block&.body
          block.body.each_node(:send).select { |node| node.receiver.nil? && node.method?(name) }
        else
          []
        end
      end

      def property?(send_node, name)
        resource_properties(send_node, name).any?
      end

      def only_action?(send_node, action)
        resource_properties(send_node, :action).any? do |property|
          actions = property.arguments.flat_map { |argument| argument.array_type? ? argument.values : [ argument ] }
          actions.any? && actions.all? { |value| value.sym_type? && value.value == action }
        end
      end
  end
end
