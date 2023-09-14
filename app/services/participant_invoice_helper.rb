
class ParticipantInvoiceHelper
  def initialize(participant, lang)
    @participant = participant
    @lang =  lang
  end

  #TODO: test & change languaje
  def item_description
    participant = @participant
    event_name = participant.event.event_type.name
    country = participant.event.country.name.tr('-', '')
    human_date = participant.event.human_date

    if participant.quantity == 1
      I18n.t('mail.invoice.item_one', locale: @lang,
        course: event_name, place: country, date: human_date, student_name: "#{participant.fname} #{participant.lname}"
      )
    else
      I18n.t('mail.invoice.item_more', locale: @lang,
        course: event_name, place: country, date: human_date, qty: participant.quantity
      )
    end
  end

  def update_participant(invoice)
    return if invoice.nil?
    participant = @participant

    participant.xero_invoice_number = invoice.invoice_number
    participant.invoice_id = invoice.invoice_id
    participant.save!
  end

end