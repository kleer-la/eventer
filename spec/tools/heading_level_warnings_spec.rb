# frozen_string_literal: true

require 'rails_helper'

# The site renders each long field under headings of its own: an article body
# and a course description right under the page's h1, a course's recipients and
# takeaways under their section's h2. A field whose headings start above that,
# or skip a level, breaks the page's outline (website17's rake headings flags
# it), so the write preview says so (kleer-la/website17#466).
describe 'heading level warnings in MCP writes' do
  let(:user) { FactoryBot.create(:administrator) }

  def run(tool_class, **args)
    tool = tool_class.new
    allow(tool).to receive_messages(current_user: user, ability: Ability.new(user))
    JSON.parse(tool.call(**args))
  end

  def heading_warnings(result) = result['warnings'].grep(/heading/i)

  describe 'an article body, shown right under the h1' do
    let!(:article) { FactoryBot.create(:article, body: "Intro\r\n\r\n### Viejo\r\n\r\nTexto") }

    it 'warns when the body skips from the h1 to an h3' do
      result = run(ArticlesTool, operation: 'update', id: article.slug, body: "Intro\n\n### Arranque\n\nTexto")

      expect(heading_warnings(result).join).to include('body', '«Arranque»', 'h3', 'h2')
    end

    it 'warns about an HTML heading that skips a level' do
      result = run(ArticlesTool, operation: 'update', id: article.slug,
                                 body: "## Sección\n\n<h4>Descargar</h4>\n\nTexto")

      expect(heading_warnings(result).join).to include('«Descargar»', 'h4', 'h2')
    end

    it 'says nothing when the levels follow each other' do
      result = run(ArticlesTool, operation: 'update', id: article.slug,
                                 body: "## Uno\n\n### Uno punto uno\n\n## Dos\n\n<h3>Dos punto uno</h3>")

      expect(heading_warnings(result)).to be_empty
    end

    it 'says nothing when the body is not touched, however its headings are' do
      result = run(ArticlesTool, operation: 'update', id: article.slug, title: 'Otro título')

      expect(heading_warnings(result)).to be_empty
    end

    it 'checks the body a replacement leaves' do
      result = run(ArticlesTool, operation: 'update', id: article.slug,
                                 replacements: [{ field: 'body', find: 'Texto', replace: 'Otro texto' }])

      expect(heading_warnings(result).join).to include('«Viejo»')
    end

    it 'counts a markdown heading written without a space after the #' do
      result = run(ArticlesTool, operation: 'update', id: article.slug, body: "####Pegado\n\nTexto")

      expect(heading_warnings(result).join).to include('«Pegado»', 'h4')
    end
  end

  describe 'a course' do
    let(:event_type) do
      EventType.create!(name: 'Taller de Prueba', description: 'Un taller', recipients: 'Equipos',
                        program: 'Contenidos', elevator_pitch: 'Un taller', lang: 'es', duration: 8,
                        trainers: [Trainer.create!(name: 'Ana Prueba')])
    end

    it 'expects the description to start at h2' do
      result = run(EventTypesTool, operation: 'update', id: event_type.slug,
                                   description: "<h3>Qué es</h3>\n\nUn taller")

      expect(heading_warnings(result).join).to include('description', '«Qué es»', 'h3', 'h2')
    end

    it 'expects recipients to start at h3, below their section title' do
      warnings = heading_warnings(run(EventTypesTool, operation: 'update', id: event_type.slug,
                                                      recipients: "## Quiénes\n\nEquipos"))

      expect(warnings.join).to include('recipients', '«Quiénes»', 'h2', 'h3')
    end

    it 'leaves the FAQ alone: its h4 only splits the questions' do
      result = run(EventTypesTool, operation: 'update', id: event_type.slug,
                                   faq: '<h4>¿Cuánto dura?</h4>Dos días.')

      expect(heading_warnings(result)).to be_empty
    end
  end

  describe 'a resource long description, shown under the page h1' do
    let(:resource) { FactoryBot.create(:resource) }

    it 'checks each language' do
      result = run(ResourcesTool, operation: 'update', id: resource.slug,
                                  long_description_es: "## Qué vas a encontrar\n\nCartas",
                                  long_description_en: "#### What you get\n\nCards")

      expect(heading_warnings(result).join).to include('long_description_en', '«What you get»')
      expect(heading_warnings(result).join).not_to include('long_description_es')
    end
  end
end
