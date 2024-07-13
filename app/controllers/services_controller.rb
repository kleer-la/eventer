class ServicesController < InheritedResources::Base
  before_action :set_service, only: %i[show edit update destroy]

  private

  def set_service
    @service = Service.friendly.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = 'The requested service area could not be found.'
    redirect_to(services_path)
  end

  def service_params
    params.require(:service).permit(:name, :card_description, :subtitle, :service_area_id)
  end
end
