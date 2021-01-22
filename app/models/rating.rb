class Rating < ActiveRecord::Base
  belongs_to :user

  def self.calculate( author = User.first )

    rating = Rating.first || Rating.new()

  	rating.user = author

    rating.calculate_global_numbers
    calculate_events_ratings
    calculate_event_type_ratings
    calculate_tainer_settings
  	rating.save!
  end

  def calculate_global_numbers
  	global_promoter_count = Participant.attended.surveyed.promoter.length.to_f
    global_passive_count = Participant.attended.surveyed.passive.length.to_f
    global_detractor_count = Participant.attended.surveyed.detractor.length.to_f
    self.global_nps_count = (global_promoter_count+global_passive_count+global_detractor_count)

    if self.global_nps_count > 0
      global_promoter_percent = global_promoter_count / self.global_nps_count
      global_detractor_percent = global_detractor_count / self.global_nps_count

      self.global_nps = ((global_promoter_percent - global_detractor_percent).round(2)*100).to_i

    else
      self.global_nps = nil
    end

    self.global_event_rating = Participant.attended.surveyed.average("event_rating").to_f.round(2)
    self.global_event_rating_count = Participant.attended.surveyed.count

    self.global_trainer_rating = Participant.attended.surveyed.average("trainer_rating").to_f.round(2)
    self.global_trainer_rating_count = Participant.attended.surveyed.count
  end

  def self.calculate_events_ratings
  	# calculate events ratings
  	Event.select{ |e| e.participants.surveyed.count > 0 }.each do |e|
  		#rating
  		cualified_participants = e.participants.attended.surveyed

	    if cualified_participants.length > 0
	      e.average_rating = cualified_participants.collect{ |p| p.event_rating}.sum.to_f/cualified_participants.length
	    end

  		#nps
  		promoter_count = cualified_participants.promoter.length.to_f
  		passive_count = cualified_participants.passive.length.to_f
  		detractor_count = cualified_participants.detractor.length.to_f
  		attended_count = (promoter_count+passive_count+detractor_count)

  		if (promoter_count+detractor_count) > 0
  		   promoter_percent = promoter_count / attended_count
  		   detractor_percent = detractor_count / attended_count

  		   e.net_promoter_score = ((promoter_percent - detractor_percent).round(2)*100).to_i

  		else
  		   e.net_promoter_score = nil
  		end

  		e.save! unless !e.valid?
  	end
  end

  def self.calculate_event_type_ratings
  	# calculate event_type ratings
  	EventType.select{ |et| et.participants.surveyed.count > 0 }.each do |et|
  		#rating
  		cualified_participants = et.participants.attended.surveyed

	    if cualified_participants.count > 0
	      et.average_rating = cualified_participants.collect{ |p| p.event_rating}.sum.to_f/cualified_participants.length
	      et.surveyed_count = cualified_participants.count
	    end

  		#nps
  		promoter_count = cualified_participants.promoter.length.to_f
  		passive_count = cualified_participants.passive.length.to_f
  		detractor_count = cualified_participants.detractor.length.to_f
  		attended_count = (promoter_count+passive_count+detractor_count)

  		if (promoter_count+detractor_count) > 0
  		   promoter_percent = promoter_count / attended_count
  		   detractor_percent = detractor_count / attended_count
        
  		   et.promoter_count = promoter_count
  		   et.net_promoter_score = ((promoter_percent - detractor_percent).round(2)*100).to_i
  		else
  		   et.net_promoter_score = nil
  		end

  		et.save! unless !et.valid?
  	end
  end

  def self.calculate_tainer_settings
    # calculate trainer ratings
  	Trainer.select{ |tr| tr.participants.surveyed.count > 0 || tr.cotrained_participants.cotrainer_surveyed.count > 0 }.each do |tr|
  		#rating
  		cualified_participants = tr.participants.attended.surveyed
      cualified_cotrained_participants = tr.cotrained_participants.attended.cotrainer_surveyed

      rating_as_trainer_count = cualified_participants.count
      rating_as_cotrainer_count = cualified_cotrained_participants.count
      rating_as_trainer_sum = 0
      rating_as_cotrainer_sum = 0

      if rating_as_trainer_count > 0
        rating_as_trainer_sum = cualified_participants.collect{ |p| p.trainer_rating}.sum.to_f
      end

      if rating_as_cotrainer_count > 0
        rating_as_cotrainer_sum  = cualified_cotrained_participants.collect{ |p| p.trainer2_rating}.sum.to_f
      end

      if rating_as_trainer_count+rating_as_cotrainer_count>0
        tr.surveyed_count = rating_as_trainer_count+rating_as_cotrainer_count
        tr.average_rating = (rating_as_trainer_sum+rating_as_cotrainer_sum) / tr.surveyed_count
      end
      
  		#nps
  		promoter_count = cualified_participants.promoter.length.to_f
  		passive_count = cualified_participants.passive.length.to_f
  		detractor_count = cualified_participants.detractor.length.to_f
  		attended_count = (promoter_count+passive_count+detractor_count)

		  if (promoter_count+detractor_count) > 0
        promoter_percent = promoter_count / attended_count
        detractor_percent = detractor_count / attended_count

        tr.promoter_count = promoter_count
        tr.net_promoter_score = ((promoter_percent - detractor_percent).round(2)*100).to_i
      else
        tr.net_promoter_score = nil
      end

  		tr.save! unless !tr.valid?
  	end

  end
end
