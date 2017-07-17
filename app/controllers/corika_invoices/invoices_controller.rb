module CorikaInvoices
  class InvoicesController < ApplicationController

    include FileArchiveHelper

    def index
      @invoices = Invoice.all.page(params[:page]).per(30) 
      respond_to do |format|
        format.html 
        format.js
        format.json { render @invoices, :format=> :json } 
      end
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
        sw = SEPAWriter.new(datePrefix, INVOICE_CONFIG)

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

      if invoice_file.nil? then
        render :text=>"File could not be generated"
      else
        send_file(invoice_file.full_path)
      end
    end

    def gen_for_month
      year = Time.now.year

      if params[:month].nil?
        month= Time.now.month
      else
        month = params[:month].to_i
      end

      tw = TexWriter.new(INVOICE_CONFIG)
      datePrefix = Time.now.strftime '%Y%m%d%H%M%S'
      sw = SEPAWriter.new(datePrefix, INVOICE_CONFIG)

      @domains = Domain.due_in(month)
      sw = SEPAWriter.new(datePrefix, INVOICE_CONFIG)

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
        params[:our_iban] = INVOICE_CONFIG["iban"]
        params[:our_bank] = INVOICE_CONFIG["bank"]
        params[:our_bic]  = INVOICE_CONFIG["bic"]
        params[:creditorId] = INVOICE_CONFIG["creditor_id"]

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
