class Invoice
  include Mongoid::Document
  include FileArchiveHelper

  field :number, type: String
  field :invoice_date, type: Date
  field :invoice_type, type: String
  field :pdf_filename, type: String
  field :sepa_filename, type: String

  embeds_one :customer, class_name: "InvoiceCustomer"
  embeds_many :invoice_items, store_as: "items"


  def addItem(count,price,label) 
    item = InvoiceItem.new
    item.count = count
    item.price = price 
    item.label = label   
  
    invoice_items << item
  end

  def net_sum
    sum/1.19
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


  def gen_pdf(tw=nil)

    invoice_file = nil
    year = self.invoice_date.year 

    if self.pdf_filename.nil? then 
      if tw.nil? then 
        tw = TexWriter.new(CORIKA_SETTINGS)
      end
      datePrefix = Time.now.strftime '%Y%m%d%H%M%S'

      tw.writeInvoice(self,"gs",year)

      work_pdf_file = tw.gen_pdf(invoice_type,datePrefix, self.customer.customer_id)

      invoice_file = archive_file(tw.workdir,work_pdf_file,year)

      self.pdf_filename = invoice_file.orig_filename
      self.save
    else
      invoice_file = MailingFile.new(self.pdf_filename, self.pdf_filename, year.to_s)
    end

    invoice_file
  end

  def gen_sepa
    year = self.invoice_date.year 

    dd_file = nil

    if self.sepa_filename.nil? then
      datePrefix = Time.now.strftime '%Y%m%d%H%M%S'
      sw = SEPAWriter.new(datePrefix, CORIKA_SETTINGS)

      if ( invoice.customer.is_direct_debit? ) then
        sw.addBooking(invoice.customer,invoice.sum,invoice.number,"RCUR")
      end

      dd_file = sw.generateFile

      self.sepa_file = dd_file.orig_filename 
      self.save
    else
      dd_file = MailingFile.new(self.sepa_filename, self.sepa_filename, year.to_s)
    end

    dd_file
  end
end
