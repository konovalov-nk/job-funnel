FactoryBot.define do
  factory :source do
    name { "Test Source" }
    source_type { "static" }
    base_url { "https://example.com/jobs.json" }
    adapter { "static_json" }
    auth_mode { "none" }
    enabled { true }
  end
end
