module CorikaInvoices
  class TexWriter 
    attr_accessor :config

    include ApplicationHelper
    include ActionView::Helpers::NumberHelper


    def initialize(config)

      if config.work_dir.nil? 
        throw :invoice_work_dir_nil
      end

      if config.tool_dir.nil? 
        throw :invoice_tool_dir_nil
      end

      self.config=config
    end


    def writeInvoice(invoice,contact_id,year) 
      contact = CorikaInvoices::Contact.new(INVOICE_CONTACT_HASH[contact_id])

      if contact.nil?
        Rails.logger.warn("CONTACT is nil! aborting")
        return
      end

      if not contact.is_valid?
        Rails.logger.warn("Contact is invalid (data missing)")
        return
      end

      File.open(config.work_dir+"/variables.tex", 'w') do |f| 
        writeOurData(f,contact)
        writeCommon(f,invoice.customer)
        f.write('\newcommand{\jahr}{'+year.to_s+"}\n")
        f.write('\newcommand{\renummer}{'+invoice.number+"}\n")
        f.write('\newcommand{\zweck}{'+invoice.number+"}\n")
      end
      File.open(config.work_dir+"/posten.tex",'w') do |f|
        invoice.items.each do |i|
          writeInvoiceItem(f,i.count,i.price,i.label)
          Rails.logger.debug("wrote invoice item: #{i.count}x#{i.price}:#{i.label}")
        end
      end
    end

    def writeInvoiceItem(file, count, tariff, label)
      if (count.nil? or count == 0 )  then
        Rails.logger.info("omitting #{label} item as count was nil or 0")
        return
      end
      amount = '%.2f' % tariff;
      amount = amount.gsub('.',',')

      if tariff < 0 then
        file.write('\Anzahlung{'+amount+"}\n")
      else
        file.write('\Artikel{'+String(count)+'}{'+label+'}{'+amount+"}\n")
      end
    end

    def write(member,year) 
      File.open(config.work_dir+"/variables.tex", 'w') do |f| 
        writeOurData(f,'gs');
        f.write('\newcommand{\jahr}{'+year.to_s+"}\n")
        writeCommon(f,member.to_customer)
      end
    end 

    def writeCommon(f,customer)
      f.write('\newcommand{\customerId}{'+customer.customer_id.to_s+"}\n")
      if ( customer.is_direct_debit? ) then
        f.write('\newcommand{\directDebit}{1}'+"\n")
        f.write('\newcommand{\iban}{'+customer.iban.to_s+"}\n")
        f.write('\newcommand{\bic}{'+customer.bic.to_s+"}\n")

        f.write('\newcommand{\mandateRef}{'+customer.mandate_id.to_s+"}\n")
        f.write('\newcommand{\glaeubigerId}{'+config.creditor_id+"}\n")
      else
        f.write('\newcommand{\directDebit}{0}'+"\n")
      end
      if ( customer.company.nil?)
        f.write('\newcommand{\firma}{}'+"\n")
      else
        f.write('\newcommand{\firma}{'+breakName(tex_escape(customer.company))+'}'+"\n")
      end

      f.write('\newcommand{\name}{'+"#{customer.first_name} #{customer.last_name}}\n")
      f.write('\newcommand{\strasse}{'+"#{customer.street}}\n")
      full_ort=""
      if ( customer.zip) then 
        full_ort += customer.zip
        full_ort += ' '
      end
      if ( customer.city ) then
        full_ort += customer.city
      end

      f.write('\newcommand{\ort}{'+"#{full_ort}}\n")

      country = ISO3166::Country[customer.country]
      country_en = nil
      if (customer.country == "DE" or customer.country.nil?) then
        country_en = ""
      else
        country_en = country.translations['en']
      end

      f.write('\newcommand{\country}{'+country_en+"}\n")
      if customer.email.nil? then
        f.write('\newcommand{\email}{0}'+"\n")
      else
        f.write('\newcommand{\email}{'+customer.email+"}\n")
      end

      lastname=""
      if (customer.last_name) 
          if ( customer.salutation == 'M' ) then
            f.write('\newcommand{\anredetxt}{r Herr '+customer.last_name+"}\n")
          elsif ( customer.salutation == 'W' ) then
            f.write('\newcommand{\anredetxt}{ Frau '+customer.last_name+"}\n")
          else
            f.write('\newcommand{\anredetxt}{ Damen und Herren}'+"\n")
          end
      else 
        f.write('\newcommand{\anredetxt}{ Damen und Herren,}'+"\n")
      end
      #f.write('\newcommand{\myStrasse}{}'+"\n")
      f.write('\newcommand{\redatum}{'+I18n.l(Time.now.to_date , :format => :long)+"}\n")
    end

    def writeOurData(f,our_contact) 

      f.write('\newcommand{\myFirma}{'+config.company+"}\n")
      f.write('\newcommand{\myFirmaShort}{'+config.company_short+"}\n")

      # contact can override the bank account for DD

      if not our_contact.has_bank_account? then
        # use default bank account
        f.write('\newcommand{\myBank}{'+config.bank+"}\n")
        f.write('\newcommand{\myIBAN}{'+config.iban+"}\n")
        f.write('\newcommand{\myBIC}{'+config.bic+"}\n")
      else
        f.write('\newcommand{\myIBAN}{'+our_contact.iban+"}\n")
        f.write('\newcommand{\myBIC}{'+our_contact.bic+"}\n")
        f.write('\newcommand{\myBank}{'+our_contact.bank+"}\n")
      end

      f.write('\newcommand{\myPhone}{'+our_contact.phone+"}\n")
      f.write('\newcommand{\myFax}{'+our_contact.fax+"}\n")
      f.write('\newcommand{\myMail}{'+our_contact.mail+"}\n")
      f.write('\newcommand{\myName}{'+our_contact.name+"}\n")
      f.write('\newcommand{\myDept}{'+our_contact.dept+"}\n")
      f.write('\newcommand{\myStreet}{'+our_contact.street+"}\n")
      f.write('\newcommand{\myPLZ}{'+our_contact.plz+"}\n")
      f.write('\newcommand{\myOrt}{'+our_contact.ort+"}\n")
      f.write('\newcommand{\myJob}{'+our_contact.job+"}\n")
    end


    def breakName(name)
      # if name contains ; use that...
      name.gsub(";","\\\\ ")
    end
    def format_date(date)
      return I18n.l(date.to_date , :format => :long)
    end

    def format_currency(val,currency)
      return number_to_currency(val,:locale => :de)
    end

    def moveGeneratedFiles(datePrefix)
      tgtDir= config.archive_dir +"/"+String(Time.now.year)

      shortprefix = Time.now.strftime("%Y%m%d-")

      if ( ! Dir.exists? tgtDir) then
        FileUtils.mkdir tgtDir
      end

      Dir.chdir(config.work_dir)
      Dir.entries(config.work_dir).each { |file|
        if file.start_with? datePrefix or file.start_with? shortprefix then
          FileUtils.mv file, tgtDir+"/"
        end
      }
    end

    def gen_pdf(invoice_type, datePrefix, customer_id)
      out_file = "#{datePrefix}-#{customer_id}-#{invoice_type}.pdf"
      batch = File.join(config.tool_dir, "bin/invoice.sh")
      cli = "#{batch} #{invoice_type} #{datePrefix} #{customer_id}"
      Rails.logger.debug("Exec: #{cli}")

      env = Hash.new
      env["TEX"]= config.tex_exe
      env["TEX_DIR"]= config.tex_dir
      env["TEX_BRANDING_DIR"]= config.tex_branding_dir
      env["OUT_DIR"]= config.work_dir

      ENV.update(env)

      system(cli)

      out_file
    end

    def tex_escape(text)
      text.gsub(/\"([a-zA-z0-9 ]+)\"/, '\glqq \1\grqq ').gsub(/\&/,'\\\&').gsub(/_/,'\\_').gsub(/"/,'\\dq')
    end
  end

  private 
  def contact_vaild?(contact) 
  end
end
