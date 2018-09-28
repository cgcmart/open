//= require jsuri
function Spree () {}

Spree.ready = function (callback) {
  jQuery(callback)
  return jQuery(document).on('page:load turbolinks:load', function () {
    return callback(jQuery)
  })
}

Spree.mountedAt = function () {
  return window.SpreePaths.mounted_at
}

Spree.adminPath = function () {
  return window.SpreePaths.admin
}

Spree.pathFor = function (path) {
  var locationOrigin = (window.location.protocol + '//' + window.location.hostname) + (window.location.port ? ':' + window.location.port : '')
  return this.url('' + locationOrigin + (this.mountedAt()) + path, this.url_params).toString()
}

Spree.adminPathFor = function (path) {
  return this.pathFor('' + (this.adminPath()) + path)
}

Spree.ajax = function (urlOrSettings, settings) {
  var url
  if (typeof urlOrSettings === 'string') {
    return $.ajax(Spree.url(urlOrSettings).toString(), settings)
  } else {
    url = urlOrSettings['url']
    delete urlOrSettings['url']
    return $.ajax(Spree.url(url).toString(), urlOrSettings)
  }
}

Spree.routes = {
  states_search: Spree.pathFor('api/v1/states'),
  apply_coupon_code: function (orderId) {
    return Spree.pathFor('api/v1/orders/' + orderId + '/apply_coupon_code')
  }
}

Spree.getJSON = function(url, data, success) {
  if (typeof data === 'function') {
    success = data;
    data = undefined;
  }
  return Spree.ajax({
    dataType: "json",
    url: url,
    data: data,
    success: success
  })
}
