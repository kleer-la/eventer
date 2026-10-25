# frozen_string_literal: true

require 'rails_helper'

# Site pages and their sections: one tool, seven operations. Page is not a
# content-role model, so writing one takes marketing or admin; deleting a
# section takes admin.
describe PagesTool do
  let(:user) { FactoryBot.create(:marketing_user) }

  def run(**args)
    tool = described_class.new
    allow(tool).to receive_messages(current_user: user, ability: Ability.new(user))
    JSON.parse(tool.call(**args))
  end

  describe 'operation=list (the default)' do
    before do
      FactoryBot.create(:page, name: 'Home', lang: :es, slug: 'home', template: 'overlay')
      FactoryBot.create(:page, name: 'Membresía IA', lang: :es, slug: 'membresia-ia', template: 'flagship')
      FactoryBot.create(:page, name: 'AI Membership', lang: :en, slug: 'membresia-ia', template: 'flagship')
    end

    it 'summarises them by language and name, with how many sections each has' do
      Page.find_by(name: 'Home').sections.create!(slug: 'hero', title: 'Hola', position: 1)

      result = run

      expect(result['pages'].pluck('name')).to eq(['Home', 'Membresía IA', 'AI Membership'])
      expect(result['pages'].first).to include('slug' => 'home', 'template' => 'overlay', 'sections' => 1,
                                               'noindex' => false, 'seo_title' => false)
    end

    it 'filters by name, slug, language and template' do
      expect(run(query: 'Membres')['pages'].pluck('name')).to eq(['Membresía IA'])
      expect(run(slug: 'membresia-ia')['pages'].size).to eq(2)
      expect(run(lang: 'en')['pages'].pluck('name')).to eq(['AI Membership'])
      expect(run(template: 'overlay')['pages'].pluck('name')).to eq(['Home'])
    end

    it 'names the valid templates when given another' do
      expect(run(template: 'landing')['errors']).to eq(['Unknown template "landing". Valid ones: overlay, flagship'])
    end

    it 'caps the listing with limit and says what it left out' do
      expect(run(limit: 1)).to include('returned' => 1, 'total' => 3, 'truncated' => true)
    end
  end

  describe 'operation=get' do
    let!(:page) do
      FactoryBot.create(:page, name: 'Membresía IA', lang: :es, slug: 'membresia-ia', template: 'flagship')
    end

    it 'returns the page with its sections in position order' do
      page.sections.create!(slug: 'contact', title: 'Hablemos', position: 9)
      page.sections.create!(slug: 'hero', title: 'Membresía', position: 1, cta_text: 'Agendar', cta_url: '#contact')

      result = run(operation: 'get', id: page.id)

      expect(result).to include('id' => page.id, 'name' => 'Membresía IA', 'rendered_title' => 'Membresía IA | Kleer',
                                'other_language' => nil)
      expect(result['sections'].pluck('slug')).to eq(%w[hero contact])
      expect(result['sections'].first).to include('title' => 'Membresía', 'cta_text' => 'Agendar',
                                                  'cta_url' => '#contact')
    end

    it 'finds it by slug and language, and points at the other language' do
      en = FactoryBot.create(:page, name: 'AI Membership', lang: :en, slug: 'membresia-ia', noindex: true)

      result = run(operation: 'get', slug: 'membresia-ia', lang: 'es')

      expect(result['id']).to eq(page.id)
      expect(result['other_language']).to eq('id' => en.id, 'lang' => 'en', 'noindex' => true)
    end

    it 'finds it by slug alone when only one language has it' do
      expect(run(operation: 'get', slug: page.slug)['id']).to eq(page.id)
    end

    it 'prefers the id when given both' do
      other = FactoryBot.create(:page, name: 'Otra', lang: :es, slug: 'otra')

      expect(run(operation: 'get', id: other.id, slug: page.slug)['id']).to eq(other.id)
    end

    it 'says what it could not find' do
      expect(run(operation: 'get', id: 0)['errors']).to eq(['No page with id 0'])
      expect(run(operation: 'get', slug: 'nada', lang: 'en')['errors']).to eq(['No page with slug "nada" in en'])
    end
  end

  describe 'operation=create' do
    let(:fields) { { operation: 'create', name: 'Nueva landing', lang: 'es', template: 'flagship' } }

    it 'previews without saving' do
      expect(run(**fields)['status']).to eq('preview')
      expect(Page.count).to eq(0)
    end

    it 'saves on confirm, deriving the slug from the name' do
      result = run(**fields, confirm: true)

      expect(result['status']).to eq('saved')
      expect(Page.find(result['id'])).to have_attributes(slug: 'nueva-landing', template: 'flagship')
    end

    it 'ignores the section fields: a page is created without sections' do
      result = run(**fields, title: 'Hero', content: '<p>Hola</p>', confirm: true)

      expect(Page.find(result['id']).sections).to be_empty
    end

    it 'reports what is missing, and a template it does not know' do
      expect(run(**fields.except(:name), confirm: true)['status']).to eq('error')
      expect(run(**fields, template: 'landing', confirm: true)['errors'].join).to include('landing')
      expect(Page.count).to eq(0)
    end

    # The tool's description promises it ("a 'flagship' with no sections
    # renders empty, and the preview says so"); PageWriteService has no such warning.
    it 'warns that a flagship without sections renders empty' do
      pending 'PageWriteService does not warn about an empty flagship, though the tool description says it does'

      expect(run(**fields)['warnings'].join).to match(/section/i)
    end
  end

  describe 'operation=update' do
    let!(:page) do
      FactoryBot.create(:page, name: 'Landing', lang: :es, slug: 'landing', seo_title: 'SEO', template: 'flagship')
    end

    it 'previews, then touches only the fields passed on confirm' do
      expect(run(operation: 'update', id: page.id, name: 'Landing 2')['status']).to eq('preview')
      expect(page.reload.name).to eq('Landing')

      run(operation: 'update', id: page.id, name: 'Landing 2', confirm: true)

      expect(page.reload).to have_attributes(name: 'Landing 2', slug: 'landing', seo_title: 'SEO')
    end

    it 'warns when the template changes' do
      expect(run(operation: 'update', id: page.id, template: 'overlay')['warnings'].join).to include('template')
    end

    it 'says so when there is no such page' do
      expect(run(operation: 'update', id: 0, name: 'x')['errors']).to eq(['No page with id 0'])
    end
  end

  describe 'sections' do
    let(:page) { FactoryBot.create(:page, name: 'Membresía IA', lang: :es, template: 'flagship') }
    let!(:hero) do
      page.sections.create!(slug: 'hero', title: 'Membresía', position: 1, content: '<p>La IA falla.</p>')
    end

    describe 'operation=create_section' do
      it 'previews, then adds the section to the page on confirm' do
        args = { operation: 'create_section', page_id: page.id, slug: 'faq', title: 'Preguntas', position: 2 }

        expect(run(**args)['status']).to eq('preview')
        expect(page.sections.count).to eq(1)

        expect(run(**args, confirm: true)['status']).to eq('saved')
        expect(page.sections.order(:position).pluck(:slug)).to eq(%w[hero faq])
      end

      it 'refuses a slug the page already uses' do
        result = run(operation: 'create_section', page_id: page.id, slug: 'hero', title: 'Otro', confirm: true)

        expect(result['status']).to eq('error')
        expect(page.sections.count).to eq(1)
      end

      it 'says so when the page does not exist' do
        expect(run(operation: 'create_section', page_id: 0, title: 'x')['errors']).to eq(['No page with id 0'])
      end
    end

    describe 'operation=update_section' do
      it 'previews, then changes only the section fields passed on confirm' do
        expect(run(operation: 'update_section', id: hero.id, title: 'Nuevo')['status']).to eq('preview')
        expect(hero.reload.title).to eq('Membresía')

        run(operation: 'update_section', id: hero.id, title: 'Nuevo', name: 'No es de la sección', confirm: true)

        expect(hero.reload).to have_attributes(title: 'Nuevo', content: '<p>La IA falla.</p>')
        expect(page.reload.name).to eq('Membresía IA')
      end

      it 'patches the HTML in place with replacements' do
        run(operation: 'update_section', id: hero.id, confirm: true,
            replacements: [{ field: 'content', find: 'falla', replace: 'funciona' }])

        expect(hero.reload.content).to eq('<p>La IA funciona.</p>')
      end

      it 'says so when the section does not exist' do
        expect(run(operation: 'update_section', id: 0, title: 'x')['errors']).to eq(['No section with id 0'])
      end
    end

    describe 'operation=delete_section' do
      let(:user) { FactoryBot.create(:administrator) }

      it 'previews which section it would delete, then deletes it on confirm' do
        preview = run(operation: 'delete_section', id: hero.id)
        expect(preview).to include('status' => 'preview')
        expect(preview['section']).to include('id' => hero.id, 'slug' => 'hero', 'page_id' => page.id)
        expect(preview['section']).not_to have_key('content')
        expect(Section.exists?(hero.id)).to be true

        result = run(operation: 'delete_section', id: hero.id, confirm: true)
        expect(result).to include('status' => 'deleted', 'admin_path' => "/admin/pages/#{page.id}")
        expect(Section.exists?(hero.id)).to be false
      end

      it 'says so when the section does not exist' do
        expect(run(operation: 'delete_section', id: 0)['errors']).to eq(['No section with id 0'])
      end

      context 'as marketing, who edits pages but deletes nothing' do
        let(:user) { FactoryBot.create(:marketing_user) }

        it 'refuses' do
          expect(run(operation: 'delete_section', id: hero.id, confirm: true)['errors'].first)
            .to include('Unauthorized')
          expect(Section.exists?(hero.id)).to be true
        end
      end
    end

    context 'as a content user, for whom pages are not content' do
      let(:user) { FactoryBot.create(:content_user) }

      it 'reads the page but cannot write it or its sections' do
        expect(run(operation: 'get', id: page.id)['sections'].size).to eq(1)

        expect(run(operation: 'create', name: 'x', lang: 'es', confirm: true)['errors'].first)
          .to include('Unauthorized')
        expect(run(operation: 'update', id: page.id, name: 'x', confirm: true)['errors'].first)
          .to include('Unauthorized')
        expect(run(operation: 'create_section', page_id: page.id, title: 'x', confirm: true)['errors'].first)
          .to include('Unauthorized')
        expect(run(operation: 'update_section', id: hero.id, title: 'x', confirm: true)['errors'].first)
          .to include('Unauthorized')
        expect(page.reload.name).to eq('Membresía IA')
        expect(hero.reload.title).to eq('Membresía')
      end
    end
  end

  it 'names the operations it knows when given another, without calling a private method' do
    result = run(operation: 'find')

    expect(result['errors'].join).to include('list', 'get', 'create', 'update', 'create_section', 'update_section',
                                             'delete_section')
  end
end
