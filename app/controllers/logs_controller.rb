# frozen_string_literal: true

class LogsController < ApplicationController
  def index
    @logs = Log.order(created_at: :desc)
  end

  def show
    @log = Log.find(params[:id])
  end
end
