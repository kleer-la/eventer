# frozen_string_literal: true

require 'rails_helper'

# The admin filters, applied. ransack 6 refuses to search through an
# association, or by an attribute, that the model does not allowlist (#241):
# the screens still render (screens_render_spec.rb), so this checks that a
# filter narrows the list to the record it names. The filters that go through
# an association are the ones most exposed, plus text searches on the screens
# the upgrade touched.
RSpec.describe 'Admin filters', type: :feature do
  before { login_as(create(:administrator), scope: :user) }

  def listed?(path) = page.has_css?("a[href='#{path}']", wait: false)

  it 'lists the participants of one event' do
    wanted, other = create_list(:participant, 2)

    visit admin_participants_path(q: { event_id_eq: wanted.event_id })

    expect(listed?(admin_participant_path(wanted))).to be(true)
    expect(listed?(admin_participant_path(other))).to be(false)
  end

  it 'lists the events of one country, trainer and course' do
    wanted = create(:event, country: create(:country, iso_code: 'AR'), trainer: create(:trainer, name: 'Ana'))
    other = create(:event, country: create(:country, iso_code: 'CL'), trainer: create(:trainer, name: 'Beto'))

    { country_id_eq: wanted.country_id, trainer_id_eq: wanted.trainer_id,
      event_type_id_eq: wanted.event_type_id }.each do |condition, value|
      visit admin_events_path(q: { condition => value })

      expect(listed?(admin_event_path(wanted))).to be(true), "#{condition} left out the event"
      expect(listed?(admin_event_path(other))).to be(false), "#{condition} kept the other event"
    end
  end

  it 'lists the resources of one category' do
    wanted = create(:resource, category: create(:category))
    other = create(:resource)

    visit admin_resources_path(q: { category_id_eq: wanted.category_id })

    expect(listed?(admin_resource_path(wanted))).to be(true)
    expect(listed?(admin_resource_path(other))).to be(false)
  end

  it 'searches text on the screens the upgrade touched' do
    coupons = [create(:coupon, code: 'VERANO'), create(:coupon, code: 'INVIERNO')]
    news = [create(:news, title: 'Kleer en Agiles'), create(:news, title: 'Otra cosa')]
    templates = [create(:mail_template, subject: 'Tu guía'), create(:mail_template, subject: 'Hola')]

    [[:admin_coupons_path, :admin_coupon_path, { code_cont: 'VERA' }, coupons],
     [:admin_news_index_path, :admin_news_path, { title_cont: 'Agiles' }, news],
     [:admin_mail_templates_path, :admin_mail_template_path, { subject_cont: 'guía' }, templates]]
      .each do |index, show, condition, (wanted, other)|
      visit public_send(index, q: condition)

      expect(listed?(public_send(show, wanted))).to be(true), "#{index} #{condition} left out the match"
      expect(listed?(public_send(show, other))).to be(false), "#{index} #{condition} kept the other one"
    end
  end

  # ransack 5+ escapes LIKE wildcards: '%' is searched as a character, so it
  # no longer matches everything.
  it 'searches a % literally' do
    with_percent = create(:news, title: '100% remoto')
    without = create(:news, title: 'Presencial')

    visit admin_news_index_path(q: { title_cont: '%' })

    expect(listed?(admin_news_path(with_percent))).to be(true)
    expect(listed?(admin_news_path(without))).to be(false)
  end
end
