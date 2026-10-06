class CreateFetchRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :fetch_runs do |t|
      t.references :source, null: false, foreign_key: true
      t.string :adapter
      t.integer :retry
      t.string :status
      t.text :content

      t.timestamps
    end
  end
end
