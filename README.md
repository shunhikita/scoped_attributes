# ScopedAttributes

Support to attributes visible for each roles.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'scoped_attributes'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install scoped_attributes

## Usage

create scoped class.

```rb
class ApplicationScopedModel
  include ScopedAttributes
  roles :admin # Multiple arguments can be specified (ex. admin, manager, ...)

  def admin?
    user.admin?
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

current_user is crew and crew is not me

```rb
scoped_crew = ScopedCrew.new(Crew.find(1), current_user)
scoped_crew.name
# => "hoge"

scoped_crew.address
# => nil

scoped_crew.attributes
# => {:id=>1, :name=>"hoge"}

scoped_crew.to_model
=> #<Crew:xxx id: 1, name: "hoge">

Crew.find(1).scoped
=> #<Crew:xxx id: 1, name: "hoge">
```

current_user is crew and crew is me
```rb
scoped_crew = ScopedCrew.new(Crew.find(1), current_user)
scoped_crew.name
# => "hoge"

scoped_crew.address
# => "tokyo"

scoped_crew.attributes
# => {:id=>1, :name=>"hoge", :address=>"tokyo"}

scoped_crew.to_model
=> #<Crew:xxx id: 1, name: "hoge", address: "tokyo">

Crew.find(1).scoped
=> #<Crew:xxx id: 1, name: "hoge", address: "tokyo">
```

current_user is admin

```rb
scoped_crew = ScopedCrew.new(Crew.find(1), current_user)
scoped_crew.name
# => "hoge"

scoped_crew.address
# =>  "tokyo"

scoped_crew.attributes
# => {:id=>1, :name=>"hoge", :address=>"tokyo", :evaluation=>"SS"}

scoped_crew.to_model
=> #<Crew:xxx id: 1, name: "hoge", address: "tokyo", evaluation: "SS">

Crew.find(1).scoped
=> #<Crew:xxx id: 1, name: "hoge", address: "tokyo", evaluation: "SS">
```

## When using with PORO 

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
