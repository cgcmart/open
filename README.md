
<img src="./open_logo_300.png" width="300">

**Open** is the newest approach to the e-commerce solution built with Ruby on Rails. It is a fork of [Spree](https://spreecommerce.org).

Open consists of several gems. When you require the `open` gem in your
`Gemfile`, Bundler will install all of the gems maintained in this repository:

* open_api (RESTful API)
* open_frontend (Customer frontend)
* open_backend (Admin panel)
* open_core (Essential models, mailers, and classes)
* open_sample (Sample data)

Getting Started
----------------------

Set up your local environment:

1. Install Ruby version 2.5.0 or newer.

2. Install the Rails 5 gem.

3. Install the Bundler gem.

Create a new app to your open store. Run the rails new command to create a new Rails app:

```shell
rails new open
```

Go to the directory that contains the generated Rails app:

```shell
cd open
```

Use a text editor to add Open gems to your Gemfile:

```shell
nano Gemfile
```

and add:

```ruby
gem 'open', github: '99cm/open'
gem 'open_auth_devise', github: '99cm/open_auth_devise'
gem 'open_gateway', github: '99cm/open_gateway'
```

To run the new Rails app on your local computer, install dependencies by using Bundler:

```shell
bundle install
```

Start a local web server:

```shell
bundle exec bin/rails server
```

By default, the installation generator (`rails g spree:install`) will run
migrations as well as adding seed and sample data. This can be disabled using

```bash
rails g spree:install --migrate=false --sample=false --seed=false
```

You can always perform any of these steps later by using these commands.

```bash
bundle exec rake railties:install:migrations
bundle exec rake db:migrate
bundle exec rake db:seed
bundle exec rake spree_sample:load
```

In case of missing migrations
--------------------------------

```bash
rails open_api:install:migrations
rails open_auth:install:migrations
rails open_gateway:install:migrations
```

Browse Store
----------------------

http://localhost:3000

Browse Admin Interface
----------------------

http://localhost:3000/admin

Extensions
----------------------

Open Extensions provide additional features not present in the Core system.


| Extension | Description |
| --- | --- |
| [open_gateway](https://github.com/99cm/open_gateway) | Open Store payment system builds with Open supported payment method gateways.
| [open_auth_devise](https://github.com/99cm/open_auth_devise) | Provides authentication services for Open, using the Devise gem.
| [open_active_shipping](https://github.com/99cm/open_active_shipping) | Provides active shipping to get shipping rates and tracking from various carriers.

### Sandbox

Create a sandbox Rails application for testing purposes which automatically perform all necessary database setup

```shell
bundle exec rake sandbox
```

Start the server

```shell
cd sandbox
rails server
```