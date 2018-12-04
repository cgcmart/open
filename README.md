
<img src="./open_logo.svg" width="300">

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

Browse Store
----------------------

http://localhost:3000

Browse Admin Interface
----------------------

http://localhost:3000/admin

Extensions
----------------------

Spree Extensions provide additional features not present in the Core system.


| Extension | Spree 3.1+ support | Description |
| --- | --- | --- |
| [spree_gateway](https://github.com/spree/spree_gateway) | [![Build Status](https://travis-ci.org/spree/spree_gateway.svg?branch=master)](https://travis-ci.org/spree/spree_gateway) | Community supported Spree Payment Method Gateways
| [spree_auth_devise](https://github.com/spree/spree_auth_devise) | [![Build Status](https://travis-ci.org/spree/spree_auth_devise.svg?branch=master)](https://travis-ci.org/spree/spree_auth_devise) | Provides authentication services for Spree, using the Devise gem.
| [spree_i18n](https://github.com/spree-contrib/spree_i18n) | [![Build Status](https://travis-ci.org/spree-contrib/spree_i18n.svg?branch=master)](https://travis-ci.org/spree-contrib/spree_i18n) | I18n translation files for Spree Commerce
| [spree-multi-domain](https://github.com/spree-contrib/spree-multi-domain) | [![Build Status](https://travis-ci.org/spree-contrib/spree-multi-domain.svg?branch=master)](https://travis-ci.org/spree-contrib/spree-multi-domain) | Multiple Spree stores on different domains - single unified backed for processing orders
| [spree_multi_currency](https://github.com/spree-contrib/spree_multi_currency) | [![Build Status](https://travis-ci.org/spree-contrib/spree_multi_currency.svg?branch=master)](https://travis-ci.org/spree-contrib/spree_multi_currency) | Provides UI to allow configuring multiple currencies in Spree |
| [spree_braintree_vzero](https://github.com/spree-contrib/spree_braintree_vzero) | [![Build Status](https://travis-ci.org/spree-contrib/spree_braintree_vzero.svg?branch=master)](https://travis-ci.org/spree-contrib/spree_braintree_vzero) | Official Spree Braintree v.zero + PayPal extension |
| [spree_address_book](https://github.com/spree-contrib/spree_address_book) | [![Build Status](https://travis-ci.org/spree-contrib/spree_address_book.svg?branch=master)](https://travis-ci.org/spree-contrib/spree_address_book) | Adds address book for users to Spree |
| [spree_digital](https://github.com/spree-contrib/spree_digital) | [![Build Status](https://travis-ci.org/spree-contrib/spree_digital.svg?branch=master)](https://travis-ci.org/spree-contrib/spree_digital) | A Spree extension to enable downloadable products |
| [spree_social](https://github.com/spree-contrib/spree_social) |[![Build Status](https://travis-ci.org/spree-contrib/spree_social.svg?branch=master)](https://travis-ci.org/spree-contrib/spree_social)  | Building block for spree social networking features (provides authentication and account linkage) |
| [spree_related_products](https://github.com/spree-contrib/spree_related_products) | [![Build Status](https://travis-ci.org/spree-contrib/spree_related_products.svg?branch=master)](https://travis-ci.org/spree-contrib/spree_related_products) | Related products extension for Spree
| [spree_active_shipping](https://github.com/spree-contrib/spree_active_shipping) | [![Build Status](https://travis-ci.org/spree-contrib/spree_active_shipping.svg?branch=master)](https://travis-ci.org/spree-contrib/spree_active_shipping) | Spree integration for Shopify's active_shipping gem
| [spree_static_content](https://github.com/spree-contrib/spree_static_content) | [![Build Status](https://travis-ci.org/spree-contrib/spree_static_content.svg?branch=master)](https://travis-ci.org/spree-contrib/spree_static_content) | Manage static pages for Spree |
| [spree-product-assembly](https://github.com/spree-contrib/spree-product-assembly) | [![Build Status](https://travis-ci.org/spree-contrib/spree-product-assembly.svg?branch=master)](https://travis-ci.org/spree-contrib/spree-product-assembly) | Adds oportunity to make bundle of products |
| [spree_editor](https://github.com/spree-contrib/spree_editor) | [![Build Status](https://travis-ci.org/spree-contrib/spree_editor.svg?branch=master)](https://travis-ci.org/spree-contrib/spree_editor) | Rich text editor for Spree with Image and File uploading in-place |
| [spree_recently_viewed](https://github.com/spree-contrib/spree_recently_viewed) | [![Build Status](https://travis-ci.org/spree-contrib/spree_recently_viewed.svg?branch=master)](https://travis-ci.org/spree-contrib/spree_recently_viewed) | Recently viewed products in Spree |
| [spree_wishlist](https://github.com/spree-contrib/spree_wishlist) | [![Build Status](https://travis-ci.org/spree-contrib/spree_wishlist.svg?branch=master)](https://travis-ci.org/spree-contrib/spree_wishlist) | Wishlist extension for Spree |
| [spree_sitemap](https://github.com/spree-contrib/spree_sitemap) | [![Build Status](https://travis-ci.org/spree-contrib/spree_sitemap.svg?branch=master)](https://travis-ci.org/spree-contrib/spree_sitemap) | Sitemap Generator for Spree  |
| [spree_volume_pricing](https://github.com/spree-contrib/spree_volume_pricing) | [![Build Status](https://travis-ci.org/spree-contrib/spree_volume_pricing.svg?branch=master)](https://travis-ci.org/spree-contrib/spree_volume_pricing) | It determines the price for a particular product variant with predefined ranges of quantities
| [better_spree_paypal_express](https://github.com/spree-contrib/better_spree_paypal_express) | [![Build Status](https://travis-ci.org/spree-contrib/better_spree_paypal_express.svg?branch=master)](https://travis-ci.org/spree-contrib/better_spree_paypal_express) | This is the official Paypal Express extension for Spree.
| [spree_globalize](https://github.com/spree-contrib/spree_globalize) | [![Build Status](https://travis-ci.org/spree-contrib/spree_globalize.svg?branch=master)](https://travis-ci.org/spree-contrib/spree_globalize) | Adds support for model translations (multi-language stores)
| [spree_avatax_certified](https://github.com/spree-contrib/spree_avatax_certified) | [![Build Status](https://travis-ci.org/spree-contrib/spree_avatax_certified.svg?branch=master)](https://travis-ci.org/spree-contrib/spree_avatax_certified) | Improve your Spree store's sales tax decision automation with Avalara AvaTax
| [spree_analytics_trackers](https://github.com/spree-contrib/spree_analytics_trackers) | [![Build Status](https://travis-ci.org/spree-contrib/spree_analytics_trackers.svg?branch=master)](https://travis-ci.org/spree-contrib/spree_analytics_trackers) | Adds support for Analytics Trackers (Google Analytics & Segment)

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
