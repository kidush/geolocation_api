class ErrorsController < ApplicationController
  skip_before_action :authenticate!

  def not_found
    render_error(status: :not_found, title: "Not Found",
                 detail: "No route matches #{request.path}")
  end
end
