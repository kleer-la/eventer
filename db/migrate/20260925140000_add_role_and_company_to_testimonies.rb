# frozen_string_literal: true

# Who speaks is half the value of a testimony for a decision maker: the site
# shows "Role · Company" under the name when they come (kleer-la/eventer#209).
class AddRoleAndCompanyToTestimonies < ActiveRecord::Migration[7.2]
  def change
    add_column :testimonies, :role, :string
    add_column :testimonies, :company, :string
  end
end
