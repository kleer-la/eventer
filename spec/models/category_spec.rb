require 'rails_helper'

describe Category do
  it { should have_and_belong_to_many(:event_types) }
  
  before(:each) do
    @category = FactoryBot.build(:category)
  end
  
  it "should be valid" do
    expect(@category.valid?).to be true
  end
  
  it "should require its name" do
    @category.name = ""
    
    expect(@category.valid?).to be false
  end
  
  it "should require its description" do
    @category.description = ""
    
    expect(@category.valid?).to be false
  end
  
  it "should require its tagline" do
    @category.tagline = ""
    
    expect(@category.valid?).to be false
  end
  
  it "should have a visibility flag" do
    @category.visible = false
    
    expect(@category.visible).to be false
  end
  
  it "should have an order index" do
    @category.order = 1
    
    expect(@category.order).to eq 1
  end
  
  it "should require its codename" do
    @category.codename = ""
    
    expect(@category.valid?).to be false
  end

  it "should get " do
    biz = FactoryBot.build(:category)
    
    tec = FactoryBot.build(:category)
    tec.codename = "TEC"
    
    csm = FactoryBot.build(:event_type)
    csm.categories << biz
    csm.save!
    
    kanban = FactoryBot.build(:event_type)
    kanban.categories << biz
    kanban.save!
    
    tdd = FactoryBot.build(:event_type)
    tdd.categories << tec
    tdd.save!
    
    expect(biz.event_types.count).to eq 2
  end
  
  it "should have a visible scope" do
    cat1 = FactoryBot.build(:category)
    cat1.visible = true
    cat1.save!
    
    cat2 = FactoryBot.build(:category)
    cat2.visible = true
    cat2.save!
    
    cat3 = FactoryBot.build(:category)
    cat3.visible = false
    cat3.save!
    
    expect(Category.all.count).to eq 3
    expect(Category.visible_ones.count).to eq 2
  end
  
end
