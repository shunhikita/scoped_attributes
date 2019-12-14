module ScopedAttributes
  module Scopable
    extend ActiveSupport::Concern

    def scoped(user)
      klass_name = "Scoped#{self.model_name}"
      klass_name.constantize.new(self, user).to_model
    end
  end
end