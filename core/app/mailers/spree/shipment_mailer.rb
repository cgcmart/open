# frozen_string_literal: true

module Spree
  class ShipmentMailer < BaseMailer
    def shipped_email(shipment, resend = false)
      @shipment = shipment.respond_to?(:id) ? shipment : Spree::Shipment.find(shipment)
      @store = @order.store
      subject = (resend ? "[#{.t('spree.resend').upcase}] " : '')
      subject += "#{@store.name} #{t('spree.shipment_mailer.shipped_email.subject')} ##{@shipment.order.number}"
      mail(to: @shipment.order.email, from: from_address(@store), subject: subject)
    end
  end
end
