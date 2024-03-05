class ServiceAreasController < InheritedResources::Base

  def show
    @service_area = ServiceArea.friendly.find(params[:id])
  end
  
  private

  def service_area_params
    params.require(:service_area).permit(:name, :abstract, :visible, :lang)
  end

end
