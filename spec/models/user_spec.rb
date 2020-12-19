require 'spec_helper'
require 'cancan/matchers'

describe User do
  
  context "If it's an administrator" do
    
    before(:each) do
      @admin = Ability.new ( FactoryGirl.create(:administrator) )
    end
  
    it { expect(@admin).to be_able_to(:manage, Role.new)}
    it { expect(@admin).to be_able_to(:manage, User.new)}
    it { expect(@admin).to be_able_to(:manage, Event.new)}
    it { expect(@admin).to be_able_to(:manage, Trainer.new)}
    it { expect(@admin).to be_able_to(:manage, Category.new)}    
  end
  
  context "If it's a comercial person" do

    before(:each) do
      @comercial = Ability.new ( FactoryGirl.create(:comercial) )
    end

    it { expect(@comercial).not_to be_able_to(:manage, Role.new)}
    it { expect(@comercial).not_to be_able_to(:manage, User.new)}
    it { expect(@comercial).to be_able_to(:manage, Event.new)}
    it { expect(@comercial).not_to be_able_to(:manage, EventType.new)}
    it { expect(@comercial).not_to be_able_to(:manage, Category.new)}
    it { expect(@comercial).not_to be_able_to(:manage, Trainer.new)}  
  end

end
