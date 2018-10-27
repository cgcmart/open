#!/bin/sh

set -e

# Target postgres. Override with: `DB=sqlite bash build.sh`
export DB=${DB:-postgres}

# Open defaults
echo "Installing Open test dependencies"
bundle check || bundle update --quiet

# Open API
echo "**************************************"
echo "* Testing Open API *"
echo "**************************************"
cd api
bundle exec rspec spec

# Open Backend
echo "******************************************"
echo "* Testing Open Backend *"
echo "******************************************"
cd ../backend
bundle exec rspec spec
bundle exec teaspoon

# Open Core
echo "***************************************"
echo "* Testing Open Core *"
echo "***************************************"
cd ../core
bundle exec rspec spec

# Open Frontend
echo "*******************************************"
echo "* Testing Open Frontend *"
echo "*******************************************"
cd ../frontend
bundle exec rspec spec

# Open Sample
echo "*****************************************"
echo "* Testing Open Sample *"
echo "*****************************************"
cd ../sample
bundle exec rspec spec
