# frozen_string_literal: true

require 'rails_helper'

describe EventType do
  before(:each) do
    @event_type = FactoryBot.create(:event_type)
  end

  it 'HABTM trainers' do
    expect(@event_type.trainers[0].name).to eq 'Juan Alberto'
  end
  it 'can belong to no categories' do
    expect(@event_type.categories).to eq []
  end
  it 'can belong to many categories' do
    event_type = EventType.create(name: 'Concert')
    category1 = Category.create(name: 'Music')
    category2 = Category.create(name: 'Live Events')

    event_type.categories << category1
    event_type.categories << category2

    expect(event_type.categories).to include(category1, category2)
  end

  it 'should be valid' do
    expect(@event_type.valid?).to be true
  end

  it 'should require its name' do
    @event_type.name = ''

    expect(@event_type.valid?).to be false
  end

  it 'should require its description' do
    @event_type.description = ''

    expect(@event_type.valid?).to be false
  end

  it 'should require an elevator pitch' do
    @event_type.elevator_pitch = ''

    expect(@event_type.valid?).to be false
  end

  it 'elevator pitch invalid if +160 chars' do
    @event_type.elevator_pitch = 'x' * 161

    expect(@event_type.valid?).to be false
  end

  it 'should require its recipients' do
    @event_type.recipients = ''

    expect(@event_type.valid?).to be false
  end

  it 'should require its program' do
    @event_type.program = ''

    expect(@event_type.valid?).to be false
  end

  it 'should require its duration' do
    @event_type.duration = ''

    expect(@event_type.valid?).to be true
  end

  it 'should have a shot_name version returning 30 characters if name is longer' do
    @event_type.name = 'qoweiuq owei owqieu qoiweuqo iweu qwoeu qouwie qowieuq woiequ woei uqowie'
    expect(@event_type.short_name).to eq 'qoweiuq owei owqieu qoiweuqo i...'
  end

  it 'should have a shot_name version returning all characters if name is shorter than 30 letters' do
    @event_type.name = 'hola che!'
    expect(@event_type.short_name).to eq 'hola che!'
  end

  it 'should have a crm tag' do
    @event_type.tag_name = 'TR-CP (Carlos Peix)'
    expect(@event_type.valid?).to be true
  end

  it 'could not have a cover' do
    @event_type.cover = nil
    expect(@event_type.valid?).to be true
  end
  it 'could have a cover' do
    @event_type.cover = 'rambandanga'
    expect(@event_type.valid?).to be true
  end

  context 'Testimonies' do
    it 'no event no testimony' do
      expect(@event_type.testimonies.count).to eq 0
    end
    it 'no participant no testimony' do
      FactoryBot.create(:event, event_type: @event_type)
      expect(@event_type.testimonies.count).to eq 0
    end
    it 'no participant no testimony' do
      FactoryBot.create(:event, event_type: @event_type)
      expect(@event_type.testimonies.count).to eq 0
    end
    it 'participant wo/ testimony' do
      ev = FactoryBot.create(:event, event_type: @event_type)
      FactoryBot.create(:participant, event: ev)
      expect(@event_type.testimonies.count).to eq 0
    end
    it 'participant w/ testimony' do
      ev = FactoryBot.create(:event, event_type: @event_type)
      FactoryBot.create(:participant, event: ev, testimony: 'Hello, Joe')
      expect(@event_type.testimonies.count).to eq 1
    end
    it 'participant w/2 testimones one selected' do
      ev = FactoryBot.create(:event, event_type: @event_type)
      FactoryBot.create(:participant, event: ev, testimony: 'Hello, Joe')
      FactoryBot.create(:participant, event: ev, testimony: 'Yeah', selected: true)
      FactoryBot.create(:participant, event: ev, testimony: 'Hello, Joe')
      testimonies = @event_type.testimonies
      expect(testimonies.count).to eq 3
      expect(testimonies[0].testimony).to eq 'Yeah'
    end
    it "shouldn't include participant other event type" do
      et = FactoryBot.create(:event_type)
      ev = FactoryBot.create(:event, event_type: et)
      FactoryBot.create(:participant, event: ev, testimony: 'Hello, Joe')
      expect(@event_type.testimonies.count).to eq 0
    end
  end
  context 'Slug & Canonical' do
    it 'allow stand alone event types' do
      et = FactoryBot.create(:event_type, id: 45, name: 'Joy Division (JD)')
      expect(et.slug).to eq '45-joy-division-jd'
    end
    it 'allow stand alone event types' do
      et = FactoryBot.create(:event_type)
      expect(et.canonical).to be_nil
      expect(et.clons).to eq []
    end
    it 'one canonical / one clon' do
      et1 = FactoryBot.create(:event_type, name: 'Original')
      et2 = FactoryBot.create(:event_type, name: 'Academia', canonical: et1)
      expect(et1.canonical).to be_nil
      expect(et1.clons.count).to eq 1
      expect(et1.clons[0].id).to eq et2.id

      expect(et2.canonical.id).to eq et1.id
      expect(et2.clons).to eq []
    end
    it 'stand alone event types canonical_slug are themself' do
      et = FactoryBot.create(:event_type, id: 504, name: 'Un Curso')
      expect(et.slug).to eq '504-un-curso'
      expect(et.canonical_slug).to eq '504-un-curso'
    end
    it 'stand alone event types canonical_slug are themself' do
      et1 = FactoryBot.create(:event_type, name: 'Original')
      et2 = FactoryBot.create(:event_type, name: 'Academia', canonical: et1)
      expect(et2.slug).to eq "#{et2.id}-academia"
      expect(et2.canonical_slug).to eq "#{et1.id}-original"
    end
  end
  context 'Deleted & noindex' do
    it 'New event type is no deleted and indexed' do
      et = FactoryBot.create(:event_type)
      expect(et.deleted).to be false
      expect(et.noindex).to be false
    end
  end
  context 'v2022 website fields' do
    it 'New event type has new fields: side_image, brochure, new_version' do
      et = FactoryBot.create(:event_type, side_image: 'alpha', brochure: 'beta')
      expect(et.new_version).to be false
      expect(et.side_image).to eq 'alpha'
      expect(et.brochure).to eq 'beta'
    end
  end
  context 'coupons' do
    it 'has a valid many-to-many relation with EventTypes' do
      event_type = FactoryBot.create(:event_type)
      coupon = FactoryBot.create(:coupon)
      coupon.event_types << event_type

      expect(coupon.event_types).to include(event_type)
    end
    it 'no cupon, no discount' do
      event_type = FactoryBot.create(:event_type)

      price, msg = event_type.apply_coupons(123.0, 1, Date.today, nil)
      expect(price).to eq 123
      expect(msg).to eq ''
    end
    context 'codeless' do
      it 'apply discount' do
        event_type = FactoryBot.create(:event_type)
        coupon = FactoryBot.create(:coupon, :codeless, percent_off: 10.0)
        coupon.event_types << event_type

        price, msg = event_type.apply_coupons(123.0, 1, Date.today, nil)
        expect(price).to eq 110.7
        expect(msg).not_to eq ''
      end
      it 'non active coupon doesnt count' do
        event_type = FactoryBot.create(:event_type)
        coupon = FactoryBot.create(:coupon, :codeless, active: false)
        coupon.event_types << event_type

        expect(event_type.active_coupons(Date.today)).to eq []
      end
      it 'expired coupon doesnt count' do
        event_type = FactoryBot.create(:event_type)
        coupon = FactoryBot.create(:coupon, :codeless, active: true, expires_on: Date.today - 1)
        coupon.event_types << event_type

        expect(event_type.active_coupons(Date.today)).to eq []
      end
    end
    context 'percent_off' do
      it 'apply discount' do
        event_type = FactoryBot.create(:event_type)
        coupon = FactoryBot.create(:coupon, :percent_off, percent_off: 10.0, code: 'ABRADADABRA')
        coupon.event_types << event_type

        price, msg = event_type.apply_coupons(123.0, 1, Date.today, 'ABRADADABRA')
        expect(price).to eq 110.7
        expect(msg).not_to eq ''
      end
      it 'normalize code to apply discount' do
        event_type = FactoryBot.create(:event_type)
        coupon = FactoryBot.create(:coupon, :percent_off, percent_off: 10.0, code: 'ABRADADABRA')
        coupon.event_types << event_type

        price, msg = event_type.apply_coupons(123.0, 1, Date.today, ' ABRADADABRa ')
        expect(price).to eq 110.7
        expect(msg).not_to eq ''
      end
      it 'dont apply discount bc wrong code' do
        event_type = FactoryBot.create(:event_type)
        coupon = FactoryBot.create(:coupon, :percent_off, percent_off: 10.0, code: 'ABRADADABRA')
        coupon.event_types << event_type

        price, msg = event_type.apply_coupons(123.0, 1, Date.today, 'ABRAD')
        expect(price).to eq 123.0
        expect(msg).to eq ''
      end
      it 'when (codeless + percentage_off) apply percentage_of discount ' do
        event_type = FactoryBot.create(:event_type)
        FactoryBot.create(:coupon, :codeless, percent_off: 50.0, code: '').event_types << event_type
        FactoryBot.create(:coupon, :percent_off, percent_off: 10.0, code: 'ABRADADABRA').event_types << event_type

        price, msg = event_type.apply_coupons(123.0, 1, Date.today, 'ABRADADABRA')
        expect(price).to eq 110.7
        expect(msg).not_to eq ''
      end
    end
  end
  context '.behavior' do
    let(:event_type) { EventType.new }
    [
      # deleted | external_url | canonical_id | noindex | expected_behavior
      [true,     nil,           nil,        false, '404'],
      [true,     'http://ext',  nil,        false, 'redirect to url'],
      [true,     nil,           1,          false, 'redirect to canonical'],
      [true,     'http://ext',  1,          false, 'redirect to url'],
      [false,    nil,           nil,        false, 'normal'],
      [false,    'http://ext',  nil,        false, 'redirect to url'],
      [false,    nil,           1,          false, 'normal & canonical'],
      [false,    'http://ext',  1,          false, 'redirect to url'],
      [false,    nil,           nil,        true, 'normal & noindex'],
      [false,    nil,           1,          true, 'normal & canonical & noindex']
    ].each do |deleted, external_url, canonical, noindex, expected_behavior|
      it "returns '#{expected_behavior}' when deleted: #{deleted}, external_url: #{external_url}, canonical: #{canonical}, noindex: #{noindex}" do
        event_type.deleted = deleted
        event_type.external_site_url = external_url
        event_type.canonical_id = canonical
        event_type.noindex = noindex
        expect(event_type.behavior).to eq(expected_behavior)
      end
    end
  end

  describe '#recommended' do
    let(:event_type) { FactoryBot.create(:event_type) }
    let(:recommended_event_type) { FactoryBot.create(:event_type) }

    before do
      FactoryBot.create(:recommended_content, source: event_type, target: recommended_event_type, relevance_order: 1)
    end

    it 'returns recommended item with proper formatting' do
      recommended = event_type.recommended

      expect(recommended.size).to eq(1)
      expect(recommended.first['type']).to eq('event_type')

      expect(recommended.first['id']).to eq(recommended_event_type.id)
      expect(recommended.first['title']).to eq(recommended_event_type.name)
      expect(recommended.first['slug']).to eq(recommended_event_type.slug)
      expect(recommended.first['cover']).to eq(recommended_event_type.cover)
      expect(recommended.first['subtitle']).to eq(recommended_event_type.subtitle)
    end
  end
end
