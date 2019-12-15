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

  describe "instance methods" do
    let(:instance) { included_klass.new(object, user) }

    describe "#attributes" do
      let(:object) { Struct.new(:name, :address).new("name", "address") }
      let(:user) { double }

      before do
        included_klass.class_eval <<-RUBY
          attribute :name
          attribute :address, only: -> { false }
        RUBY
      end

      context "when include_key argument is true" do
        subject { instance.attributes }

        it "return hash" do
          is_expected.to be_a Hash
        end

        it "visible attribute is included" do
          is_expected.to include(name: "name")
        end

        it "unvisible attribute is not included" do
          is_expected.not_to include(address: "address")
        end
      end

      context "when include_key argument is true" do
        subject { instance.attributes(include_key: true) }

        it "unvisible attribute is included and value is nil" do
          is_expected.to include(address: nil)
        end
      end
    end

    describe "#to_model" do
      let(:object) { Struct.new(:name, :address).new("name", "address") }
      let(:user) { double }
      subject { instance.to_model }

      before do
        included_klass.class_eval <<-RUBY
          attribute :name
          attribute :address, only: -> { false }
        RUBY
      end

      context "when #model is nil" do
        before do
          allow(instance).to receive(:model).and_return(nil)
        end

        it "return nil" do
          is_expected.to be nil
        end
      end

      context "when #model is not nil" do
        before do
          allow(instance).to receive(:model).and_return(mock_model)
        end

        context "when object#id is nil" do
          let(:mock_model) do
            Class.new do
              attr_accessor :name, :address
              def initialize(name: nil, address: nil)
                self.name = name
                self.address = address
              end
            end
          end

          it "return mock_model instance" do
            is_expected.to be_a mock_model
          end
        end

        xcontext "when object#id is not nil" do
        end
      end
    end
  end
end
