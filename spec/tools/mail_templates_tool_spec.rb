# frozen_string_literal: true

require 'rails_helper'

# The email templates the site's forms trigger: one tool, four operations.
# MailTemplate is not a content-role model, so only an administrator writes
# them (marketing too, through its create/update on everything).
describe MailTemplatesTool do
  let(:user) { FactoryBot.create(:administrator) }

  def run(**args)
    tool = described_class.new
    allow(tool).to receive_messages(current_user: user, ability: Ability.new(user))
    JSON.parse(tool.call(**args))
  end

  let!(:contact_es) do
    FactoryBot.create(:mail_template, identifier: 'contacto_es', trigger_type: :contact_form, lang: :es,
                                      subject: 'Gracias, {{name}}', to: '{{email}}', content: 'Hola {{name}}')
  end
  let!(:download_en) do
    FactoryBot.create(:mail_template, identifier: 'descarga_en', trigger_type: :download_form, lang: :en,
                                      subject: 'Your {{resource_title_en}}', to: '{{email}}',
                                      content: '<a href="{{resource_getit_en}}">Get it</a>')
  end
  let!(:handoff) do
    FactoryBot.create(:mail_template, identifier: 'handoff_es', trigger_type: :download_form, lang: :es,
                                      resource_slug: 'session-handoff', active: false)
  end

  describe 'operation=list (the default)' do
    it 'summarises them by trigger, language and identifier, without the content' do
      result = run

      expect(result).to include('returned' => 3, 'total' => 3)
      expect(result['templates'].pluck('identifier')).to eq(%w[contacto_es handoff_es descarga_en])
      expect(result['templates'].first).not_to have_key('content')
    end

    it 'filters by trigger, language, resource and whether it is active' do
      expect(run(trigger_type: 'download_form')['templates'].pluck('identifier')).to eq(%w[handoff_es descarga_en])
      expect(run(lang: 'en')['templates'].pluck('identifier')).to eq(['descarga_en'])
      expect(run(resource_slug: 'session-handoff')['templates'].pluck('identifier')).to eq(['handoff_es'])
      expect(run(active: false)['templates'].pluck('identifier')).to eq(['handoff_es'])
    end

    it 'caps the listing with limit and says what it left out' do
      result = run(limit: 2)

      expect(result).to include('returned' => 2, 'total' => 3, 'truncated' => true)
      expect(result['note']).to include('trigger_type, lang, resource_slug or active')
    end

    it 'finds nothing for a trigger it does not know, rather than failing' do
      expect(run(trigger_type: 'newsletter')).to include('returned' => 0, 'total' => 0)
    end
  end

  describe 'operation=get' do
    it 'returns the template and how it renders for a sample contact' do
      result = run(operation: 'get', id: 'contacto_es')

      expect(result).to include('identifier' => 'contacto_es', 'content' => 'Hola {{name}}')
      expect(result['rendered']).to eq('subject' => 'Gracias, Ana García', 'to' => 'ana@example.com',
                                       'content' => 'Hola Ana García')
    end

    it 'also finds it by numeric id' do
      expect(run(operation: 'get', id: download_en.id.to_s)['identifier']).to eq('descarga_en')
    end

    it 'renders for a real resource, found by its English slug too' do
      FactoryBot.create(:resource, slug: 'guia-x', slug_en: 'guide-x', title_en: 'Guide X',
                                   getit_en: 'https://files.example/guide-x.pdf')

      result = run(operation: 'get', id: 'descarga_en', resource_slug: 'guide-x')

      expect(result['rendered']['subject']).to eq('Your Guide X')
      expect(result['rendered']['content']).to include('https://files.example/guide-x.pdf')
    end

    it 'says so when there is no such template, or no id' do
      expect(run(operation: 'get', id: 'nope')['errors']).to eq(['No mail template with identifier or id "nope"'])
      expect(run(operation: 'get')['errors']).to eq(['No mail template with identifier or id nil'])
    end

    # Resource.find_by_any_slug raises RecordNotFound for an unknown slug; it
    # used to fall into the tool's rescue and blame the template.
    it 'names the resource, not the template, when the resource slug is unknown' do
      expect(run(operation: 'get', id: 'descarga_en', resource_slug: 'no-existe')['errors'].join)
        .to include('no-existe')
    end
  end

  describe 'operation=update' do
    it 'previews, then touches only the fields passed on confirm' do
      expect(run(operation: 'update', id: 'contacto_es', subject: 'Recibimos tu consulta')['status'])
        .to eq('preview')
      expect(contact_es.reload.subject).to eq('Gracias, {{name}}')

      run(operation: 'update', id: 'contacto_es', subject: 'Recibimos tu consulta', confirm: true)

      expect(contact_es.reload).to have_attributes(subject: 'Recibimos tu consulta', content: 'Hola {{name}}',
                                                   to: '{{email}}')
    end

    it 'patches the content in place with replacements' do
      run(operation: 'update', id: 'contacto_es', confirm: true,
          replacements: [{ field: 'content', find: 'Hola', replace: 'Buen día' }])

      expect(contact_es.reload.content).to eq('Buen día {{name}}')
    end

    it 'warns about a Liquid variable the forms do not send' do
      expect(run(operation: 'update', id: 'contacto_es', subject: 'Hola {{nombre}}')['warnings'].join)
        .to include('{{nombre}}')
    end

    it 'empties cc and resource_slug with ""' do
      handoff.update!(cc: 'equipo@kleer.la')

      run(operation: 'update', id: 'handoff_es', cc: '', resource_slug: '', confirm: true)

      expect(handoff.reload).to have_attributes(cc: '', resource_slug: '')
    end

    it 'reports a value the enum does not know' do
      result = run(operation: 'update', id: 'contacto_es', delivery_schedule: 'weekly', confirm: true)

      expect(result['status']).to eq('error')
      expect(result['errors'].join).to include('weekly')
      expect(contact_es.reload.delivery_schedule).to eq('immediate')
    end

    it 'says so when there is no such template' do
      expect(run(operation: 'update', id: 'nope', subject: 'x')['errors'].join).to include('"nope"')
    end
  end

  describe 'operation=create' do
    let(:fields) do
      { operation: 'create', identifier: 'contacto_en', trigger_type: 'contact_form', lang: 'en',
        subject: 'Thanks, {{name}}', content: 'Hi {{name}}' }
    end

    it 'previews without saving' do
      expect(run(**fields)['status']).to eq('preview')
      expect(MailTemplate.find_by(identifier: 'contacto_en')).to be_nil
    end

    it 'saves on confirm, sent to the contact, active and immediate unless told otherwise' do
      expect(run(**fields, confirm: true)['status']).to eq('saved')

      expect(MailTemplate.find_by(identifier: 'contacto_en'))
        .to have_attributes(to: '{{email}}', active: true, delivery_schedule: 'immediate', lang: 'en')
    end

    it 'keeps the recipient and schedule it is given' do
      run(**fields, to: 'ventas@kleer.la', delivery_schedule: 'daily', active: false, confirm: true)

      expect(MailTemplate.find_by(identifier: 'contacto_en'))
        .to have_attributes(to: 'ventas@kleer.la', delivery_schedule: 'daily', active: false)
    end

    it 'reports what is missing or taken instead of saving' do
      expect(run(**fields.except(:subject), confirm: true)['errors'].join).to include('Subject')
      expect(run(**fields, identifier: 'contacto_es', confirm: true)['errors'].join).to include('Identifier')
      expect(MailTemplate.count).to eq(3)
    end
  end

  it 'names the operations it knows when given another' do
    expect(run(operation: 'send')['errors'].join).to include('list', 'get', 'update', 'create')
  end

  context 'as a content user, for whom mail templates are not content' do
    let(:user) { FactoryBot.create(:content_user) }

    it 'reads them but cannot write' do
      expect(run(operation: 'get', id: 'contacto_es')['identifier']).to eq('contacto_es')

      expect(run(operation: 'update', id: 'contacto_es', subject: 'x', confirm: true)['errors'].first)
        .to include('Unauthorized')
      expect(run(operation: 'create', identifier: 'x', trigger_type: 'contact_form', lang: 'es', subject: 'x',
                 content: 'y', confirm: true)['errors'].first).to include('Unauthorized')
      expect(contact_es.reload.subject).to eq('Gracias, {{name}}')
      expect(MailTemplate.count).to eq(3)
    end
  end

  context 'as marketing' do
    let(:user) { FactoryBot.create(:marketing_user) }

    it 'may write them' do
      expect(run(operation: 'update', id: 'contacto_es', subject: 'Nuevo', confirm: true)['status']).to eq('saved')
    end
  end
end
