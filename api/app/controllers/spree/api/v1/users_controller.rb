module Spree
  module Api
    module V1
      class UsersController < Spree::Api::BaseController
        private

        attr_reader :user

        def model_class
          Spree.user_class
        end

        def user_params
          permitted_resource_params
        end

        def permitted_resource_attributes
          if action_name == "create" || can?(:update_email, user)
            super | [:email]
          else
            super
          end
        end
      end
    end
  end
end
