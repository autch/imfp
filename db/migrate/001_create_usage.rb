class CreateUsage < ActiveRecord::Migration
  def change
    create_table :sims, id: false do |t|
      t.string :hdo_code, null: false
      t.string :phone_number, null: false
      t.string :iccid, null: false
      t.string :sim_type, null: false

      t.timestamps

      t.index [:hdo_code], unique: true
    end

    create_table :daily_usages do |t|
      t.string :hdo_code, null: false
      t.date :date, null: false
      t.integer :lte_3g, null: false
      t.integer :limited_200k, null: false
      t.datetime :last_checked, null: false

      t.timestamps

      t.index [:hdo_code, :date], unique: true
    end
  end
end
