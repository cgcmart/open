# frozen_string_literal: true

north_america = Spree::Zone.where(name: 'North America', description: 'USA + Canada', kind: 'country').first_or_create!

%w(US CA).each do |name|
  north_america.zone_members.where(zoneable: Spree::Country.find_by!(iso: name)).first_or_create!
end
