module CorikaInvoices
  class InvoiceConfigWriter
    attr_accessor :config, :callback

    def initialize(config, callback = nil)
      self.config = config
      self.callback = callback
    end
  end

  def write_invoice(invoice, contact_id, year)

    seller = new CorikaInvoices::Seller()
    seller.from_hash(INVOICE_CONTACT_HASH[contact_id]
    contact = CorikaInvoices::Contact.new(INVOICE_CONTACT_HASH[contact_id])

    self.uuid = SecureRandom.uuid

    if contact.nil?
      Rails.logger.warn('CONTACT is nil! aborting')
      return
    end

    unless contact.valid?
      Rails.logger.warn('Contact is invalid (data missing)')
      return
    end

    FileUtils.mkdir_p config.work_dir unless Dir.exist?(config.work_dir)

    File.open("#{config.work_dir}/variables-#{uuid}.tex", 'w') do |out_file|
      write_our_data(out_file, contact)
      write_common(out_file, invoice.customer)
      callback&.writeAdditionalVars(out_file, invoice)
      out_file.write("\\newcommand{\\jahr}{#{year}}\n")
      out_file.write("\\newcommand{\\renummer}{#{invoice.number}}\n")
      out_file.write("\\newcommand{\\redatum}{#{I18n.l(invoice.invoice_date, format: :long)}}\n")
      out_file.write("\\newcommand{\\zweck}{#{invoice.number}}\n")
      out_file.write("\\newcommand{\\rechnungTyp}{#{invoice.tax_type}}\n")
    end

    pos = 1
    File.open("#{config.work_dir}/posten-#{uuid}.tex", 'w') do |out_file|
      invoice.items.each do |i|
        write_invoice_item(out_file, pos, i)
        Rails.logger.debug("wrote invoice item: #{i.count}x#{i.price}:#{i.label}")
        pos += 1
      end

      sum = format('%.2f', invoice.sum)
      net_sum = format('%.2f', invoice.net_sum)
      tax_sum = format('%.2f', invoice.tax_sum)

      out_file.write("\\InvoiceSum{#{tax_sum}}{#{net_sum}}{#{sum}}\n")
    end
  end

  def write_invoice_item(file, pos, invoice_item)
    count = invoice_item.count
    price = invoice_item.price
    label = tex_escape(invoice_item.label)
    net_price = invoice_item.net_price

    tax_rate = invoice_item.tax_rate

    net_price = 0 if net_price.nil?

    if count.nil? || count.zero?
      Rails.logger.info("omitting #{label} item as count was nil or 0")
      return
    end

    net_amount = format('%.2f', net_price)
    amount = format('%.2f', price)
    total = format('%.2f', (price * count))
    tax_total = format('%.2f', invoice_item.tax_total)

    file.write("\\Item{#{pos}}{#{count}}{#{label}}{#{amount}}{#{net_amount}}{#{total}}{#{tax_rate}}{#{tax_total}}\n")
  end
end