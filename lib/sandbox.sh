#!/bin/sh
# Used in the sandbox rake task in Rakefile

set -e

case "$DB" in
postgres)
  RAILSDB="postgresql"
  ;;
mysql)
  RAILSDB="mysql"
  ;;
sqlite|'')
  RAILSDB="sqlite3"
  ;;
*)
  echo "Invalid DB specified: $DB"
  exit 1
  ;;
esac

rm -rf ./sandbox
bundle exec rails new sandbox --database="$RAILSDB" \
  --skip-bundle \
  --skip-git \
  --skip-keeps \
  --skip-rc \
  --skip-spring \
  --skip-test \
  --skip-yarn \

if [ ! -d "sandbox" ]; then
  echo 'sandbox rails application failed'
  exit 1
fi

cd ./sandbox
cat <<RUBY >> Gemfile

gem 'open', path: '..'
gem 'open_auth_devise', '>= 2.5.0'
gem 'rails-i18n'
gem 'open_i18n'

group :test, :development do
  platforms :mri do
    gem 'pry-byebug'
  gem 'awesome_print'
  end
end
RUBY

bundle install --gemfile Gemfile
bundle exec rails db:drop || true
bundle exec rails db:create
bundle exec rails g spree:install --auto-accept --user_class=Spree::User --enforce_available_locales=true --copy_views=false
bundle exec rails g open:auth:install
bundle exec rails g open_gateway:install