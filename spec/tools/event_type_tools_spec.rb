# frozen_string_literal: true

require 'rails_helper'

# The course page is long text with links in it, and it ages the way an article
# does: every course rename leaves stale links behind. Without these two tools a
# course type could be created from the chat and never touched again.
describe 'event type MCP tools' do
  let(:user) { FactoryBot.create(:content_user) }
  let(:trainer) { Trainer.create!(name: 'Ana Prueba') }
  let(:event_type) do
    EventType.create!(name: 'Taller de Prueba', description: 'Un taller <a href="/cursos/7-viejo">viejo</a>',
                      recipients: 'Equipos', program: 'Contenidos', elevator_pitch: 'Un taller',
                      faq: '<h4>¿Por dónde empiezo?</h4>Por <a href="/cursos/7-viejo">este</a>.',
                      trainers: [trainer], lang: 'es', duration: 8)
  end

  def run(tool_class, **args)
    tool = tool_class.new
    allow(tool).to receive_messages(current_user: user, ability: Ability.new(user))
    JSON.parse(tool.call(**args))
  end

  describe 'operation=get' do
    it 'returns the blocks that make up the page' do
      result = run(EventTypesTool, operation: 'get', id: event_type.slug)

      expect(result['name']).to eq 'Taller de Prueba'
      expect(result['blocks']['description']).to include '/cursos/7-viejo'
      expect(result['trainers']).to eq ['Ana Prueba']
    end

    # The questions and answers are a block of the page like any other, and the
    # links inside them go stale the same way.
    it 'returns the questions and answers' do
      result = run(EventTypesTool, operation: 'get', id: event_type.slug)

      expect(result['blocks']['faq']).to include '/cursos/7-viejo'
    end

    it 'says so when there is no such course' do
      result = run(EventTypesTool, operation: 'get', id: 'no-existe')

      expect(result['status']).to eq 'error'
      expect(result['errors'].first).to include 'no-existe'
    end
  end

  describe 'operation=update' do
    it 'previews without saving' do
      result = run(EventTypesTool, operation: 'update', id: event_type.slug, subtitle: 'Nuevo subtítulo')

      expect(result['status']).to eq 'preview'
      expect(event_type.reload.subtitle).to be_blank
    end

    it 'saves on confirm' do
      run(EventTypesTool, operation: 'update', id: event_type.slug, subtitle: 'Nuevo subtítulo', confirm: true)

      expect(event_type.reload.subtitle).to eq 'Nuevo subtítulo'
    end

    # Trainers are a has_and_belongs_to_many: assigning them to a saved record
    # writes the join rows at once, so they must wait for confirm like the rest.
    describe 'trainers' do
      let(:other) { Trainer.create!(name: 'Otro Entrenador') }

      it 'previews a trainer change without saving it' do
        result = run(EventTypesTool, operation: 'update', id: event_type.slug, trainers: [other.name])

        expect(result['status']).to eq 'preview'
        expect(result['changes']['trainers']).to eq('from' => ['Ana Prueba'], 'to' => ['Otro Entrenador'])
        expect(event_type.reload.trainers).to eq [trainer]
      end

      it 'saves nothing when the rest of the record does not validate' do
        run(EventTypesTool, operation: 'update', id: event_type.slug, trainers: [other.name],
                            elevator_pitch: 'x' * 200, confirm: true)

        expect(event_type.reload.trainers).to eq [trainer]
      end

      # A course with no trainers and an over-long pitch (DevOps Leader, 241)
      # fails validation on either field alone: both go in one call.
      it 'repairs a course that fails validation on two fields at once' do
        event_type.update_columns(elevator_pitch: 'x' * 200)
        event_type.trainers.clear

        result = run(EventTypesTool, operation: 'update', id: event_type.slug, trainers: [other.name],
                                     elevator_pitch: 'Un taller corto', confirm: true)

        expect(result['status']).to eq 'saved'
        expect(event_type.reload.trainers).to eq [other]
        expect(event_type.elevator_pitch).to eq 'Un taller corto'
      end
    end

    # The reason these tools exist: patching a link inside a long block without
    # resending the whole thing.
    it 'patches a link inside a long block' do
      run(EventTypesTool, operation: 'update', id: event_type.slug, confirm: true,
                          replacements: [{ field: 'description', find: '/cursos/7-viejo',
                                           replace: '/es/cursos/7-nuevo' }])

      expect(event_type.reload.description).to include '/es/cursos/7-nuevo'
      expect(event_type.description).not_to include '/cursos/7-viejo"'
    end

    it 'patches a link inside the questions and answers' do
      run(EventTypesTool, operation: 'update', id: event_type.slug, confirm: true,
                          replacements: [{ field: 'faq', find: '/cursos/7-viejo',
                                           replace: '/es/cursos/7-nuevo' }])

      expect(event_type.reload.faq).to include '/es/cursos/7-nuevo'
    end

    it 'says so when there is no such course' do
      result = run(EventTypesTool, operation: 'update', id: 'no-existe', subtitle: 'x')

      expect(result['status']).to eq 'error'
      expect(result['errors'].first).to include 'no-existe'
    end

    # A course that leaves the catalog sends its traffic to the service that
    # replaces it (kleer-marketing#28). external_site_url is a path or an
    # absolute URL, and the site answers the course page with a 301 to it.
    it 'sends the course page elsewhere with external_site_url' do
      run(EventTypesTool, operation: 'update', id: event_type.slug, confirm: true,
                          external_site_url: '/es/servicios/producto-digital/desarrollo-productos-digitales-agentes-ia')

      expect(event_type.reload.external_site_url)
        .to eq '/es/servicios/producto-digital/desarrollo-productos-digitales-agentes-ia'
    end

    it 'rejects an external_site_url that is neither a path nor a URL' do
      result = run(EventTypesTool, operation: 'update', id: event_type.slug, confirm: true,
                                   external_site_url: 'servicios/otro')

      expect(result['status']).to eq 'error'
      expect(result['errors'].join).to include 'external_site_url'
      expect(event_type.reload.external_site_url).to be_blank
    end

    # Putting a course on sale is a decision about what Kleer sells: ability.rb
    # keeps it for the publisher role (set_include_in_catalog), the same line
    # the admin form draws.
    describe 'in_catalog' do
      it 'refuses it to the content role' do
        result = run(EventTypesTool, operation: 'update', id: event_type.slug, in_catalog: true, confirm: true)

        expect(result['status']).to eq 'error'
        expect(result['errors'].join).to include 'catalog'
        expect(event_type.reload.include_in_catalog).to be_falsey
      end

      context 'as a publisher' do
        let(:user) { FactoryBot.create(:publisher_user) }

        it 'previews putting the course on sale without saving it' do
          result = run(EventTypesTool, operation: 'update', id: event_type.slug, in_catalog: true)

          expect(result['status']).to eq 'preview'
          expect(result['changes']['include_in_catalog']).to eq('from' => nil, 'to' => true)
          expect(result['warnings'].join).to include 'catalog'
          expect(event_type.reload.include_in_catalog).to be_falsey
        end

        it 'puts the course on sale on confirm' do
          run(EventTypesTool, operation: 'update', id: event_type.slug, in_catalog: true, confirm: true)

          expect(event_type.reload.include_in_catalog).to be true
        end

        it 'takes the course off sale, and points at external_site_url' do
          event_type.update!(include_in_catalog: true)

          result = run(EventTypesTool, operation: 'update', id: event_type.slug, in_catalog: false, confirm: true)

          expect(result['warnings'].join).to include 'external_site_url'
          expect(event_type.reload.include_in_catalog).to be false
        end

        it 'still creates the course out of the catalog' do
          result = run(EventTypesTool, operation: 'create', name: 'Otro Taller', description: 'D',
                                       recipients: 'R', program: 'P', elevator_pitch: 'E',
                                       trainers: [trainer.name], in_catalog: true, confirm: true)

          expect(EventType.find(result['id']).include_in_catalog).to be false
          expect(result['warnings'].join).not_to include 'taken out'
        end
      end
    end
  end
end
