require 'rails/railtie'

module ScopedAttributes
  class Railtie < Rails::Railtie
    initializer 'scoped_attributes.setup_orm' do
      [:active_record].each do |orm|
        ActiveSupport.on_load orm do
          self.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            include ScopedAttributes::Scopable
          RUBY
        end
      end
    end
  end
end
