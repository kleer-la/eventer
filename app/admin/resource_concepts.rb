# frozen_string_literal: true

# The cards of a "concepts" resource, nested under it: too many cards and
# fields to fit in the resource form.
ActiveAdmin.register ResourceConcept do
  belongs_to :resource, instance_name: :parent_resource, finder: :find_by_slug_or_id
  menu false

  controller do
    # Resource#concepts, not Resource#resource_concepts
    def method_for_association_chain = :concepts

    # Inside Arbre views `parent` is the enclosing HTML element.
    helper_method :concepts_resource
    def concepts_resource = parent
  end
  config.sort_order = 'position_asc'

  permit_params do
    params = %i[lang position slug name question stage definition analogy misconception
                correction practice related_slugs]
    params << :media if current_user.ability.can?(:set_media, ResourceConcept)
    params
  end

  breadcrumb do
    [link_to('Resources', admin_resources_path),
     link_to(concepts_resource.title_es, admin_resource_path(concepts_resource))]
  end

  filter :lang, as: :select, collection: ResourceConcept::LANGS
  filter :stage
  filter :name

  index title: proc { "Concepts · #{concepts_resource.title_es}" } do
    column :position
    column :stage
    column :name do |concept|
      link_to concept.name, admin_resource_resource_concept_path(concepts_resource, concept)
    end
    column :question
    column :lang
    column :slug
    actions
  end

  show title: :name do
    attributes_table do
      row :resource
      row :lang
      row :position
      row :slug
      row :stage
      row :name
      row :question
      row :definition
      row :analogy
      row :misconception
      row :correction
      row :practice
      row(:media) { |concept| concept.media.present? ? markdown(concept.media) : nil }
      row :related_slugs
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    stages = concepts_resource.concepts.distinct.pluck(:stage)
    f.inputs do
      f.input :lang, as: :select, collection: ResourceConcept::LANGS, include_blank: false
      f.input :position, hint: 'Reading order. Stages are ordered by the first position of their concepts'
      f.input :name
      f.input :slug, hint: 'Empty -> automatic from the name. It is the URL of the card on the site'
      f.input :question
      f.input :stage, input_html: { list: 'concept-stages' }, hint: 'Pick one already used or write a new one'
      f.input :definition, hint: ResourceConcept::LINK_HINT, input_html: { rows: 3 }
      f.input :analogy, hint: "Una imagen para recordarlo. #{ResourceConcept::LINK_HINT}", input_html: { rows: 2 }
      f.input :misconception, hint: "El malentendido (se muestra tachado). #{ResourceConcept::LINK_HINT}", input_html: { rows: 2 }
      f.input :correction, hint: "Lo que es cierto en su lugar. #{ResourceConcept::LINK_HINT}", input_html: { rows: 2 }
      f.input :practice, hint: "Qué cambia en la práctica. #{ResourceConcept::LINK_HINT}", input_html: { rows: 2 }
      if current_user.ability.can?(:set_media, ResourceConcept)
        f.input :media, input_html: { rows: 6 }, hint: 'Optional visual: Markdown or HTML'
      end
      f.input :related_slugs, hint: 'Slugs of concepts of this resource and language, separated by commas'
    end
    options = helpers.safe_join(stages.map { |stage| helpers.tag.option(value: stage) })
    text_node helpers.content_tag(:datalist, options, id: 'concept-stages')
    f.actions
  end
end
