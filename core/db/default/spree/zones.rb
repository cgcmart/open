# frozen_string_literal: true

north_america = Spree::Zone.create!(name: "North America", description: "USA + Canada", kind: 'country')

%w(US CA).each do |name|
  north_america.zone_members.create!(zoneable: Spree::Country.find_by!(iso: name))
end
