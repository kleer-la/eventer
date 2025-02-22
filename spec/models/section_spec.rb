require 'rails_helper'

RSpec.describe Section, type: :model do
  let(:page) do
    Page.create!(
      name: 'Catalogo',
      slug: 'catalogo',
      lang: 'es',
      seo_title: 'Formación Empresarial en Métodos Ágiles',
      seo_description: 'Programas de capacitación In-Company...',
      canonical: '/catalogo'
    )
  end

  describe 'slug handling with FriendlyId' do
    it 'generates slug from title on creation' do
      section = Section.new(
        page:,
        title: 'Recommended Content',
        content: 'Lorem ipsum...'
      )
      section.save!
      expect(section.slug).to eq('recommended-content')
    end

    it 'regenerates slug when title changes' do
      section = Section.create!(
        page:,
        title: 'Recommended Content',
        content: 'Lorem ipsum...'
      )
      expect(section.slug).to eq('recommended-content')

      section.update!(title: 'Updated Recommendations')
      expect(section.slug).to eq('updated-recommendations')
    end

    it 'enforces slug uniqueness within page scope' do
      # Create first section
      Section.create!(
        page:,
        title: 'Recommended Content',
        content: 'Lorem ipsum...'
      )

      # Try to create another section with the same title on the same page
      duplicate_section = Section.new(
        page:,
        title: 'Recommended Content',
        content: 'Different content...'
      )
      expect(duplicate_section).not_to be_valid
      expect(duplicate_section.errors[:slug]).to include('ya está en uso')
    end

    it 'allows same title on different pages' do
      # Create another page
      other_page = Page.create!(
        name: 'Otro',
        slug: 'otro',
        lang: 'es',
        seo_title: 'Otro Título',
        seo_description: 'Otra descripción...',
        canonical: '/otro'
      )

      # Create section on first page
      Section.create!(
        page:,
        title: 'Recommended Content',
        content: 'Lorem ipsum...'
      )

      # Create section with same title on different page
      other_section = Section.create!(
        page: other_page,
        title: 'Recommended Content',
        content: 'Different content...'
      )
      expect(other_section).to be_valid
      expect(other_section.slug).to eq('recommended-content')
    end

    it 'finds section by friendly slug' do
      section = Section.create!(
        page:,
        title: 'Recommended Content',
        content: 'Lorem ipsum...'
      )
      found_section = Section.friendly.find('recommended-content')
      expect(found_section).to eq(section)
    end

    it 'raises error if slug not found' do
      expect { Section.friendly.find('non-existent-slug') }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
