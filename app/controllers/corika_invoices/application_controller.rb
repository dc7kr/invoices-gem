module CorikaInvoices
  class ApplicationController < ActionController::Base
    def current_user
      current_admin
    end
  end
end
