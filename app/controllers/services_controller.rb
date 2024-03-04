class ServicesController < InheritedResources::Base

  private

    def service_params
      params.require(:service).permit(:name, :card_description, :subtitle, :service_area_id)
    end

end
