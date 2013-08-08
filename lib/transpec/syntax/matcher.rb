# coding: utf-8

module Transpec
  class Syntax
    class Matcher < Syntax
      include SendNodeSyntax, Util

      def initialize(node, in_example_group_context, source_rewriter)
        @node = node
        @in_example_group_context = in_example_group_context
        @source_rewriter = source_rewriter
      end

      def correct_operator!(parenthesize_arg = true)
        case method_name
        when :==
          @source_rewriter.replace(selector_range, 'eq')
          parenthesize!(parenthesize_arg)
        when :===, :<, :<=, :>, :>=
          @source_rewriter.insert_before(selector_range, 'be ')
        when :=~
          if arg_node.type == :array
            @source_rewriter.replace(selector_range, 'match_array')
          else
            @source_rewriter.replace(selector_range, 'match')
          end
          parenthesize!(parenthesize_arg)
        end
      end

      def parenthesize!(always = true)
        return if here_document?(arg_node)

        case left_parenthesis_range.source
        when ' '
          if always || arg_node.type == :hash
            @source_rewriter.replace(left_parenthesis_range, '(')
            @source_rewriter.insert_after(expression_range, ')')
          end
        when "\n", "\r"
          @source_rewriter.insert_before(left_parenthesis_range, '(')
          linefeed = left_parenthesis_range.source
          matcher_line_indentation = indentation_of_line(@node)
          right_parenthesis = "#{linefeed}#{matcher_line_indentation})"
          @source_rewriter.insert_after(expression_range, right_parenthesis)
        end
      end

      private

      def left_parenthesis_range
        Parser::Source::Range.new(
          selector_range.source_buffer,
          selector_range.end_pos,
          selector_range.end_pos + 1
        )
      end
    end
  end
end
