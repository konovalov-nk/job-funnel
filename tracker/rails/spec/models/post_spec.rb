RSpec.describe Post do
  describe "validations" do
    it "is valid with valid attributes" do
      post = Post.new(title: "Hello", body: "World")
      expect(post).to be_valid
    end

    it "is invalid without a title" do
      post = Post.new(title: nil, body: "World")
      expect(post).not_to be_valid
      expect(post.errors[:title]).to include("can't be blank")
    end

    it "is invalid without a body" do
      post = Post.new(title: "Hello", body: nil)
      expect(post).not_to be_valid
      expect(post.errors[:body]).to include("can't be blank")
    end
  end

  describe "factory" do
    it "builds a valid post" do
      expect(build(:post)).to be_valid
    end

    it "creates a persisted post" do
      post = create(:post)
      expect(post).to be_persisted
      expect(post.id).to be_present
    end
  end
end
