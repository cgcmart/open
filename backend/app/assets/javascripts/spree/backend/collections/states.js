Spree.Collections.States = Backbone.Collection.extend({
  initialize: function (models, options) {
    this.country_id = options.countryId
  },

  url: function () {
    return Spree.routes.states_search + "?countryId=" + this.country_id
  },

  parse: function(resp, options) {
    return resp.states
  }
})
