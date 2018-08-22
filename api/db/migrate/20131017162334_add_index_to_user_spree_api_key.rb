# frozen_string_literal: true

class AddIndexToUserSpreeApiKey < ActiveRecord::Migration[5.2]
  def change
    unless defined?(User)
      add_index :spree_users, :spree_api_key
    end
  end
end
