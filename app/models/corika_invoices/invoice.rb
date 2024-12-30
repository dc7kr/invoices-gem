module CorikaInvoices
  class Invoice
    include Mongoid::Document
    include Hashify

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
    embeds_many :invoice_items, store_as: 'items'

    def consider_item(count, price, label)
      return false if count.nil? || count.zero?

      add_item(count, price, label)
    end

    def add_item(count, price, label)
      item = InvoiceItem.create(count, price, label)

      invoice_items << item

      item
    end

    def net_sum
      sum = 0.0
      invoice_items.each do |item|
        sum += item.net_total
      end

      sum
    end

    def tax_sum
      tax = 0.0

      invoice_items.each do |item|
        tax += item.tax_total
      end

      tax
    end

    def sum
      sum = 0.0
      invoice_items.each do |item|
        sum += item.count * item.price
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
    def gen_pdf(tex_writer = nil)
      invoice_file = nil
      self.invoice_date = Time.now if invoice_date.nil?

      if our_contact.nil?
        Rails.logger.warn('setting contact to default')
        self.our_contact = 'default'
      end
      year = if booking_year.nil?
               invoice_date.year
             else
               booking_year
             end

      if pdf_filename.nil?
        if tex_writer.nil?
          tex_writer = CorikaInvoices::TexWriter.new(INVOICE_CONFIG)
        elsif tex_writer.is_a? TexWriterCallback
          tex_writer = CorikaInvoices::TexWriter.new(INVOICE_CONFIG, twc)
        end

        date_prefix = Time.now.strftime '%Y%m%d%H%M%S'

        tex_writer.write_invoice(self, our_contact, year)

        work_pdf_file = tex_writer.gen_pdf(invoice_type, date_prefix, customer.customer_id)

        invoice_file = CorikaInvoices::ArchiveFile.from_source_and_year(INVOICE_CONFIG.work_dir, work_pdf_file, year)

        Rails.logger.debug("Work_pdf: #{invoice_file}")
        Rails.logger.debug("Archived: #{work_pdf_file}")

        return nil if invoice_file.nil?

        self.pdf_filename = invoice_file.orig_filename
        save
      else
        invoice_file = CorikaInvoices::ArchiveFile.new(pdf_filename, pdf_filename, year.to_s)
      end

      invoice_file
    end

    def gen_sepa(sepa_writer = nil)
      year = invoice_date.year

      batch = false

      dd_file = nil
      date_prefix = Time.now.strftime '%Y%m%d%H%M%S'

      if sepa_writer.nil?
        sepa_writer = SepaWriter.new(date_prefix, INVOICE_CONFIG)
      else
        batch = true
      end

      # if already generated simply return the file for download
      unless sepa_filename.nil?
        return false if batch

        return CorikaInvoices::ArchiveFile.new(sepa_filename, sepa_filename, year.to_s)

      end

      if gen_sepa_booking(sepa_writer)
        return true if batch

        dd_file = sepa_writer.generate_file

        unless dd_file.nil?
          self.sepa_filename = dd_file.orig_filename
          save
        end

      end

      dd_file
    end

    def make_distinct
      return if Invoice.where(number: number).first.nil?

      suffix = 2

      number = "#{self.number}-#{suffix}"

      until Invoice.where(number: number).first.nil?
        suffix += 1
        number = "#{self.number}-#{suffix}"
      end

      self.number = number
    end

    def gen_sepa_booking(sepa_writer)
      if customer.direct_debit?
        sepa_writer.add_direct_debit(customer, sum, number, 'RCUR')
        true
      else
        false
      end
    end

    def items?
      invoice_items.length.positive?
    end

    def to_yaml
      customer.to_yaml
      invoice.contact.to_yaml
      invoice = invoice.to_yaml

      invoice.to_yaml
    end
  end
end
