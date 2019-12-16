# ScopedAttributes
![](https://github.com/shunhikita/scoped_attributes/workflows/CI/badge.svg?branch=master)

scoped_attributes provides a module that allows you to add access restriction settings to attributes.
By using this, you can easily create a wrapper model that returns only the information required for each different role.
I think it can also be used to API Scope and view models.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'scoped_attributes'
```

## Usage

You can create a wrapper model by including the ScopedAttributes module.

```rb
class ApplicationScopedModel
  include ScopedAttributes
  roles :admin, :manager 

  def admin?
    user.admin?
  end

  def manager?
    user.manager?
  end
end
```

```rb
class ScopedCrew < ApplicationScopedModel
  attribute :id
  attribute :name
  attribute :address, only: proc { me? || admin? } # Proc
  attribute :evaluation, only: %i(admin) # role names (Array)

  def me?
    id == user.crew_id
  end
end
```

### When using with ActiveRecord object

Specify the target object in the first argument and the user with the role in the second argument.
The acquisition of the attribute  is controlled by the condition specified in attribute class macro.

For an ActiveRecord object, you can use the to_model method to get the model instance with the attribute selected.

```rb
# current_user is not admin and not me
scoped_crew = ScopedCrew.new(Crew.find(1), current_user)
scoped_crew.name
# => "hoge"

scoped_crew.address
# => nil

scoped_crew.attributes
# => {:id=>1, :name=>"hoge"}

scoped_crew.to_model
# => #<Crew:xxx id: 1, name: "hoge">

Crew.find(1).scoped(current_user)
# => #<Crew:xxx id: 1, name: "hoge">
```


```rb
# current_user is not admin but is me
scoped_crew = ScopedCrew.new(Crew.find(1), current_user)
scoped_crew.name
# => "hoge"

scoped_crew.address
# => "tokyo"

scoped_crew.attributes
# => {:id=>1, :name=>"hoge", :address=>"tokyo"}

scoped_crew.to_model
# => #<Crew:xxx id: 1, name: "hoge", address: "tokyo">

Crew.find(1).scoped(current_user)
# => #<Crew:xxx id: 1, name: "hoge", address: "tokyo">
```

```rb
# current_user is admin
scoped_crew = ScopedCrew.new(Crew.find(1), current_user)
scoped_crew.name
# => "hoge"

scoped_crew.address
# => "tokyo"

scoped_crew.attributes
# => {:id=>1, :name=>"hoge", :address=>"tokyo", :evaluation=>"SS"}

scoped_crew.to_model
# => #<Crew:xxx id: 1, name: "hoge", address: "tokyo", evaluation: "SS">

Crew.find(1).scoped(current_user)
# => #<Crew:xxx id: 1, name: "hoge", address: "tokyo", evaluation: "SS">
```

## When using with PORO 

ScopedAttributes module can also be used by including it in PORO(Plain Old Ruby Object).

```rb
class ScopedCrew < ApplicationScopedModel
  attribute :name
  attribute :addres
  attribute :evaluation, only: %i(admin)
end

class CustomCrew
  attr_accessor :name, :address, :evaluation
  
  def initialize(name, address, evaluation)
    self.name = name
    self.address = address
    self.evaluation = evaluation
  end
end

crew = CustomCrew.new("hoge", "tokyo", "SS")
scoped_crew = ScopedCrew.new(crew, current_user)
scoped_crew.attributes
# => {:name=>"hoge", :address=>"tokyo"}
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/shunhikita/scoped_attributes.
