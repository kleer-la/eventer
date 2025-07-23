class AddTextResponseToResponses < ActiveRecord::Migration[7.2]
  def change
    add_column :responses, :text_response, :text
    change_column_null :responses, :answer_id, true
  end
end