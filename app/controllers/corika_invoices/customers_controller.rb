module CorikaInvoices
  #  NOTE: inherits from CorikaInvoices::ApplicationController 
  class CustomersController < ApplicationController

    include FileArchiveHelper

    def index
      @invoices = Customer.all

    end

    def show
      @invoice_customer = Customer.find(params[:id])
    end
  end
end
