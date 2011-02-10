require File.expand_path('../../spec_helper', __FILE__)

describe ActsAsTaggableOn::Tag do
  before(:each) do
    clean_database!
    @tag = ActsAsTaggableOn::Tag.new
    @user = TaggableModel.create(:name => "Pablo")
    OtherTaggableModel
  end

  describe "named like any" do
    before(:each) do
      ActsAsTaggableOn::Tag.create(:name => "awesome")
      ActsAsTaggableOn::Tag.create(:name => "epic")
    end

    it "should find both tags" do
      ActsAsTaggableOn::Tag.named_like_any(["awesome", "epic"]).should have(2).items
    end
  end

  describe "find or create by name" do
    before(:each) do
      @tag.name = "awesome"
      @tag.save
    end

    it "should find by name" do
      ActsAsTaggableOn::Tag.find_or_create_with_like_by_name("awesome").should == @tag
    end

    it "should find by name case insensitive" do
      ActsAsTaggableOn::Tag.find_or_create_with_like_by_name("AWESOME").should == @tag
    end

    it "should create by name" do
      lambda {
        ActsAsTaggableOn::Tag.find_or_create_with_like_by_name("epic")
      }.should change(ActsAsTaggableOn::Tag, :count).by(1)
    end
  end
  
  describe 'find or create by name with scope' do
    before(:each) do
      @tag_scope = OtherTaggableModel.create(:name => "SCOPED")
      @other_tag_scope = OtherTaggableModel.create(:name => 'other scoped')
    end
    
    it 'should create with scope' do
      tag = ActsAsTaggableOn::Tag.new(:name => 'taged rad aesome')
      tag.scoped = @tag_scope
      tag.save!
      tag.scoped_id.should be_present
      tag.scoped_type.should be_present
    end

    it "should find or create by name without scope" do
      lambda {
        ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name(["awesome"])
      }.should change(ActsAsTaggableOn::Tag, :count).by(1)
    end
    
    it 'should find or create by name with scope' do
      lambda {
        ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name(["awesome"], @tag_scope)
      }.should change(ActsAsTaggableOn::Tag.with_tag_scope(@tag_scope), :count).by(1)            
    end    

    it "should find or create by name with multiple scopes" do
      lambda {
        ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name(["awesome"], @tag_scope)
      }.should change(ActsAsTaggableOn::Tag.with_tag_scope(@tag_scope), :count).by(1)      
      
      lambda {
        ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name(["awesome"], @other_tag_scope)
      }.should change(ActsAsTaggableOn::Tag.with_tag_scope(@other_tag_scope), :count).by(1)                        
    end

    it "should find or create by name with multiple scopes not messing with others" do
      lambda {
        ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name(["awesome"], @tag_scope)
      }.should change(ActsAsTaggableOn::Tag.with_tag_scope(@other_tag_scope), :count).by(0)
      
      lambda {
        ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name(["awesome"], @other_tag_scope)
      }.should change(ActsAsTaggableOn::Tag.with_tag_scope(@tag_scope), :count).by(0)                        
    end    
  end

  describe "find or create all by any name" do
    before(:each) do
      @tag.name = "awesome"
      @tag.save
    end

    it "should find by name" do
      ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name("awesome").should == [@tag]
    end

    it "should find by name case insensitive" do
      ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name("AWESOME").should == [@tag]
    end

    it "should create by name" do
      lambda {
        ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name("epic")
      }.should change(ActsAsTaggableOn::Tag, :count).by(1)
    end

    it "should find or create by name, stripping whitespace" do
      lambda {
        ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name(["  awesome ", " epic      "]).map(&:name).should == ["awesome", "epic"]
      }.should change(ActsAsTaggableOn::Tag, :count).by(1)
    end

    it "should return an empty array if no tags are specified" do
      ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name([]).should == []
    end
  end

  it "should require a name" do
    @tag.valid?
    
    if ActiveRecord::VERSION::MAJOR >= 3
      @tag.errors[:name].should == ["can't be blank"]
    else
      @tag.errors[:name].should == "can't be blank"
    end

    @tag.name = "something"
    @tag.valid?
    
    if ActiveRecord::VERSION::MAJOR >= 3      
      @tag.errors[:name].should == []
    else
      @tag.errors[:name].should be_nil
    end
  end

  it "should equal a tag with the same name" do
    @tag.name = "awesome"
    new_tag = ActsAsTaggableOn::Tag.new(:name => "awesome")
    new_tag.should == @tag
  end

  it "should return its name when to_s is called" do
    @tag.name = "cool"
    @tag.to_s.should == "cool"
  end

  it "have named_scope named(something)" do
    @tag.name = "cool"
    @tag.save!
    ActsAsTaggableOn::Tag.named('cool').should include(@tag)
  end

  it "have named_scope named_like(something)" do
    @tag.name = "cool"
    @tag.save!
    @another_tag = ActsAsTaggableOn::Tag.create!(:name => "coolip")
    ActsAsTaggableOn::Tag.named_like('cool').should include(@tag, @another_tag)
  end
end
