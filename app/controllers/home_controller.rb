class HomeController < ApplicationController
  def index
    @events = Event.public_courses
    respond_to do |format|
      format.html
      format.xml { render :xml => @events.to_xml( :include => event_data_to_include,
                                                  :methods => [:human_date]
                                                ) }
      format.json { render json: @events.to_json( :include => event_data_to_include,
                                                  :methods => [:human_date]
      ) }
    end
  end

  def event_by_event_type
    @events = Event.public_commercial_visible.select{|event| event.event_type.id == params[:id].to_i}.sort_by { |event| event.date }
    respond_to do |format|
      format.html
      format.xml { render :xml => @events.to_xml( :include => event_data_to_include,
                                                  :methods => [:human_date]
      ) }
      format.json { render json: @events.to_json( :include => event_data_to_include,
                                                 :methods => [:human_date]
      )}
    end
  end

  def index_community
    @events = Event.public_community_visible.all(:order => 'date')
    respond_to do |format|
      format.html
      format.xml { render :xml => @events.to_xml(:include => event_data_to_include,
                                                  :methods => [:human_date]
                                                ) }
      format.json { render json: @events.to_json( :include => event_data_to_include,
                                                  :methods => [:human_date]
      )}
    end
  end

  def show
    @event = Event.public_and_visible.find(params[:id])
    respond_to do |format|
      format.xml { render :xml => @event.to_xml(:include => event_data_to_include,
                                                  :methods => [:human_date]
                                                ) }
      format.json { render json: @event.to_json( :include => event_data_to_include,
                                                  :methods => [:human_date]
      )}
    end
  end

  def trainers
    @trainers = Trainer.order('country_id','name')
    respond_to do |format|
      format.html
      format.xml { render :xml => @trainers.to_xml(:include => :country ) }
      format.json { render json: @trainers }
    end
  end

  def kleerers
    @trainers = Trainer.kleerer.order('country_id','name')
    respond_to do |format|
      format.xml { render :xml => @trainers.to_xml(:include => :country ) }
      format.json { render json: @trainers }
    end
  end

  def categories
    @categories = Category.visible_ones
    respond_to do |format|
      format.xml { render :xml => @categories.to_xml(:include => {:event_types  => {} } ) }
      format.json { render json: @categories }
    end
  end

  # GET /event_types/1
  # GET /event_types/1.json
  def event_type_show
    @event_type = EventType.find(params[:id])

    respond_to do |format|
      format.json { render json: @event_type }
      format.xml { render :xml => @event_type.to_xml( { :include => :categories } ) }
    end
  end

  # GET /event_types
  # GET /event_types.json
  def event_type_index
    @event_types = EventType.all.sort{|p1,p2| p1.name <=> p2.name}

    respond_to do |format|
      format.json { render json: @event_types }
      format.xml { render :xml => @event_types.to_xml( { :include => :categories } ) }
    end
  end

  def show_event_type_trainers
    @event_type = EventType.find(params[:id])

    respond_to do |format|
      format.xml { render xml: @event_type.trainers }
    end
  end

  private

  def event_data_to_include
      return {
        :country => {},
        :event_type => {},
        :trainer => {},
        :trainer2 => {},
        :trainers => {},
        :categories => {}
    }
  end

end
