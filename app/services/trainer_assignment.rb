# frozen_string_literal: true

# Trainers by name, as the admin shows them, for the write services of models
# that have them: the trainers of event types and articles, the authors,
# translators and illustrators of resources. Each service names its
# associations in `trainer_associations`. A list given replaces the current
# one and [] empties it; one not given is left alone. An unknown name is an
# error that lists the existing ones rather than being skipped.
#
# Assigning one of these associations to a saved record writes at once:
# ContentWriteService#call runs in a savepoint that rolls it back on a preview
# or a failed validation.
module TrainerAssignment
  def self.included(base)
    base.class_attribute :trainer_associations, default: %i[trainers]
  end

  def initialize(**args)
    names = args.slice(*self.class.trainer_associations)
    super(**args.except(*self.class.trainer_associations))
    @trainer_names = names.compact
  end

  private

  def assign
    super
    @trainer_names.each { |association, names| assign_trainers(association, names) }
  end

  def assign_trainers(association, names)
    found = Trainer.where(name: names)
    missing = names - found.map(&:name)
    return errors << unknown_trainers(missing) if missing.any?

    trainers_before[association] = @record.public_send(association).map(&:name)
    @record.public_send("#{association}=", found)
  end

  def trainers_before = @trainers_before ||= {}

  def unknown_trainers(missing)
    "Unknown trainer#{'s' if missing.size > 1} #{missing.map(&:inspect).join(', ')}. " \
      "Existing ones: #{Trainer.order(:name).pluck(:name).join(', ')}"
  end

  # The associations never reach record.changes, so the preview says it here.
  def changes
    trainers_before.each_with_object(super) do |(association, before), all|
      after = @record.public_send(association).map(&:name)
      all[association.to_s] = { from: before, to: after } unless before.sort == after.sort
    end
  end
end
