RSpec.describe FetchRun do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:fetch_run)).to be_valid
    end

    it "is invalid without a source" do
      fetch_run = build(:fetch_run, source: nil)
      expect(fetch_run).not_to be_valid
      expect(fetch_run.errors[:source]).to include("must exist")
    end

    it "is invalid without an adapter" do
      fetch_run = build(:fetch_run, adapter: nil)
      expect(fetch_run).not_to be_valid
      expect(fetch_run.errors[:adapter]).to include("can't be blank")
    end

    it "is invalid with an unknown status" do
      fetch_run = build(:fetch_run, status: "unknown")
      expect(fetch_run).not_to be_valid
      expect(fetch_run.errors[:status]).to include("is not included in the list")
    end

    it "is invalid with a negative retry_count" do
      fetch_run = build(:fetch_run, retry_count: -1)
      expect(fetch_run).not_to be_valid
      expect(fetch_run.errors[:retry_count]).to include("must be greater than or equal to 0")
    end
  end

  describe "defaults" do
    it "defaults retry_count to 0" do
      fetch_run = FetchRun.new
      expect(fetch_run.retry_count).to eq 0
    end

    it "defaults status to new" do
      fetch_run = FetchRun.new
      expect(fetch_run.status).to eq "new"
    end
  end

  describe "associations" do
    it "belongs to source" do
      source = create(:source)
      fetch_run = create(:fetch_run, source: source)
      expect(fetch_run.source).to eq source
    end
  end

  describe "creation for enabled source" do
    it "creates a new FetchRun with status new and retry_count 0" do
      source = create(:source)
      fetch_run = create(:fetch_run, source: source)
      expect(fetch_run.status).to eq "new"
      expect(fetch_run.retry_count).to eq 0
      expect(fetch_run).to be_persisted
    end
  end
end
