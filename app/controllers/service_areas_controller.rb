class ServiceAreasController < InheritedResources::Base
  before_action :set_service_area, only: [:show, :edit, :update, :destroy]

  private

  def set_service_area
    @service_area = ServiceArea.friendly.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "The requested service area could not be found."
    redirect_to(service_areas_path)
  end

  def service_area_params
    params.require(:service_area).permit(
      :name, :abstract, :lang, :icon, :primary_color, :secondary_color, :visible, 
      :target_title, :seo_title, :seo_description
    )
  end
end
