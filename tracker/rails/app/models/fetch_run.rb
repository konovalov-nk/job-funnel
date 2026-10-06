class FetchRun < ApplicationRecord
  STATUSES = %w[new running success failed].freeze

  belongs_to :source

  validates :adapter, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :retry_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  attribute :retry_count, :integer, default: 0
  attribute :status, :string, default: "new"
end
