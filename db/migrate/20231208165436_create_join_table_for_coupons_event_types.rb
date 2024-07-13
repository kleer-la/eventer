# frozen_string_literal: true

class CreateJoinTableForCouponsEventTypes < ActiveRecord::Migration[7.1]
  def change
    create_join_table :coupons, :event_types do |t|
      # t.index [:coupon_id, :event_type_id]
      t.index %i[event_type_id coupon_id]
      t.timestamps
    end
  end
end
