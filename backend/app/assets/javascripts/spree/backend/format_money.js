//= require spree/backend/translation
//= require solidus_admin/accounting

Spree.formatMoney = function(amount, currency) {
  var currencyInfo = Spree.currencyInfo[currency];

  var thousand = I18n.t('spree.currency_delimiter');
  var decimal = I18n.t('spree.currency_separator');

  return accounting.formatMoney(amount, currencyInfo[0], currencyInfo[1], thousand, decimal, currencyInfo[2]);
}
