Spree.routes.checkouts_api = Spree.pathFor('api/v1/checkouts');
Spree.routes.classifications_api = Spree.pathFor('api/v1/classifications');
Spree.routes.option_type_search = Spree.pathFor('api/v1/option_types');
Spree.routes.option_value_search = Spree.pathFor('api/v1/option_values');
Spree.routes.orders_api = Spree.pathFor('api/v1/orders');
Spree.routes.product_api = Spree.pathFor('api/vi/products');
Spree.routes.admin_product_search = Spree.pathFor('admin/search/products');
Spree.routes.shipments_api = Spree.pathFor('api/v1/shipments');
Spree.routes.stock_locations_api = Spree.pathFor('api/v1/stock_locations');
Spree.routes.tags_api = Spree.pathFor('api/v1/tags');
Spree.routes.taxon_products_api = Spree.pathFor('api/v1/taxons/products');
Spree.routes.taxons_search = Spree.pathFor('api/v1/taxons');
Spree.routes.user_search = Spree.pathFor('admin/search/users');
Spree.routes.variants_api = Spree.pathFor('api/v1/variants');
Spree.routes.users_api = Spree.pathFor('api/v1/users');

Spree.routes.line_items_api = function(order_id) {
  return Spree.pathFor('api/v1/orders/' + order_id + '/line_items');
};

Spree.routes.payments_api = function(order_id) {
  return Spree.pathFor('api/v1/orders/' + order_id + '/payments');
};

Spree.routes.stock_items_api = function(stock_location_id) {
  return Spree.pathFor('api/v1/stock_locations/' + stock_location_id + '/stock_items');
};
