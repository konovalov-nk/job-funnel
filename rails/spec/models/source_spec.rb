RSpec.describe Source do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:source)).to be_valid
    end

    it "is invalid without a name" do
      source = build(:source, name: nil)
      expect(source).not_to be_valid
      expect(source.errors[:name]).to include("can't be blank")
    end

    it "is invalid without a source_type" do
      source = build(:source, source_type: nil)
      expect(source).not_to be_valid
      expect(source.errors[:source_type]).to include("can't be blank")
    end

    it "is invalid with an unknown source_type" do
      source = build(:source, source_type: "unknown")
      expect(source).not_to be_valid
      expect(source.errors[:source_type]).to include("is not included in the list")
    end

    it "is invalid without a base_url" do
      source = build(:source, base_url: nil)
      expect(source).not_to be_valid
      expect(source.errors[:base_url]).to include("can't be blank")
    end

    it "is invalid without an adapter" do
      source = build(:source, adapter: nil)
      expect(source).not_to be_valid
      expect(source.errors[:adapter]).to include("can't be blank")
    end

    it "is invalid with an unknown adapter" do
      source = build(:source, adapter: "unknown")
      expect(source).not_to be_valid
      expect(source.errors[:adapter]).to include("is not included in the list")
    end

    it "is invalid without an auth_mode" do
      source = build(:source, auth_mode: nil)
      expect(source).not_to be_valid
      expect(source.errors[:auth_mode]).to include("can't be blank")
    end

    it "is invalid with an unknown auth_mode" do
      source = build(:source, auth_mode: "unknown")
      expect(source).not_to be_valid
      expect(source.errors[:auth_mode]).to include("is not included in the list")
    end
  end

  describe "defaults" do
    it "defaults enabled to true" do
      source = Source.new
      expect(source.enabled).to be true
    end
  end

  describe "associations" do
    it "has many fetch_runs" do
      source = create(:source)
      fetch_run = create(:fetch_run, source: source)
      expect(source.fetch_runs).to include(fetch_run)
    end

    it "destroys fetch_runs when destroyed" do
      source = create(:source)
      create(:fetch_run, source: source)
      expect { source.destroy }.to change(FetchRun, :count).by(-1)
    end
  end

  describe "persistence" do
    it "persists a valid source" do
      source = create(:source)
      expect(source).to be_persisted
      expect(source.id).to be_present
    end
  end
end
