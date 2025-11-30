require 'yaml'
module CorikaInvoices
  class Invoice
    include Mongoid::Document
    include Hashify

    field :number, type: String
    field :invoice_date, type: Date
    field :tax_mode, type: String
    field :typecode, type: Integer
    field :seq_nr, type: Integer
    field :pdf_filename, type: String
    field :sepa_filename, type: String
    field :generator_session_id, type: String
    field :booking_year, type: Integer
    field :reference_id, type: String
    field :reference_type, type: String
    field :exemption_reason, type: String
    field :locale, type: String
    field :template, type: String
    field :template_subdir, type: String

    embeds_one :customer
    embeds_one :contact
    embeds_many :invoice_items, store_as: 'items'

    def initialize
      super
      # "normal invoice" by default
      self.typecode = 380
      self.locale = 'de'
      self.seq_nr = CorikaInvoices::Invoice.max(:seq_nr) + 1
    end

    def full_number
      "#{seq_nr}-#{number}"
    end

    def consider_item(count, price, label)
      return nil if count.nil? || count.zero?

      add_item(count, price, label)
    end

    def add_item(count, price, label, unit_code = 'C62', _p_tax_rate = INVOICE_CONFIG.taxrate, p_tax_mode = tax_mode)
      item = InvoiceItem.create(count, price, label, unit_code, INVOICE_CONFIG.taxrate, p_tax_mode)

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
        sum += item.total
      end

      sum
    end

    def items
      invoice_items
    end

    def <<(item)
      invoice_items << item
    end

    def gen_pdf
      invoice_file = nil
      self.invoice_date = Time.now if invoice_date.nil?

      year = if booking_year.nil?
               invoice_date.year
             else
               booking_year
             end

      if pdf_filename.nil?

        to_yaml

        date_prefix = Time.now.strftime '%Y%m%d%H%M%S'
        pdf_generator = CorikaInvoices::PdfGenerator.new(INVOICE_CONFIG)

        work_pdf_file = pdf_generator.gen_pdf(self)
        # content: <uuid>.pdf

        target_file_name = "#{date_prefix}_#{seq_nr}_#{number}.pdf"

        Rails.logger.debug("Work_pdf: #{work_pdf_file}")

        pdf_generator.archive_generated_file(work_pdf_file, target_file_name, year)

        return nil if work_pdf_file.nil?

        invoice_file = CorikaInvoices::ArchiveFile.new(target_file_name, target_file_name, year.to_s)

        Rails.logger.debug("Archived: #{work_pdf_file}->#{invoice_file.full_path}")

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

    def to_hash
      retval = {
        invoice: {
          date: I18n.l(invoice_date, format: :long), # "02. Juli 2025"
          year: booking_year,
          locale: locale,
          number: full_number,
          zweck: number,
          tax_mode: tax_mode,
          typecode: typecode,
          template: template,
          template_subdir: template_subdir
        }
      }

      h_invoice = retval[:invoice]

      h_invoice[:exemption_reason] = I18n.t('invoice.exemption_reason') if tax_mode == 'E'

      unless reference_id.nil?
        h_invoice[:reference_id] = reference_id
        h_invoice[:reference_type] = reference_type
      end


      h_contact = contact.to_hash

      h_invoice[:me] = h_contact

      h_items = []
      invoice_items.each do |item|
        h_items << item.to_hash
      end

      customer_hash = customer.to_hash
      h_invoice[:customer] = customer_hash

      h_invoice[:items] = h_items

      grand_total = 0
      line_total = 0
      tax = 0
      tax_basis = 0
      taxes = {}

      invoice_items.each do |item|
        grand_total += item.total + item.tax
        line_total += item.total

        tax += item.tax

        if taxes[item.tax_rate].nil?
          taxes[item.tax_rate] = {
            rate: item.tax_rate,
            sum: 0,
            basis: 0
          }
        end

        taxes[item.tax_rate][:sum] += item.tax
        taxes[item.tax_rate][:basis] += item.total
        tax_basis += item.total
      end

      h_invoice[:sum] = {
        grand_total: grand_total,
        due_payable: grand_total,
        line_total: line_total,
        tax: tax,
        tax_basis: tax_basis,
        taxes: taxes.values
      }

      retval
    end

    def to_yaml
      invoice_hash = to_hash

      CorikaInvoices::YamlCleaningVisitor.clean(invoice_hash)
    end
  end
end
