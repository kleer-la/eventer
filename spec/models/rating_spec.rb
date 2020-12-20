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
      expect(@event.average_rating).to eq 5.0
      expect(@event2.average_rating).to eq 2.0
    end

    it "should have a global event rating" do
      expect(Rating.first.global_event_rating).to eq 4.0
    end

    it "should have an average event rating even with participants without rating" do
      expect(@event.average_rating).to eq 5.0
    end

    it "should have an average event rating even with participants not being present" do
      expect(@event.average_rating).to eq 5.0
    end

    it "should have a net promoter score" do
      expect(@event.net_promoter_score).to eq 100
      expect(@event2.net_promoter_score).to eq -100
    end

    it "should have a net promoter score even with participants without rating" do
      expect(@event.net_promoter_score).to eq 100
      expect(@event2.net_promoter_score).to eq -100
    end

    it "should have a net promoter score even with participants not being present" do
      expect(@event.net_promoter_score).to eq 100
      expect(@event2.net_promoter_score).to eq -100
    end

	end

	context "for the event_type" do

    it "should have an average event rating" do
      expect(@event_type.average_rating).to eq 4.0
    end

    it "should have an average event rating even with participants without rating" do
      expect(@event_type.average_rating).to eq 4.0
    end

    it "should have an average event rating even with participants not being present" do
      expect(@event_type.average_rating).to eq 4.0
    end

    it "should have a net promoter score" do
      expect(@event_type.net_promoter_score).to eq 33
    end

    it "should have a net promoter score even with participants without rating" do
      expect(@event_type.net_promoter_score).to eq 33
    end

    it "should have a net promoter score even with participants not being present" do
      expect(@event_type.net_promoter_score).to eq 33
    end

	end

	context "for the trainer" do

    it "should have an average event rating" do
      expect(@trainer.average_rating).to eq 4.0
    end

    it "should have a global event rating" do
      expect(Rating.first.global_trainer_rating).to eq 4.0
      # expect(Rating.first.global_trainer_rating).to eq 3.8
    end

    it "should have an average event rating even with participants without rating" do
      expect(@trainer.average_rating).to eq 4.0
    end

    it "should have an average event rating even with participants not being present" do
      expect(@trainer.average_rating).to eq 4.0
    end

    it "should have a net promoter score" do
      expect(@trainer.net_promoter_score).to eq 33
    end

    it "should have a net promoter score even with participants without rating" do
      expect(@trainer.net_promoter_score).to eq 33
    end

    it "should have a net promoter score even with participants not being present" do
      expect(@trainer.net_promoter_score).to eq 33
    end

    it "should have a net promoter score for the co-trainer" do
      expect(@trainer2.average_rating).to eq 3.5
    end

	end

end
