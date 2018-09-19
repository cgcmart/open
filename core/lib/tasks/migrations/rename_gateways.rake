# frozen_string_literal: true

require 'spree/migrations/rename_gateways'

namespace 'spree:migrations:rename_gateways' do
  task up: :environment do
    count = Spre::Migrations::RenameGateways.new.up

    unless ENV['VERBOSE'] == 'false' || !verbose
      puts "Renamed #{count} gateways into payment methods."
    end
  end

  task down: :environment do
    count = Spree::Migrations::RenameGateways.new.down

    unless ENV['VERBOSE'] == 'false' || !verbose
      puts "Renamed #{count} payment methods into gateways."
    end
  end
end
