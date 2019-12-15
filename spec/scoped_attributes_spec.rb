RSpec.describe ScopedAttributes do
  let(:included_klass) { Class.new { include ScopedAttributes } }
  let(:user) { double }

  describe "Version" do
    it "has a version number" do
      expect(ScopedAttributes::VERSION).not_to be nil
    end
  end

  describe "included" do
    it "attributes_registry is empty hash" do
      expect(included_klass.attributes_registry).to eq({})
    end
  end

  describe "class methods" do
    describe "self.roles" do
      context "when `roles :admin` defined" do
        before do
          included_klass.class_eval <<-RUBY
          roles :admin
          RUBY
        end

        it "defined #admin? instance method" do
          expect(included_klass.instance_methods).to include :admin?
        end
      end
    end

    describe "self.attribute" do
      context "when `attribute :name` defined" do
        before do
          included_klass.class_eval <<-RUBY
          attribute :name
          RUBY
        end

        it "defined #name instance method" do
          expect(included_klass.instance_methods).to include :name
        end

        it "#name return object#name" do
          Obj = Struct.new(:name)
          expect(included_klass.new(Obj.new("name"), user).name).to eq "name"
        end
      end

      context "when `attribute :name, only: %i(admin)` defined and admin? return false" do
        before do
          included_klass.class_eval <<-RUBY
          roles :admin

          attribute :name, only: %i(admin)

          def admin?
            false
          end
          RUBY
        end

        it "#name return nil" do
          Obj = Struct.new(:name)
          expect(included_klass.new(Obj.new("name"), user).name).to eq nil
        end
      end

      context "when `attribute :name, only: proc { false }` defined" do
        before do
          included_klass.class_eval <<-RUBY
          attribute :name, only: proc { false }
          RUBY
        end

        it "#name return nil" do
          Obj = Struct.new(:name)
          expect(included_klass.new(Obj.new("name"), user).name).to eq nil
        end
      end

      context "when `attribute :name, only: proc { true }` defined" do
        before do
          included_klass.class_eval <<-RUBY
          attribute :name, only: proc { true }
          RUBY
        end

        it "#name return object#name" do
          Obj = Struct.new(:name)
          expect(included_klass.new(Obj.new("name"), user).name).to eq "name"
        end
      end

      context "when `attribute :name, only: :me?` defined and me? return false" do
        before do
          included_klass.class_eval <<-RUBY
          attribute :name, only: :me?
          
          def me?
            false
          end
          RUBY
        end

        it "#name return nil" do
          Obj = Struct.new(:name)
          expect(included_klass.new(Obj.new("name"), user).name).to eq nil
        end
      end
    end
  end

  xdescribe "instance methods" do
    describe "#attributes" do
    end

    describe "#to_model" do
    end
  end
end
