# frozen_string_literal: true

# Use this module to easily test Spree actions within Spree components
# or inside your application to test routes for the mounted Spree engine.
#
# Inside your spec_helper.rb, include this module inside the RSpec.configure
# block by doing this:
#
#   require 'spree/testing_support/controller_requests'
#   RSpec.configure do |c|
#     c.include Spree::TestingSupport::ControllerRequests, type: :controller
#   end
#
# Then, in your controller tests, you can access spree routes like this:
#
#   require 'spec_helper'
#
#   describe Spree::ProductsController do
#     it "can see all the products" do
#       spree_get :index
#     end
#   end
#
# Use spree_get, spree_post, spree_put or spree_delete to make requests
# to the Spree engine, and use regular get, post, put or delete to make
# requests to your application.
#
module Spree
  module TestingSupport
    module ControllerRequests
      extend ActiveSupport::Concern

      included do
        routes { Spree::Core::Engine.routes }
      end

      def get(action, parameters = nil, session = nil, flash = nil)
        process_spree_action(action, parameters, session, flash, 'GET')
      end

      # Executes a request simulating POST HTTP method and set/volley the response
      def post(action, parameters = nil, session = nil, flash = nil)
        process_spree_action(action, parameters, session, flash, 'POST')
      end

      # Executes a request simulating PUT HTTP method and set/volley the response
      def put(action, parameters = nil, session = nil, flash = nil)
        process_spree_action(action, parameters, session, flash, 'PUT')
      end

       # Executes a request simulating DELETE HTTP method and set/volley the response
      def delete(action, parameters = nil, session = nil, flash = nil)
        process_spree_action(action, parameters, session, flash, 'DELETE')
      end

      private

      def process_spree_action(action, parameters = nil, session = nil, flash = nil, method = 'GET')
        parameters ||= {}
        process(action, method, parameters, session, flash)
      end

      def process_spree_xhr_action(action, parameters = nil, session = nil, flash = nil, method = :get)
        parameters ||= {}
        parameters.reverse_merge!(format: :json)
        xml_http_request(method, action, parameters, session, flash)
      end
    end
  end
end
