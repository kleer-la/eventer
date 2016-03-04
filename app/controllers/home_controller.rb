class HomeController < ApplicationController
  def index
    @events = Event.public_commercial_visible.all(:order => 'date')
    respond_to do |format|
      format.html
      format.xml { render :xml => @events.to_xml( :include => {
                                                    :country => {},
                                                    :event_type => {},
                                                    :trainer => {},
                                                    :trainer2 => {},
                                                    :trainers => {},
                                                    :categories => {}
                                                  },
                                                  :methods => [:human_date, :is_webinar]
                                                ) }
      format.json { render json: @events }
    end
  end

  def index_community
    @events = Event.public_community_visible.all(:order => 'date')
    respond_to do |format|
      format.html
      format.xml { render :xml => @events.to_xml(:include => {
                                                    :country => {},
                                                    :event_type => {},
                                                    :trainer => {},
                                                    :trainer2 => {},
                                                    :trainers => {},
                                                    :categories => {}
                                                  },
                                                  :methods => [:human_date, :is_webinar]
                                                ) }
      format.json { render json: @events }
    end
  end

  def show
    @event = Event.public_and_visible.find(params[:id])
    respond_to do |format|
      format.xml { render :xml => @event.to_xml(:include => {
                                                    :country => {},
                                                    :event_type => {},
                                                    :trainer => {},
                                                    :trainer2 => {},
                                                    :trainers => {},
                                                    :categories => {}
                                                  },
                                                  :methods => [:human_date, :is_webinar]
                                                ) }
      format.json { render json: @event }
    end
  end

  def trainers
    @trainers = Trainer.all(:order => ['country_id','name'])
    respond_to do |format|
      format.html
      format.xml { render :xml => @trainers.to_xml(:include => :country ) }
      format.json { render json: @trainers }
    end
  end

  def kleerers
    @trainers = Trainer.kleerer.all(:order => ['country_id','name'])
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

end
