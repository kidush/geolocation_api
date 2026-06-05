class GeolocationsController < ApplicationController
  def index
    if lookup_params.values.any?(&:present?)
      render_jsonapi(Geolocations::Finder.new(**lookup_params).call)
    else
      render_jsonapi(Geolocation.order(:id))
    end
  end

  def create
    record = Geolocations::Create.new(**create_params).call
    render_jsonapi(record, status: :created)
  end

  def destroy
    require_lookup_params!
    Geolocations::Finder.new(**lookup_params).call.destroy!
    head :no_content
  end

  private

  def create_params
    attributes = params[:data].is_a?(ActionController::Parameters) ? params.dig(:data, :attributes) : nil
    attributes = params unless attributes.is_a?(ActionController::Parameters)

    { ip: attributes[:ip].presence, url: attributes[:url].presence }
  end

  def lookup_params
    { ip: params[:ip].presence, url: params[:url].presence }
  end

  def require_lookup_params!
    return if lookup_params.values.any?(&:present?)

    raise ActionController::ParameterMissing.new(:ip), "param is missing or the value is empty: provide ip or url"
  end
end
