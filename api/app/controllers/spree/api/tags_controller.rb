# frozen_string_literal: true

module Spree
  module Api
    class TagsController < Spree::Api::BaseController
      def index
        @tags =
          if params[:ids]
            Tag.where(id: params[:ids].split(',').flatten)
          else
            Tag.ransack(params[:q]).result
        end

        @tags = pagenate(@tags)
        respond_with(@tags)
      end

      private

      def default_per_page
        500
      end

      def tags_params
        params.require(:tag).permit(permitted_tags_attributes)
      end
    end
  end
end
