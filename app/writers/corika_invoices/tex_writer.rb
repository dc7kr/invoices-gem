module CorikaInvoices
  class TexWriter
    attr_accessor :config, :callback

    include ApplicationHelper
    include ActionView::Helpers::NumberHelper

    def initialize(config, callback = nil)
      throw :invoice_work_dir_nil if config.work_dir.nil?

      throw :invoice_tool_dir_nil if config.tool_dir.nil?

      self.config = config

      if !callback.nil?
        self.callback = callback
      else
        klass = Module.const_get('TexWriterCallback')
        self.callback = Object.const_get('TexWriterCallback').new if klass.is_a?(Class)
      end
    end

    def write_invoice(invoice, contact_id, year)
      contact = CorikaInvoices::Contact.new(INVOICE_CONTACT_HASH[contact_id])

      if contact.nil?
        Rails.logger.warn('CONTACT is nil! aborting')
        return
      end

      unless contact.valid?
        Rails.logger.warn('Contact is invalid (data missing)')
        return
      end

      FileUtils.mkdir_p config.work_dir unless Dir.exist?(config.work_dir)

      File.open("#{config.work_dir}/variables.tex", 'w') do |out_file|
        write_our_data(out_file, contact)
        write_common(out_file, invoice.customer)
        callback&.writeAdditionalVars(out_file, invoice)
        out_file.write("\\newcommand{\\jahr}{#{year}}\n")
        out_file.write("\\newcommand{\\renummer}{#{invoice.number}}\n")
        out_file.write("\\newcommand{\\zweck}{#{invoice.number}}\n")
        out_file.write("\\newcommand{\\rechnungTyp}{#{invoice.tax_type}}\n")
        out_file.write("\\newcommand{\\redatum}{#{I18n.l(invoice.invoice_date, format: :long)}}\n")
      end

      pos = 1
      File.open("#{config.work_dir}/posten.tex", 'w') do |out_file|
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

    def write(member, year)
      File.open("#{config.work_dir}/variables.tex", 'w') do |out_file|
        write_our_data(out_file, 'gs')
        out_file.write("\\newcommand{\\jahr}{#{year}}\n")
        write_common(out_file, member.to_customer)
      end
    end

    def write_common(out_file, customer)
      out_file.write("\\newcommand{\\customerId}{#{customer.customer_id}}\n")
      if customer.direct_debit?
        out_file.write('\newcommand{\directDebit}{1}')
        out_file.write("\\newcommand{\\iban}{#{customer.iban}}\n")
        out_file.write("\\newcommand{\\bic}{#{customer.bic}}\n")
        out_file.write("\\newcommand{\\mandateRef}{#{customer.mandate_id}}\n")
        out_file.write("\\newcommand{\\glaeubigerId}{#{config.creditor_id}}\n")
      else
        out_file.write('\newcommand{\directDebit}{0}')
      end
      out_file.write("\n")
      if customer.company.nil?
        out_file.write("\\newcommand{\\firma}{}\n")
      else
        out_file.write("\\newcommand{\\firma}{#{break_name(tex_escape(customer.company))}}\n")
      end

      out_file.write("\\newcommand{\\name}{#{customer.first_name} #{customer.last_name}}\n")
      out_file.write("\\newcommand{\\strasse}{#{customer.street}}\n")
      full_ort = ''
      if customer.zip
        full_ort += customer.zip
        full_ort += ' '
      end
      full_ort += customer.city if customer.city

      out_file.write("\\newcommand{\\ort}{#{full_ort}}\n")

      country = ISO3166::Country[customer.country]
      country_en = if (customer.country == 'DE') || customer.country.nil?
                     ''
                   else
                     country.translations['en']
                   end

      out_file.write("\\newcommand{\\country}{#{country_en}}\n")

      if customer.email.nil?
        out_file.write("\\newcommand{\\email}{0}\n")
      else
        out_file.write("\\newcommand{\\email}{#{customer.email}}\n")
      end

      if !customer.last_name.nil?
        out_file.write("\\newcommand{\\anredetxt}{#{customer.salutation_line}}\n")
      else
        out_file.write("\\newcommand{\\anredetxt}{ Damen und Herren,}\n")
      end
      # out_file.write('\newcommand{\myStrasse}{}'+"\n")
      out_file.write("\\newcommand{\\redatum}{#{I18n.l(Time.now.to_date, format: :long)}}\n")
    end

    def write_our_data(out_file, our_contact)
      out_file.write("\\newcommand{\\myFirma}{#{config.company}}\n")
      out_file.write("\\newcommand{\\myFirmaShort}{#{config.company_short}}\n")

      # contact can override the bank account for DD

      if !our_contact.has_bank_account?
        # use default bank account
        out_file.write("\\newcommand{\\myBank}{#{config.bank}}\n")
        out_file.write("\\newcommand{\\myIBAN}{#{config.iban}}\n")
        out_file.write("\\newcommand{\\myBIC}{#{config.bic}}\n")
      else
        out_file.write("\\newcommand{\\myIBAN}{#{our_contact.iban}}\n")
        out_file.write("\\newcommand{\\myBIC}{#{our_contact.bic}}\n")
        out_file.write("\\newcommand{\\myBank}{#{our_contact.bank}}\n")
      end

      out_file.write("\\newcommand{\\myPhone}{#{our_contact.phone}}\n")
      out_file.write("\\newcommand{\\myFax}{#{our_contact.fax}}\n")
      out_file.write("\\newcommand{\\myMail}{#{our_contact.mail}}\n")
      out_file.write("\\newcommand{\\myName}{#{our_contact.name}}\n")
      out_file.write("\\newcommand{\\myDept}{#{our_contact.dept}}\n")
      out_file.write("\\newcommand{\\myStreet}{#{our_contact.street}}\n")
      out_file.write("\\newcommand{\\myPLZ}{#{our_contact.zip}}\n")
      out_file.write("\\newcommand{\\myOrt}{#{our_contact.city}}\n")
      out_file.write("\\newcommand{\\myJob}{#{our_contact.job}}\n")
      out_file.write("\\newcommand{\\brko}{#{config.header_file}}\n")
    end

    def break_name(name)
      # if name contains ; use that...
      name.gsub(';', '\\\\ ')
    end

    def format_date(date)
      I18n.l(date.to_date, format: :long)
    end

    def format_currency(val, _currency)
      number_to_currency(val, locale: :de)
    end

    def move_generated_files(date_prefix)
      target_dir = config.archive_dir(+'/' + String(Time.now.year))

      shortprefix = Time.now.strftime('%Y%m%d-')

      FileUtils.mkdir target_dir unless Dir.exist? target_dir

      Dir.chdir(config.work_dir)
      Dir.entries(config.work_dir).each do |file|
        FileUtils.mv file, "#{target_dir}/" if file.start_with?(date_prefix) || file.start_with?(shortprefix)
      end
    end

    def gen_pdf(invoice_type, date_prefix, customer_id)
      out_file = "#{date_prefix}-#{customer_id}-#{invoice_type}.pdf"
      batch = File.join(config.tool_dir, 'bin/invoice.sh')
      cli = "#{batch} #{invoice_type} #{date_prefix} #{customer_id}"

      env = {}
      env['TEX'] = config.tex_exe
      env['TEX_DIR'] = config.tex_dir
      env['TEX_BRANDING_DIR'] = config.tex_branding_dir
      env['OUT_DIR'] = config.work_dir

      Rails.logger.debug("Env: #{env}")
      Rails.logger.debug("Exec: #{cli}")

      ENV.update(env)

      system(cli)

      out_file
    end

    def tex_escape(text)
      text.gsub(/"([a-zA-z0-9 ]+)"/, '``\1\'\'').gsub(/&/, '\\\&').gsub(/_/, '\\_').gsub(/"/, '\\dq ')
    end
  end

  private

  def contact_vaild?(contact); end
end
