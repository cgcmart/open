# frozen_string_literal: true

json.partial! 'spree/api/shared/pagination', pagination: @tags
json.tags(@tags) do |tag|
  json.(tag, *tag_attributes)
end
