# frozen_string_literal: true

module MarketingHelper
  def training(from_to)
    Participant.joins(event: :event_type)
               .select('events.id, name, date, visibility_type, capacity, list_price, currency_iso_code, status, count(*) as part')
               .where('events.date' => from_to)
               .group('events.id', :name, :date, :visibility_type, :capacity, :list_price, :currency_iso_code, :status)
  end
end
