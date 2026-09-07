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
                      trainers: [trainer], lang: 'es', duration: 8)
  end

  def run(tool_class, **args)
    tool = tool_class.new
    allow(tool).to receive_messages(current_user: user, ability: Ability.new(user))
    JSON.parse(tool.call(**args))
  end

  describe GetEventTypeTool do
    it 'returns the blocks that make up the page' do
      result = run(described_class, id: event_type.slug)

      expect(result['name']).to eq 'Taller de Prueba'
      expect(result['blocks']['description']).to include '/cursos/7-viejo'
      expect(result['trainers']).to eq ['Ana Prueba']
    end

    it 'says so when there is no such course' do
      result = run(described_class, id: 'no-existe')

      expect(result['status']).to eq 'error'
      expect(result['errors'].first).to include 'no-existe'
    end
  end

  describe UpdateEventTypeTool do
    it 'previews without saving' do
      result = run(described_class, id: event_type.slug, subtitle: 'Nuevo subtítulo')

      expect(result['status']).to eq 'preview'
      expect(event_type.reload.subtitle).to be_blank
    end

    it 'saves on confirm' do
      run(described_class, id: event_type.slug, subtitle: 'Nuevo subtítulo', confirm: true)

      expect(event_type.reload.subtitle).to eq 'Nuevo subtítulo'
    end

    # The reason these tools exist: patching a link inside a long block without
    # resending the whole thing.
    it 'patches a link inside a long block' do
      run(described_class, id: event_type.slug, confirm: true,
                           replacements: [{ field: 'description', find: '/cursos/7-viejo',
                                            replace: '/es/cursos/7-nuevo' }])

      expect(event_type.reload.description).to include '/es/cursos/7-nuevo'
      expect(event_type.description).not_to include '/cursos/7-viejo"'
    end

    it 'says so when there is no such course' do
      result = run(described_class, id: 'no-existe', subtitle: 'x')

      expect(result['status']).to eq 'error'
      expect(result['errors'].first).to include 'no-existe'
    end

    # Putting a course on sale is a decision about what Kleer sells, and
    # ability.rb keeps it away from the content role. It is not an argument.
    it 'does not take include_in_catalog' do
      expect(UpdateEventTypeTool.input_schema.key_map.map(&:name)).not_to include 'include_in_catalog'
    end
  end
end
