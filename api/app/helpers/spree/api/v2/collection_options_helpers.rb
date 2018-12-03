# frozen_string_literal: true

module Spree
  module Api
    module V2
      module CollectionOptionsHelpers
        def collection_links(collection)
          {
            self: request.original_url,
            next: pagination_url(collection.next_page || collection.total_pages),
            prev: pagination_url(collection.prev_page || 1),
            last: pagination_url(collection.total_pages),
            first: pagination_url(1)
          }
        end

        def collection_meta(collection)
          {
            count: collection.size,
            total_count: collection.total_count,
            total_pages: collection.total_pages
          }
        end
      end
    end
  end
end
