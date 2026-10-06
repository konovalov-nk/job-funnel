class Source < ApplicationRecord
  SOURCE_TYPES = %w[static api rss].freeze
  ADAPTERS = %w[static_json greenhouse lever linkedin].freeze
  AUTH_MODES = %w[none api_key basic oauth].freeze

  has_many :fetch_runs, dependent: :destroy

  validates :name, presence: true
  validates :source_type, presence: true, inclusion: { in: SOURCE_TYPES }
  validates :base_url, presence: true
  validates :adapter, presence: true, inclusion: { in: ADAPTERS }
  validates :auth_mode, presence: true, inclusion: { in: AUTH_MODES }

  attribute :enabled, :boolean, default: true
  validates :enabled, inclusion: { in: [true, false] }
end
