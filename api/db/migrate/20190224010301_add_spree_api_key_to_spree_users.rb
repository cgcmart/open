# frozen_string_literal: true

class AddApiKeyToSpreeUsers < ActiveRecord::Migration[5.2]
  def change
    unless defined?(User)
      add_column :spree_users, :spree_api_key, :string, limit: 48
	  add_index :spree_users, :spree_api_key
    end
  end
end