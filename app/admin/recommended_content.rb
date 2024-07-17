ActiveAdmin.register RecommendedContent do
  menu parent: 'We Publish'

  index do
    selectable_column
    id_column
    column :source do |rc|
      link_to "#{rc.source_type} - #{rc.source.title}", edit_polymorphic_path([:admin, rc.source])
    end
    column :title do |rc|
      link_to rc.source.title, edit_polymorphic_path([:admin, rc.source])
    end
    column :target do |rc|
      "#{rc.target_type} - #{rc.target.title}"
    end
    column :relevance_order
  end

  filter :source_type, as: :select, collection: %w[Service Article EventType]
  filter :target_type, as: :select, collection: %w[Service Article EventType]
  filter :relevance_order

  controller do
    def scoped_collection
      super.includes(:source, :target)
    end
  end
end
