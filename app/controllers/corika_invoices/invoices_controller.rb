module CorikaInvoices
  #  NOTE: inherits from CorikaInvoices::ApplicationController
  class InvoicesController < ApplicationController
    include FileArchiveHelper

    def index
      @invoices = Invoice.all.page(params[:page]).per(30)
      respond_to do |format|
        format.html
        format.js
        format.json { render @invoices, format: :json }
      end
    end

    def generation; end

    def show
      @invoice = Invoice.find(params[:id])
    end

    def gen_sepa
      invoice = Invoice.find(params[:id])
      year = invoice.invoice_date.year

      dd_file = nil

      if invoice.sepa_filename.nil?
        dd_file = invoice.gen_sepa

        if !dd_file.nil?
          invoice.sepa_filename = dd_file.orig_filename
          invoice.save
        else
          Rails.logger.error('SEPA file could not be generated')

          redirect_to invoices_path, notice: 'SEPA file could not be created'
          return
        end

      else
        dd_file = MailingFile.new(invoice.sepa_filename, invoice.pdf_filename, year.to_s)
      end

      send_file(dd_file.full_path)
    end

    def gen_pdf
      @invoice = Invoice.find(params[:id])

      invoice_file = @invoice.gen_pdf

      if invoice_file.nil?
        render text: 'File could not be generated'
      else
        send_file(invoice_file.full_path)
      end
    end

    def translated_salutation(customer)
      gender = if customer.anrede.zero?
                 'M'
               else
                 'F'
               end

      t("common.salutations.#{gender}", name: customer.name)
    end
  end
end
