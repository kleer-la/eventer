module DashboardHelper

  def currency_symbol_for( iso_code )
    currency = Money::Currency.table[iso_code.downcase.to_sym] unless iso_code.nil?
    if currency.nil?
      ""
    else
      currency[:symbol]
    end
  end

  def short_date(d)
    d.nil? ? '' : d.to_formatted_s(:short)
  end

end
