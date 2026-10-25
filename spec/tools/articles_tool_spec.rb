# frozen_string_literal: true

require 'rails_helper'

# Blog articles: one tool, five operations. The request specs drive it over
# MCP; these call the tool directly, one operation at a time, and pin what it
# decides itself — which filters list applies, how it finds an article, and
# which writes it refuses before handing them to ArticleWriteService.
describe ArticlesTool do
  let(:user) { FactoryBot.create(:administrator) }

  def run(**args)
    tool = described_class.new
    allow(tool).to receive_messages(current_user: user, ability: Ability.new(user))
    JSON.parse(tool.call(**args))
  end

  describe 'operation=list (the default)' do
    let(:agilidad) { FactoryBot.create(:category, name: 'Agilidad') }

    # Creating an article stamps substantive_change_at with the moment it is
    # saved, so the ordering is set afterwards.
    def article(changed:, **attributes)
      FactoryBot.create(:article, **attributes).tap { |a| a.update_column(:substantive_change_at, changed) }
    end

    before do
      article(title: 'Kanban en equipos', lang: 'es', published: true, category: agilidad, changed: 2.days.ago)
      article(title: 'La creación de un Producto', lang: 'es', published: false, slug: 'la-creacion-de-un-producto',
              changed: 1.day.ago)
      article(title: 'Scrum in English', lang: 'en', published: false, changed: 3.days.ago)
    end

    it 'summarises them, most recently changed first, without the body' do
      result = run

      expect(result).to include('returned' => 3, 'total' => 3)
      expect(result['articles'].pluck('title'))
        .to eq(['La creación de un Producto', 'Kanban en equipos', 'Scrum in English'])
      expect(result['articles'].first.keys)
        .to contain_exactly('id', 'slug', 'title', 'lang', 'published', 'selected', 'category', 'description',
                            'substantive_change_at')
    end

    it 'filters by language, publication and category' do
      expect(run(lang: 'en')['articles'].pluck('title')).to eq(['Scrum in English'])
      expect(run(published: true)['articles'].pluck('title')).to eq(['Kanban en equipos'])
      expect(run(published: false)['articles'].size).to eq(2)
      expect(run(category: 'Agilidad')['articles'].pluck('category')).to eq(['Agilidad'])
    end

    it 'finds a title typed without its accents, through the slug' do
      expect(run(query: 'la creacion de')['articles'].pluck('title')).to eq(['La creación de un Producto'])
    end

    it 'caps the listing with limit and says what it left out' do
      result = run(limit: 2)

      expect(result).to include('returned' => 2, 'total' => 3, 'truncated' => true)
      expect(result['note']).to include('query, lang, published or category')
    end

    it 'returns at least one even when asked for none' do
      expect(run(limit: 0)['returned']).to eq(1)
    end
  end

  describe 'operation=get' do
    let!(:article) do
      FactoryBot.create(:article, title: 'Con autor', body: 'El cuerpo entero', redirect_url: '/es/blog/otro')
    end

    before { article.trainers << Trainer.create!(name: 'Carlos Peix') }

    it 'returns the article in full by slug, with its authors' do
      result = run(operation: 'get', id: article.slug)

      expect(result).to include('id' => article.id, 'title' => 'Con autor', 'body' => 'El cuerpo entero',
                                'redirect_url' => '/es/blog/otro', 'trainers' => ['Carlos Peix'])
    end

    it 'also finds it by numeric id' do
      expect(run(operation: 'get', id: article.id.to_s)['slug']).to eq(article.slug)
    end

    it 'says so when there is no such article, or no id at all' do
      expect(run(operation: 'get', id: 'no-existe')).to eq('status' => 'error',
                                                           'errors' => ['No article with slug or id "no-existe"'])
      expect(run(operation: 'get')['errors']).to eq(['No article with slug or id nil'])
    end
  end

  describe 'operation=create' do
    let(:fields) { { operation: 'create', title: 'Nuevo artículo', description: 'Un resumen', body: 'El cuerpo' } }

    it 'previews without saving' do
      result = run(**fields)

      expect(result['status']).to eq('preview')
      expect(Article.count).to eq(0)
    end

    it 'saves on confirm, unpublished, in Spanish, with the slug taken from the title' do
      result = run(**fields, confirm: true)

      expect(result['status']).to eq('saved')
      expect(Article.find(result['id'])).to have_attributes(slug: 'nuevo-articulo', published: false, lang: 'es')
    end

    it 'reports what is missing instead of saving' do
      result = run(**fields.except(:title), confirm: true)

      expect(result['status']).to eq('error')
      expect(result['errors'].join).to include('Title')
      expect(Article.count).to eq(0)
    end

    it 'sets the category by name' do
      FactoryBot.create(:category, name: 'Agilidad')

      run(**fields, category: 'Agilidad', confirm: true)

      expect(Article.last.category_name).to eq('Agilidad')
    end

    context 'as a content user' do
      let(:user) { FactoryBot.create(:content_user) }

      it 'creates it but may not publish it' do
        expect(run(**fields, confirm: true)['status']).to eq('saved')

        result = run(**fields, title: 'Otro', published: true, confirm: true)
        expect(result['status']).to eq('error')
        expect(result['errors'].join).to match(/not allowed/i)
      end
    end
  end

  describe 'operation=update' do
    let!(:article) { FactoryBot.create(:article, title: 'Viejo título', body: 'Cuerpo viejo', tabtitle: 'Pestaña') }

    it 'previews, then touches only the fields passed on confirm' do
      expect(run(operation: 'update', id: article.slug, title: 'Nuevo título')['status']).to eq('preview')
      expect(article.reload.title).to eq('Viejo título')

      run(operation: 'update', id: article.slug, title: 'Nuevo título', confirm: true)

      expect(article.reload).to have_attributes(title: 'Nuevo título', body: 'Cuerpo viejo', tabtitle: 'Pestaña')
    end

    it 'patches the body in place with replacements' do
      run(operation: 'update', id: article.slug, confirm: true,
          replacements: [{ field: 'body', find: 'viejo', replace: 'nuevo' }])

      expect(article.reload.body).to eq('Cuerpo nuevo')
    end

    it 'empties a field named in clear' do
      run(operation: 'update', id: article.slug, clear: ['tabtitle'], confirm: true)

      expect(article.reload.tabtitle).to be_blank
    end

    it 'says so when there is no such article' do
      expect(run(operation: 'update', id: 'no-existe', title: 'x')['errors'].join).to include('no-existe')
    end
  end

  describe 'operation=copy_from_production' do
    it 'needs the slug of the article in production' do
      expect(run(operation: 'copy_from_production')['errors'].join).to include('id is required')
    end

    it 'refuses outside QA, where there is no production to copy from' do
      stub_const('ENV', ENV.to_h.except('PRODUCTION_API_URL'))

      expect(run(operation: 'copy_from_production', id: 'algo')['errors'].join).to include('Only on QA')
    end
  end

  it 'names the operations it knows when given another' do
    result = run(operation: 'delete', id: 'algo')

    expect(result['status']).to eq('error')
    expect(result['errors'].join).to include('list', 'get', 'create', 'update', 'copy_from_production')
  end

  context 'as a user who may only read' do
    let(:user) { FactoryBot.create(:comercial) }
    let!(:article) { FactoryBot.create(:article) }

    it 'lists and reads them but cannot write or copy' do
      expect(run['returned']).to eq(1)
      expect(run(operation: 'get', id: article.slug)['id']).to eq(article.id)

      expect(run(operation: 'create', title: 'x', description: 'y', body: 'z', confirm: true)['errors'].first)
        .to include('Unauthorized')
      expect(run(operation: 'update', id: article.slug, title: 'x', confirm: true)['errors'].first)
        .to include('Unauthorized')
      expect(run(operation: 'copy_from_production', id: article.slug)['errors'].first).to include('Unauthorized')
      expect(article.reload.title).not_to eq('x')
    end
  end
end
