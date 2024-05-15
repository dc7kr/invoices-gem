module CorikaInvoices
  class Invoice
    include Mongoid::Document
    include FileArchiveHelper

    field :number, type: String
    field :invoice_date, type: Date
    field :our_contact, type: String
    field :invoice_type, type: String
    field :tax_type, type: String
    field :pdf_filename, type: String
    field :sepa_filename, type: String
    field :generator_session_id, type: String
    field :booking_year, type: Integer

    embeds_one :customer
    embeds_many :invoice_items, store_as: "items"

    def considerItem(count, price,label)
      if count.nil? or count == 0 then
        return false
      end

      addItem(count,price,label)
    end

    def addItem(count,price,label) 
      item = InvoiceItem.new
      item.count = count
      item.price = price 
      item.label = label   
    
      invoice_items << item
    end

    def net_sum
      sum=0.0
      invoice_items.each do  |item|
        sum+=item.net_total
      end

      sum
    end

    def tax_sum
      tax=0.0

      invoice_items.each do  |item|
        sum+=item.tax_total
      end

      tax
    end

    def sum
      sum=0.0
      invoice_items.each do  |item|
        sum+=item.count*item.price
      end

      sum
    end

    def items
      invoice_items
    end

    def <<(item)
      invoice_items << item
    end

    # TW is either a TexWriter or TexWriterCallback instance
    def gen_pdf(tw=nil)

      invoice_file = nil
      if self.invoice_date.nil? then 
        self.invoice_date = Time.now
      end

      if self.our_contact.nil? then
        Rails.logger.warn("setting contact to default")
        self.our_contact = "default"
      end
     
      year = nil
      if self.booking_year.nil?  
        year = self.invoice_date.year 
      else
        year = self.booking_year
      end

      if self.pdf_filename.nil? then 
        if tw.nil? then 
          tw = CorikaInvoices::TexWriter.new(INVOICE_CONFIG)
        elsif tw.is_a? TexWriterCallback
          tw = CorikaInvoices::TexWriter.new(INVOICE_CONFIG,twc)
        end

        datePrefix = Time.now.strftime '%Y%m%d%H%M%S'

        tw.writeInvoice(self,self.our_contact,year)

        work_pdf_file = tw.gen_pdf(invoice_type,datePrefix, self.customer.customer_id)

        invoice_file = archive_file(INVOICE_CONFIG.work_dir,work_pdf_file,year)


        Rails.logger.debug("Work_pdf: #{invoice_file}")
        Rails.logger.debug("Archived: #{work_pdf_file}")

        if invoice_file.nil? then 
          return nil
        end

        self.pdf_filename = invoice_file.orig_filename
        self.save
      else
        invoice_file = MailingFile.new(self.pdf_filename, self.pdf_filename, year.to_s)
      end

      invoice_file
    end

    def gen_sepa(sepa_writer=nil)
      year = self.invoice_date.year 

      batch = false

      dd_file = nil
      datePrefix = Time.now.strftime '%Y%m%d%H%M%S'

      if sepa_writer.nil? then 
        sepa_writer = SepaWriter.new(datePrefix, INVOICE_CONFIG)
      else 
        batch=true
      end

      # if already generated simply return the file for download
      if not self.sepa_filename.nil? then
        if batch
          return false
        else
          return MailingFile.new(self.sepa_filename, self.sepa_filename, year.to_s)
        end
      end

      if gen_sepa_booking(sepa_writer) then
        if batch 
          return true
        else
          dd_file = sepa_writer.generate_file

          if not dd_file.nil? then
            self.sepa_filename = dd_file.orig_filename 
            self.save
          end
        end
      end

      dd_file
    end

    def make_distinct
      if not Invoice.where(number: self.number).first.nil? then
        suffix = 2;

        number = self.number+"-"+suffix.to_s

        while not Invoice.where(number: number).first.nil?  do
          suffix +=1  
          number = self.number+"-"+suffix.to_s
        end

        self.number = number
      end
    end

    def gen_sepa_booking(sepa_writer)
      dd_file = nil
      if ( self.customer.is_direct_debit? ) then
        sepa_writer.add_direct_debit(self.customer,self.sum,self.number,"RCUR")
        return true
      else
        false
      end
    end

    def has_items?
      invoice_items.length > 0
    end

    def to_yaml
      cust = customer.to_yaml
      contact = invoice.contact.to_yaml
      invoice = invoice.to_yaml

      invoice.to_yaml
    end
  end
end
