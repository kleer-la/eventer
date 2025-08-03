# frozen_string_literal: true

class ParticipantInvoiceHelper
  def initialize(participant, lang = nil)
    @participant = participant
    @lang = lang
  end

  # TODO: test & change languaje
  def item_description
    participant = @participant
    event_name = participant.event.event_type.name
    country = participant.event.country.name.tr('-', '')
    human_date = participant.event.human_date
    coupon = participant.applied_coupon

    base_description = if participant.quantity == 1
                         I18n.t('mail.invoice.item_one', locale: @lang,
                                                         course: event_name, place: country, date: human_date, student_name: "#{participant.fname} #{participant.lname}")
                       else
                         I18n.t('mail.invoice.item_more', locale: @lang,
                                                          course: event_name, place: country, date: human_date, qty: participant.quantity)
                       end

    if coupon.present?
      coupon_description = I18n.t('mail.invoice.coupon_applied', locale: @lang, coupon_code: coupon.code)
      "#{base_description} - #{coupon_description}"
    else
      base_description
    end
  end

  def update_participant(invoice)
    return if invoice.nil?

    participant = @participant

    participant.xero_invoice_number = invoice.invoice_number
    participant.invoice_id = invoice.invoice_id
    participant.save!
  end

  def new_invoice
    unit_price = @participant.applicable_unit_price
    return nil if unit_price < 0.01 || @participant.event.is_sold_out

    invoice = nil
    begin
      invoice_service = InvoiceService.new(@participant)
      invoice = invoice_service.create_send_invoice
      online_invoice_url = invoice_service&.get_online_invoice_url
      if online_invoice_url
        @participant.online_invoice_url = online_invoice_url
        @participant.save
      end
    rescue StandardError => e
      Log.log(:xero, :error,
              "create_send_invoice:#{@participant.company_name} #{@participant.fname} #{@participant.lname}",
              "#{e.message} - #{e.backtrace.grep_v(%r{/gems/}).join('\n')}")
    end
    invoice
  end
end
