FactoryBot.define do
  factory :fetch_run do
    source
    adapter { source&.adapter || "static_json" }
    retry_count { 0 }
    status { "new" }
  end
end
