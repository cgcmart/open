Spree.routes.checkouts_api = Spree.pathFor('api/checkouts')
Spree.routes.classifications_api = Spree.pathFor('api/classifications')
Spree.routes.option_type_search = Spree.pathFor('api/option_types')
Spree.routes.option_value_search = Spree.pathFor('api/option_values')
Spree.routes.orders_api = Spree.pathFor('api/orders')
Spree.routes.product_api = Spree.pathFor('api/products')
Spree.routes.shipments_api = Spree.pathFor('api/shipments')
Spree.routes.stock_locations_api = Spree.pathFor('api/stock_locations')
Spree.routes.tags_api = Spree.pathFor('api/tags')
Spree.routes.taxon_products_api = Spree.pathFor('api/taxons/products')
Spree.routes.taxons_api = Spree.pathFor('api/taxons')
Spree.routes.users_api = Spree.pathFor('api/users')
Spree.routes.variants_api = Spree.pathFor('api/variants')

Spree.routes.edit_product = function (productId) {
  return Spree.adminPathFor('products/' + productId + '/edit')
}

Spree.routes.line_items_api = function(orderId) {
  return Spree.pathFor('api/orders/' + orderId + '/line_items');
}

Spree.routes.payments_api = function(orderId) {
  return Spree.pathFor('api/orders/' + orderId + '/payments');
}

Spree.routes.stock_items_api = function(stockLocation_id) {
  return Spree.pathFor('api/stock_locations/' + stockLocationId + '/stock_items');
}
