class CreateSources < ActiveRecord::Migration[8.1]
  def change
    create_table :sources do |t|
      t.string :name
      t.string :source_type
      t.string :base_url
      t.string :adapter
      t.string :auth_mode
      t.boolean :enabled

      t.timestamps
    end
  end
end
