# frozen_string_literal: true

# An event type created from the chat: the course template a certificate names.
#
# It is never put in the public catalog. The same record that backs a
# certificate also backs the course's page on the site, and one of those is a
# decision about what Kleer sells — so `include_in_catalog` is not an argument
# these tools take, it is forced off and said out loud in the warnings.
class EventTypeWriteService < ContentWriteService
  self.model = EventType
  self.editable_fields = %i[name description recipients program elevator_pitch goal learnings takeaways
                            duration lang tag_name subtitle is_kleer_certification kleer_cert_seal_image
                            csd_eligible new_version]
  self.long_fields = %w[description program recipients goal learnings takeaways]
  self.publication_flag = nil

  def initialize(trainers: nil, **args)
    super(**args)
    @trainer_names = trainers
  end

  private

  def assign
    super
    @record.include_in_catalog = false if @record.new_record?
    assign_trainers
  end

  def assign_trainers
    return if @trainer_names.blank?

    found = Trainer.where(name: @trainer_names)
    missing = @trainer_names - found.map(&:name)
    return errors << unknown_trainers(missing) if missing.any?

    @record.trainers = found
  end

  def unknown_trainers(missing)
    "Unknown trainer#{'s' if missing.size > 1} #{missing.map(&:inspect).join(', ')}. " \
      "Existing ones: #{Trainer.order(:name).pluck(:name).join(', ')}"
  end

  def model_warnings
    return [] unless @record.new_record?

    ['It is created out of the public catalog (include_in_catalog is false). If this course should be on ' \
     'sale on the site, add it to the catalog from the admin.']
  end
end
