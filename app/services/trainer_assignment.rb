# frozen_string_literal: true

# Trainers by name, as the admin shows them, for the write services of models
# that have them (event types, articles). An unknown name is an error that
# lists the existing ones rather than being skipped.
#
# The association is a has_and_belongs_to_many, so assigning it to a saved
# record writes at once: ContentWriteService#call runs in a savepoint that
# rolls it back on a preview or a failed validation.
module TrainerAssignment
  def initialize(trainers: nil, **args)
    super(**args)
    @trainer_names = trainers
  end

  private

  def assign
    super
    assign_trainers
  end

  def assign_trainers
    return if @trainer_names.blank?

    found = Trainer.where(name: @trainer_names)
    missing = @trainer_names - found.map(&:name)
    return errors << unknown_trainers(missing) if missing.any?

    @trainers_before = @record.trainers.map(&:name)
    @record.trainers = found
  end

  def unknown_trainers(missing)
    "Unknown trainer#{'s' if missing.size > 1} #{missing.map(&:inspect).join(', ')}. " \
      "Existing ones: #{Trainer.order(:name).pluck(:name).join(', ')}"
  end

  # The association never reaches record.changes, so the preview says it here.
  def changes
    after = @record.trainers.map(&:name)
    return super if @trainers_before.nil? || @trainers_before.sort == after.sort

    super.merge('trainers' => { from: @trainers_before, to: after })
  end
end
