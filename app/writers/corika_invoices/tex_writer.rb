module CorikaInvoices
  class TexWriter 
    attr_accessor :workdir,:tooldir

    include ApplicationHelper
    include ActionView::Helpers::NumberHelper


    def initialize
      self.workdir = INVOICE_CONFIG['invoice_workdir']
      self.tooldir = INVOICE_CONFIG['invoice_tool_dir']
    end


    def writeInvoice(invoice,contact,year) 
      File.open(self.workdir+"/variables.tex", 'w') do |f| 
        writeOurData(f,contact)
        writeCommon(f,invoice.customer)
        f.write('\newcommand{\jahr}{'+year.to_s+"}\n")
        f.write('\newcommand{\renummer}{'+invoice.number+"}\n")
        f.write('\newcommand{\zweck}{'+invoice.number+"}\n")
      end
      File.open(self.workdir+"/posten.tex",'w') do |f|
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
      File.open(self.workdir+"/variables.tex", 'w') do |f| 
        writeOurData(f,'gs');
        f.write('\newcommand{\jahr}{'+year.to_s+"}\n")
        writeCommon(f,member.to_customer)
      end
    end 

    def writeCommon(f,customer)
      f.write('\newcommand{\mglnr}{'+customer.customer_id.to_s+"}\n")
      if ( customer.is_direct_debit? ) then
        f.write('\newcommand{\directDebit}{1}'+"\n")
        f.write('\newcommand{\iban}{'+customer.iban.to_s+"}\n")
        f.write('\newcommand{\bic}{'+customer.bic.to_s+"}\n")

        f.write('\newcommand{\mandateRef}{'+customer.mandate_id.to_s+"}\n")
        f.write('\newcommand{\glaeubigerId}{'+INVOICE_CONFIG["creditor_id"]+"}\n")
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

      lastname=""
      if (customer.last_name) 
          if ( customer.salutation == 'M' ) then
            f.write('\newcommand{\anredetxt}{r Herr '+customer.name+"}\n")
          elsif ( customer.salutation == 'W' ) then
            f.write('\newcommand{\anredetxt}{ Frau '+customer.name+"}\n")
          else
            f.write('\newcommand{\anredetxt}{ Damen und Herren}'+"\n")
          end
      else 
        f.write('\newcommand{\anredetxt}{ Damen und Herren,}'+"\n")
      end
      #f.write('\newcommand{\myStrasse}{}'+"\n")
      f.write('\newcommand{\redatum}{'+I18n.l(Time.now.to_date , :format => :long)+"}\n")
    end

    def writeOurData(f,contact) 
      our_contact = INVOICE_CONFIG['contacts'][contact]

      f.write('\newcommand{\myFirma}{'+INVOICE_CONFIG['company']+"}\n")
      f.write('\newcommand{\myFirmaShort}{'+INVOICE_CONFIG['companyShort']+"}\n")
      f.write('\newcommand{\myKonto}{'+INVOICE_CONFIG['konto']+"}\n")
      f.write('\newcommand{\myBLZ}{'+INVOICE_CONFIG['blz']+"}\n")
      if ( our_contact['iban'].nil? ) then
        f.write('\newcommand{\myBank}{'+INVOICE_CONFIG['bank']+"}\n")
        f.write('\newcommand{\myIBAN}{'+INVOICE_CONFIG['iban']+"}\n")
        f.write('\newcommand{\myBIC}{'+INVOICE_CONFIG['bic']+"}\n")
      else
        f.write('\newcommand{\myIBAN}{'+our_contact['iban']+"}\n")
        f.write('\newcommand{\myBIC}{'+our_contact['bic']+"}\n")
        f.write('\newcommand{\myBank}{'+our_contact['bank']+"}\n")
      end

      f.write('\newcommand{\myPhone}{'+our_contact['phone']+"}\n")
      f.write('\newcommand{\myFax}{'+our_contact['fax']+"}\n")
      f.write('\newcommand{\myMail}{'+our_contact['mail']+"}\n")
      f.write('\newcommand{\myName}{'+our_contact['name']+"}\n")
      f.write('\newcommand{\myDept}{'+our_contact['dept']+"}\n")
      f.write('\newcommand{\myStreet}{'+our_contact['street']+"}\n")
      f.write('\newcommand{\myPLZ}{'+our_contact['plz']+"}\n")
      f.write('\newcommand{\myOrt}{'+our_contact['ort']+"}\n")
      f.write('\newcommand{\myJob}{'+our_contact['job']+"}\n")
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
      workDir = INVOICE_CONFIG['invoice_workdir']
      archiveDir= INVOICE_CONFIG['invoice_archive_dir']
      tgtDir= archiveDir +"/"+String(Time.now.year)

      shortprefix = Time.now.strftime("%Y%m%d-")

      if ( ! Dir.exists? tgtDir) then
        FileUtils.mkdir tgtDir
      end

      Dir.chdir(workDir)
      Dir.entries(workDir).each { |file|
        if file.start_with? datePrefix or file.start_with? shortprefix then
          FileUtils.mv file, tgtDir+"/"
        end
      }
    end

    def gen_pdf(invoice_type, datePrefix, customer_id)
      out_file = "#{datePrefix}-#{customer_id}-#{invoice_type}.pdf"
      batch = File.join(self.tooldir, "bin/rechnung.sh")
      cli = "#{batch} #{invoice_type} #{datePrefix} #{customer_id}"
      Rails.logger.debug("Exec: #{cli}")
      system(cli)

      out_file
    end

    def tex_escape(text)
      text.gsub(/\"([a-zA-z0-9]+)\"/, '\glqq \1\grqq ')
    end
  end
end
