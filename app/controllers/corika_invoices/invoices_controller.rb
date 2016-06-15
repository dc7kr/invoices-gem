module CorikaInvoices
  class InvoicesController < ApplicationController

    include FileArchiveHelper

    def index
      @invoices = Invoice.all
    end

    def generation
          
    end

    def show
      @invoice = Invoice.find(params[:id])
    end

    def gen_sepa
      invoice = Invoice.find(params[:id])
      year = invoice.invoice_date.year 

      dd_file = nil

      if invoice.sepa_filename.nil? then
        datePrefix = Time.now.strftime '%Y%m%d%H%M%S'
        sw = SEPAWriter.new(datePrefix, CORIKA_SETTINGS)

        if ( invoice.customer.is_direct_debit? ) then
          sw.addBooking(invoice.customer,invoice.sum,invoice.number,"RCUR")
        end

        dd_file = sw.generateFile

        invoice.sepa_filename = dd_file.orig_filename 
        invoice.save
      else
        dd_file = MailingFile.new(invoice.sepa_filename, invoice.pdf_filename, year.to_s)
      end

      send_file(dd_file.full_path)
    end

    def gen_pdf
      @invoice = Invoice.find(params[:id])

      invoice_file = @invoice.gen_pdf

      send_file(invoice_file.full_path)
    end

    def gen_for_month
      year = Time.now.year

      if params[:month].nil?
        month= Time.now.month
      else
        month = params[:month].to_i
      end

      tw = TexWriter.new(CORIKA_SETTINGS)
      datePrefix = Time.now.strftime '%Y%m%d%H%M%S'
      sw = SEPAWriter.new(datePrefix, CORIKA_SETTINGS)

      @domains = Domain.due_in(month)
      sw = SEPAWriter.new(datePrefix, CORIKA_SETTINGS)

      @domains.each do |domain|
        invoice = domain.gen_invoice(month)
        if ( domain.customer.is_direct_debit? ) then
          sw.addBooking(invoice.customer,invoice.sum,invoice.number,"RCUR")
        end

        invoice_file = invoice.gen_pdf(tw)

        interval = domain.tariff.interval-1
        to = Date.new(year,month,1)+interval.month

        customer = domain.customer

        params[:salutation] = translated_salutation(customer)
        params[:domain]  = domain.domain
        params[:from] = "#{month}/#{year}"
        params[:to] = "#{to.month}/#{to.year}"
        params[:directDebit] = customer.is_direct_debit?
        params[:iban] = customer.iban
        params[:bic] = customer.bic
        params[:mandateRef] = customer.mandate_id
        params[:renr] = invoice.number
        params[:our_iban] = CORIKA_SETTINGS["iban"]
        params[:our_bank] = CORIKA_SETTINGS["bank"]
        params[:our_bic]  = CORIKA_SETTINGS["bic"]
        params[:creditorId] = CORIKA_SETTINGS["creditor_id"]

        InvoiceMailer.notify(domain.customer.email,invoice_file, nil, params).deliver
      end

      dd_file = sw.generateFile
    end

    def translated_salutation(customer)

      gender = nil
      if (customer.anrede == 0 ) then
        gender ="M"
      else
        gender="F"
      end

      t("common.salutations.#{gender}",:name => customer.name)
    end
  end
end
