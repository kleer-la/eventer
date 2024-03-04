class ServiceAreasController < InheritedResources::Base

  private

  def service_area_params
    params.require(:service_area).permit(:name, :abstract, :visible, :lang)
  end

end
