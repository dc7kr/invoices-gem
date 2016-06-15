module CorikaInvoices
  class InvoiceCustomersController < ApplicationController

    include FileArchiveHelper

    def index
      @invoices = InvoiceCustomer.all

    end

    def show
      @invoice_customer = InvoiceCustomer.find(params[:id])
    end
  end
end
