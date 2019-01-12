# frozen_string_literal: true

north_america = Spree::Zone.find_or_create_by!(name: 'North America', description: 'USA + Canada', kind: 'country')

%w(US CA).each do |name|
  north_america.zone_members.find_or_create_by!(zoneable: Spree::Country.find_by!(iso: symbol))
end