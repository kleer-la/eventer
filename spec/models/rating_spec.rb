require 'spec_helper'

describe Rating do

    before(:each) do

		@event_type = FactoryGirl.create(:event_type)
		@country = FactoryGirl.create(:country)

		@event = FactoryGirl.create(:event)
		@event2 = FactoryGirl.create(:event)

		@event.country = @country
		@event2.country = @country

		@trainer = FactoryGirl.create(:trainer)
    @trainer2 = FactoryGirl.create(:trainer2)

		@event.trainer = @trainer
		@event2.trainer = @trainer
    @event.trainer2= @trainer2

		@event.event_type = @event_type
		@event2.event_type = @event_type

		@participant1 = FactoryGirl.build(:participant)
		@participant2 = FactoryGirl.build(:participant)
		@participant3 = FactoryGirl.build(:participant)

		@participant1.id = 101
		@participant2.id = 102
		@participant3.id = 103

		@participant1.status = "A"
		@participant2.status = "A"
		@participant3.status = "A"

		@participant1.event_rating = 5
		@participant2.event_rating = 5
		@participant3.event_rating = 2

		@participant1.trainer_rating = 5
		@participant2.trainer_rating = 5
		@participant3.trainer_rating = 2

    @participant1.trainer2_rating = 4
    @participant2.trainer2_rating = 3

		@participant1.promoter_score = 10
		@participant2.promoter_score = 9
		@participant3.promoter_score = 5

		@participant1.save!
		@participant2.save!
		@participant3.save!

		@event.participants << @participant1
		@event.participants << @participant2
		@event2.participants << @participant3

		@event.save!
		@event2.save!

		Rating.calculate

		@event.reload
		@event2.reload
		@event_type.reload
		@trainer.reload
    @trainer2.reload
    end

    context "for each event" do

	    it "should have an average event rating" do
	      @event.average_rating.should == 5.0
	      @event2.average_rating.should == 2.0
	    end

	    it "should have a global event rating" do
	      Rating.first.global_event_rating.should == 4.0
	    end

	    it "should have an average event rating even with participants without rating" do
	      participant4 = FactoryGirl.build(:participant)
	      participant4.id = 104
	      participant4.status = "A"
	      participant4.save!
	      @event.participants << participant4
	      @event.save!

	      @event.average_rating.should == 5.0
	    end

	    it "should have an average event rating even with participants not being present" do
	      participant4 = FactoryGirl.build(:participant)
	      participant4.id = 104
	      @participant3.event_rating = 5
	      participant4.status = "C"
	      participant4.save!
	      @event.participants << participant4
	      @event.save!

	      @event.average_rating.should == 5.0
	    end

	    it "should have a net promoter score" do
	      @event.net_promoter_score.should == 100
	      @event2.net_promoter_score.should == -100
	    end

	    it "should have a net promoter score even with participants without rating" do
	      participant4 = FactoryGirl.build(:participant)
	      participant4.id = 104
	      participant4.status = "A"
	      participant4.save!
	      @event.participants << participant4
	      @event.save!

	      @event.net_promoter_score.should == 100
	      @event2.net_promoter_score.should == -100
	    end

	    it "should have a net promoter score even with participants not being present" do
	      participant4 = FactoryGirl.build(:participant)
	      participant4.id = 104
	      @participant3.promoter_score = 0
	      participant4.status = "C"
	      participant4.save!
	      @event.participants << participant4
	      @event.save!

	      @event.net_promoter_score.should == 100
	      @event2.net_promoter_score.should == -100
	    end

	end

	context "for the event_type" do

	    it "should have an average event rating" do
	      @event_type.average_rating.should == 4.0
	    end

	    it "should have an average event rating even with participants without rating" do
	      participant4 = FactoryGirl.build(:participant)
	      participant4.id = 104
	      participant4.status = "A"
	      participant4.save!
	      @event.participants << participant4
	      @event.save!

	      @event_type.average_rating.should == 4.0
	    end

	    it "should have an average event rating even with participants not being present" do
	      participant4 = FactoryGirl.build(:participant)
	      participant4.id = 104
	      @participant3.event_rating = 5
	      participant4.status = "C"
	      participant4.save!
	      @event.participants << participant4
	      @event.save!

	      @event_type.average_rating.should == 4.0
	    end

	    it "should have a net promoter score" do
	      @event_type.net_promoter_score.should == 33
	    end

	    it "should have a net promoter score even with participants without rating" do
	      participant4 = FactoryGirl.build(:participant)
	      participant4.id = 104
	      participant4.status = "A"
	      participant4.save!
	      @event.participants << participant4
	      @event.save!

	      @event_type.net_promoter_score.should == 33
	    end

	    it "should have a net promoter score even with participants not being present" do
	      participant4 = FactoryGirl.build(:participant)
	      participant4.id = 104
	      @participant3.promoter_score = 0
	      participant4.status = "C"
	      participant4.save!
	      @event.participants << participant4
	      @event.save!

	      @event_type.net_promoter_score.should == 33
	    end

	end

	context "for the trainer" do

	    it "should have an average event rating" do
	      @trainer.average_rating.should == 4.0
	    end

	    it "should have a global event rating" do
	      Rating.first.global_trainer_rating.should == 4.0
	    end

	    it "should have an average event rating even with participants without rating" do
	      @trainer.average_rating.should == 4.0
	    end

	    it "should have an average event rating even with participants not being present" do
	      @trainer.average_rating.should == 4.0
	    end

	    it "should have a net promoter score" do
	      @trainer.net_promoter_score.should == 33
	    end

	    it "should have a net promoter score even with participants without rating" do
	      @trainer.net_promoter_score.should == 33
	    end

	    it "should have a net promoter score even with participants not being present" do
	      @trainer.net_promoter_score.should == 33
	    end

      it "should have a net promoter score for the co-trainer" do
	      @trainer2.average_rating.should == 3.5
	    end

	end

end
