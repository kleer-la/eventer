# frozen_string_literal: true

class AddJitPaymentUrlToEvent < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :enable_online_payment, :boolean, default: false
    add_column :events, :online_course_codename, :string
    add_column :events, :online_cohort_codename, :string
  end
end
