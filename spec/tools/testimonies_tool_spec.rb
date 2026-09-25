# frozen_string_literal: true

require 'rails_helper'

# What clients and participants said about a service or a course. Testimony is
# a content-role model, so a content user may write them; starring one is what
# puts it on the area page (kleer-la/eventer#206).
describe TestimoniesTool do
  let(:user) { FactoryBot.create(:content_user) }
  let(:area) { FactoryBot.create(:service_area) }
  let(:service) { FactoryBot.create(:service, service_area: area, name: 'Flujo y mejora continua') }
  let(:course) { FactoryBot.create(:event_type, name: 'CSPO') }

  def run(**args)
    tool = described_class.new
    allow(tool).to receive_messages(current_user: user, ability: Ability.new(user))
    JSON.parse(tool.call(**args))
  end

  describe 'operation=list' do
    before do
      FactoryBot.create(:testimony, :starred, testimonial: service, first_name: 'Ana', last_name: 'Pérez')
      FactoryBot.create(:testimony, testimonial: service, first_name: 'Beto', last_name: 'Gómez')
      FactoryBot.create(:testimony, testimonial: course, first_name: 'Carla', last_name: 'Ruiz')
    end

    it 'says who each one is about and whether it is starred' do
      ana = run(service: service.slug)['testimonies'].find { |t| t['first_name'] == 'Ana' }

      expect(ana).to include('starred' => true,
                             'about' => include('type' => 'Service', 'slug' => service.slug,
                                                'name' => 'Flujo y mejora continua'))
    end

    it 'filters by service, by course, and by starred' do
      expect(run(service: service.slug)['testimonies'].pluck('first_name')).to contain_exactly('Ana', 'Beto')
      expect(run(event_type: course.id.to_s)['testimonies'].pluck('first_name')).to eq(['Carla'])
      expect(run(service: service.slug, starred: true)['testimonies'].pluck('first_name')).to eq(['Ana'])
    end

    it 'lists what an area shows: the testimonies of its services' do
      expect(run(service_area: area.slug)['testimonies'].pluck('first_name')).to contain_exactly('Ana', 'Beto')
    end
  end

  describe 'operation=get' do
    it 'returns the text as HTML with the links and photo' do
      testimony = FactoryBot.create(:testimony, testimonial: service, testimony: '<p>Nos ordenó el backlog.</p>')

      result = run(operation: 'get', id: testimony.id)

      expect(result['testimony']).to include('Nos ordenó el backlog.')
      expect(result).to include('profile_url' => testimony.profile_url, 'photo_url' => testimony.photo_url)
    end

    it 'says so when the id is unknown' do
      expect(run(operation: 'get', id: 999_999)['errors'].first).to include('No testimony with id 999999')
    end
  end

  describe 'operation=create' do
    let(:fields) do
      { operation: 'create', first_name: 'Ana', last_name: 'Pérez', testimony: '<p>Nos ordenó el backlog.</p>',
        service: service.slug }
    end

    it 'previews without saving, naming what it is about' do
      result = run(**fields)

      expect(result['status']).to eq('preview')
      expect(result['warnings']).to include(a_string_matching(/Flujo y mejora continua/))
      expect(Testimony.count).to eq(0)
    end

    it 'saves on confirm, not starred unless asked' do
      run(**fields, confirm: true)

      testimony = Testimony.last
      expect(testimony).to have_attributes(first_name: 'Ana', testimonial: service, stared: false)
      expect(testimony.testimony.to_s).to include('Nos ordenó el backlog.')
    end

    it 'can be about a course, by its id' do
      run(**fields.except(:service), event_type: course.id.to_s, confirm: true)

      expect(Testimony.last.testimonial).to eq(course)
    end

    it 'needs to know what it is about, and only one thing' do
      expect(run(**fields.except(:service))['errors'].join).to match(/service or event_type/)
      expect(run(**fields, event_type: course.id.to_s)['errors'].join).to match(/service or event_type/)
    end

    it 'rejects a service it does not know' do
      expect(run(**fields, service: 'no-existe')['errors'].join).to include('Unknown service "no-existe"')
    end
  end

  describe 'operation=update' do
    let!(:testimony) { FactoryBot.create(:testimony, testimonial: service, first_name: 'Ana') }

    it 'stars it, and warns that it will show on the site' do
      preview = run(operation: 'update', id: testimony.id, starred: true)
      expect(preview['warnings']).to include(a_string_matching(/visible/))

      run(operation: 'update', id: testimony.id, starred: true, confirm: true)
      expect(testimony.reload.stared).to be true
    end

    it 'edits the text in place with replacements' do
      testimony.update!(testimony: '<p>Nos ordenó el backlog en tres meses.</p>')

      run(operation: 'update', id: testimony.id, confirm: true,
          replacements: [{ field: 'testimony', find: 'tres meses', replace: 'seis semanas' }])

      expect(testimony.reload.testimony.to_s).to include('en seis semanas')
    end

    it 'can move it to another service' do
      other = FactoryBot.create(:service, service_area: area, name: 'Otro servicio')

      run(operation: 'update', id: testimony.id, service: other.slug, confirm: true)

      expect(testimony.reload.testimonial).to eq(other)
    end
  end

  context 'as a user who may only read' do
    let(:user) { FactoryBot.create(:comercial) }

    it 'lists them but cannot write' do
      FactoryBot.create(:testimony, testimonial: service)

      expect(run['returned']).to eq(1)
      expect(run(operation: 'create', first_name: 'Ana', last_name: 'P', service: service.slug)['errors'].first)
        .to include('Unauthorized')
    end
  end
end
