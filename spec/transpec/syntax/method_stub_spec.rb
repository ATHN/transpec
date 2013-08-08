# coding: utf-8

require 'spec_helper'

module Transpec
  class Syntax
    describe MethodStub do
      include_context 'parsed objects'

      subject(:method_stub_object) do
        AST::Scanner.scan(ast) do |node, ancestor_nodes, in_example_group_context|
          next unless MethodStub.target_node?(node)
          return MethodStub.new(
            node,
            ancestor_nodes,
            in_example_group_context?,
            source_rewriter
          )
        end
        fail 'No method stub node is found!'
      end

      let(:in_example_group_context?) { true }

      describe '#method_name' do
        let(:source) do
          <<-END
            it 'responds to #foo' do
              subject.stub(:foo)
            end
          END
        end

        it 'returns the method name' do
          method_stub_object.method_name.should == :stub
        end
      end

      describe '#allowize!' do
        [:stub, :stub!].each do |method|
          context "when it is `subject.#{method}(:method)` form" do
            let(:source) do
              <<-END
                it 'responds to #foo' do
                  subject.#{method}(:foo)
                end
              END
            end

            let(:expected_source) do
              <<-END
                it 'responds to #foo' do
                  allow(subject).to receive(:foo)
                end
              END
            end

            it 'converts into `allow(subject).to receive(:method)` form' do
              method_stub_object.allowize!
              rewritten_source.should == expected_source
            end
          end

          context "when it is `subject.#{method}(:method).and_return(value)` form" do
            let(:source) do
              <<-END
                it 'responds to #foo' do
                  subject.#{method}(:foo).and_return(value)
                end
              END
            end

            let(:expected_source) do
              <<-END
                it 'responds to #foo' do
                  allow(subject).to receive(:foo).and_return(value)
                end
              END
            end

            it 'converts into `allow(subject).to receive(:method).and_return(value)` form' do
              method_stub_object.allowize!
              rewritten_source.should == expected_source
            end
          end

          context "when it is `subject.#{method}(:method).and_raise(RuntimeError)` form" do
            let(:source) do
              <<-END
                it 'responds to #foo' do
                  subject.#{method}(:foo).and_raise(RuntimeError)
                end
              END
            end

            let(:expected_source) do
              <<-END
                it 'responds to #foo' do
                  allow(subject).to receive(:foo).and_raise(RuntimeError)
                end
              END
            end

            it 'converts into `allow(subject).to receive(:method).and_raise(RuntimeError)` form' do
              method_stub_object.allowize!
              rewritten_source.should == expected_source
            end
          end

          context "when it's statement continues over multi lines" do
            let(:source) do
              <<-END
                it 'responds to #foo' do
                  subject.#{method}(
                      :baz
                    ).
                    and_return(
                      3
                    )
                end
              END
            end

            let(:expected_source) do
              <<-END
                it 'responds to #foo' do
                  allow(subject).to receive(
                      :baz
                    ).
                    and_return(
                      3
                    )
                end
              END
            end

            it 'keeps the style as far as possible' do
              method_stub_object.allowize!
              rewritten_source.should == expected_source
            end
          end

          context "when it is `subject.#{method}(:method => value)` form" do
            let(:source) do
              <<-END
                it 'responds to #foo and returns 1' do
                  subject.#{method}(:foo => 1)
                end
              END
            end

            let(:expected_source) do
              <<-END
                it 'responds to #foo and returns 1' do
                  allow(subject).to receive(:foo).and_return(1)
                end
              END
            end

            it 'converts into `allow(subject).to receive(:method).and_return(value)` form' do
              method_stub_object.allowize!
              rewritten_source.should == expected_source
            end
          end

          context "when it is `subject.#{method}(method: value)` form" do
            let(:source) do
              <<-END
                it 'responds to #foo and returns 1' do
                  subject.#{method}(foo: 1)
                end
              END
            end

            let(:expected_source) do
              <<-END
                it 'responds to #foo and returns 1' do
                  allow(subject).to receive(:foo).and_return(1)
                end
              END
            end

            it 'converts into `allow(subject).to receive(:method).and_return(value)` form' do
              method_stub_object.allowize!
              rewritten_source.should == expected_source
            end
          end

          context "when it is `subject.#{method}(:a_method => a_value, b_method => b_value)` form" do
            let(:source) do
              <<-END
                it 'responds to #foo and returns 1' do
                  subject.#{method}(:foo => 1, :bar => 2)
                end
              END
            end

            let(:expected_source) do
              <<-END
                it 'responds to #foo and returns 1' do
                  allow(subject).to receive(:foo).and_return(1)
                  allow(subject).to receive(:bar).and_return(2)
                end
              END
            end

            it 'converts into `allow(subject).to receive(:a_method).and_return(a_value)` ' +
               'and `allow(subject).to receive(:b_method).and_return(b_value)` form' do
              method_stub_object.allowize!
              rewritten_source.should == expected_source
            end

            context "when it's statement continues over multi lines" do
              let(:source) do
                <<-END
                  it 'responds to #foo' do
                    subject
                      .#{method}(
                        :foo => 1,
                        :bar => 2
                      )
                  end
                END
              end

              let(:expected_source) do
                <<-END
                  it 'responds to #foo' do
                    allow(subject)
                      .to receive(:foo).and_return(1)
                    allow(subject)
                      .to receive(:bar).and_return(2)
                  end
                END
              end

              it 'keeps the style except around the hash' do
                method_stub_object.allowize!
                rewritten_source.should == expected_source
              end
            end
          end
        end

        [:unstub, :unstub!].each do |method|
          context "when it is `subject.#{method}(:method)` form" do
            let(:source) do
              <<-END
                it 'does not respond to #foo' do
                  subject.#{method}(:foo)
                end
              END
            end

            it 'does nothing' do
              method_stub_object.allowize!
              rewritten_source.should == source
            end
          end
        end

        [:stub, :stub!].each do |method|
          context "when it is `SomeClass.any_instance.#{method}(:method)` form" do
            let(:source) do
              <<-END
                it 'responds to #foo' do
                  SomeClass.any_instance.#{method}(:foo)
                end
              END
            end

            let(:expected_source) do
              <<-END
                it 'responds to #foo' do
                  allow_any_instance_of(SomeClass).to receive(:foo)
                end
              END
            end

            it 'converts into `allow_any_instance_of(SomeClass).to receive(:method)` form' do
              method_stub_object.allowize!
              rewritten_source.should == expected_source
            end
          end
        end

        [:unstub, :unstub!].each do |method|
          context "when it is `SomeClass.any_instance.#{method}(:method)` form" do
            let(:source) do
              <<-END
                it 'does not respond to #foo' do
                  SomeClass.any_instance.#{method}(:foo)
                end
              END
            end

            it 'does nothing' do
              method_stub_object.allowize!
              rewritten_source.should == source
            end
          end
        end

        context 'when already replaced deprecated method' do
          let(:source) do
            <<-END
              it 'responds to #foo' do
                subject.stub!(:foo)
              end
            END
          end

          it 'raises error' do
            method_stub_object.replace_deprecated_method!
            -> { method_stub_object.allowize! }.should raise_error
          end
        end
      end

      describe '#replace_deprecated_method!' do
        [
          [:stub!,   :stub,   'responds to'],
          [:unstub!, :unstub, 'does not respond to']
        ].each do |method, replacement_method, description|
          context "when it is ##{method}" do
            let(:source) do
              <<-END
                it '#{description} #foo' do
                  subject.#{method}(:foo)
                end
              END
            end

            let(:expected_source) do
              <<-END
                it '#{description} #foo' do
                  subject.#{replacement_method}(:foo)
                end
              END
            end

            it "replaces with ##{replacement_method}" do
              method_stub_object.replace_deprecated_method!
              rewritten_source.should == expected_source
            end
          end
        end

        [
          [:stub,   'responds to'],
          [:unstub, 'does not respond to']
        ].each do |method, description|
          context "when it is ##{method}" do
            let(:source) do
              <<-END
                it '#{description} #foo' do
                  subject.#{method}(:foo)
                end
              END
            end

            it 'does nothing' do
              method_stub_object.replace_deprecated_method!
              rewritten_source.should == source
            end
          end
        end

        context 'when already allowized' do
          let(:source) do
            <<-END
              it 'responds to #foo' do
                subject.stub!(:foo)
              end
            END
          end

          it 'raises error' do
            method_stub_object.allowize!
            -> { method_stub_object.replace_deprecated_method! }.should raise_error
          end
        end
      end
    end
  end
end
