# coding: utf-8

module Transpec
  class Syntax
    class NotInExampleGroupContextError < StandardError
      attr_reader :message, :source_range

      def initialize(source_range, original_syntax, target_syntax)
        @source_range = source_range
        @message = build_message(original_syntax, target_syntax)
      end

      def source_buffer
        @source_range.source_buffer
      end

      private

      def build_message(original_syntax, target_syntax)
        "Cannot convert #{original_syntax} into #{target_syntax} " +
        "since #{target_syntax} is not available in the context."
      end
    end

    attr_reader :node, :ancestor_nodes, :in_example_group_context, :source_rewriter
    alias_method :in_example_group_context?, :in_example_group_context

    def self.all
      @subclasses ||= []
    end

    def self.inherited(subclass)
      all << subclass
    end

    def self.snake_case_name
      @snake_cake_name ||= begin
        class_name = name.split('::').last
        class_name.gsub(/([a-z])([A-Z])/, '\1_\2').downcase
      end
    end

    def self.target_node?(node)
      false
    end

    def initialize(node, ancestor_nodes, in_example_group_context, source_rewriter)
      @node = node
      @ancestor_nodes = ancestor_nodes
      @in_example_group_context = in_example_group_context
      @source_rewriter = source_rewriter
    end

    def parent_node
      @ancestor_nodes.last
    end
  end
end
