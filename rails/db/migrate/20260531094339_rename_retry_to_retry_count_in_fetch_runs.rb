class RenameRetryToRetryCountInFetchRuns < ActiveRecord::Migration[8.1]
  def change
    rename_column :fetch_runs, :retry, :retry_count
  end
end
