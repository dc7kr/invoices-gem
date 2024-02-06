require 'sepa_king'

module CorikaInvoices
  class SepaWriter 
    attr_accessor :date_prefix, :outfile,:workdir, :direct_debits, :credit_transfers,:year, :company,:bic,:iban,:creditor_id,:message_prefix,:settings,:generator_session_id


    def initialize(date_prefix,settings,year=nil)
      self.workdir = settings.work_dir+"/"

      if date_prefix.nil? then
        self.date_prefix = Time.now.strftime '%Y%m%d%H%M%S'
      else
        self.date_prefix=date_prefix
      end

      if year.nil? then
        self.year = Time.now.year
      else
        self.year = year
      end

      self.settings = settings
      self.direct_debits = Array.new
      self.credit_transfers = Array.new


      self.company = settings.company
      self.bic = settings.bic
      self.iban = settings.iban.gsub(/ /,"")
      self.creditor_id = settings.creditor_id
      self.message_prefix = settings.message_prefix

      if self.message_prefix.nil? then
        self.message_prefix="KRI"
      end
      self.generator_session_id = SecureRandom.uuid
    end
    

    def overrideDate(pref)
      self.date_prefix=pref+"_"
    end

    

    public
    def add_direct_debit(customer, amount, remittance_txt,sequence_type=nil)
      if self.credit_transfers.count > 0 
        throw :invalid_request
      else
        dd = SepaDirectDebit.new(customer,sequence_type)
        dd.remittance_txt = remittance_txt
        dd.amount = amount 

        Rails.logger.debug("New booking: #{customer.id}: #{dd.sequence_type}: #{amount}")
        self.direct_debits << dd

        true
      end
    end

    def add_credit_transfer(customer,remittance_txt, amount) 
      if self.direct_debits.count > 0 
        throw :invalid_request
      else
        if not customer.is_direct_debit? then
          Rails.logger.info("Customer #{customer.customer_id} is not considered for CreditTransfer - no IBAN/BIC!")
          return false
        end

        ct = SepaCreditTransfer.new(customer,amount) 
        ct.remittance_txt = remittance_txt

        self.credit_transfers << ct
        
        true
      end
    end

    def filename
      if self.direct_debits.count >0 
        self.date_prefix+"_sepa_dd.xml"
      elsif self.credit_transfers.count >0 
        self.date_prefix+"_sepa_ct.xml"
      else
        nil
      end
    end

    def generate_file
      write_xml
    end

    private
    def write_xml
      if self.direct_debits.count == 0 and self.credit_transfers.count == 0
        Rails.logger.warn("No SEPA bookings - not generating empty file")
        return nil
      end

      sepaxml = nil

      if self.direct_debits.count > 0 
        sepaxml = create_sepa_direct_debit_order(self.direct_debits)
      elsif self.credit_transfers.count > 0 
        sepaxml = create_credit_transfer(self.credit_transfers)
      end

      outfile = MailingFile.new(self.filename,self.filename,self.year.to_s)
      sepaFile = File.open(outfile.full_path,"w")
      sepaFile << sepaxml
      sepaFile.close

      outfile
    end

    def create_sepa_direct_debit_order direct_debits, requested_date=nil
      dd_list = Array.new

      if requested_date.nil? 
        requested_date = 5.day.from_now.to_date
      end

      sdd = Sepa::DirectDebit.new(
        name:       self.company,
        bic:        self.bic,
        iban:       self.iban,
        creditor_identifier: self.creditor_id
      )

      # REQUIRES sepa_king > 0.1.0 
      sdd.message_identification = "#{self.message_prefix}/#{Time.now.to_i}"

      direct_debits.each do |dd|
        sdd.add_transaction(
          name:                      dd.name,
          bic:                       dd.bic,
          iban:                      dd.iban,
          amount:                    dd.amount,

          # OPTIONAL: End-To-End-Identification, will be submitted to the debtor
          # String, max. 35 char
          #reference:                 'XYZ/2013-08-ABO/6789',

          remittance_information:    dd.remittance_txt,
          mandate_id:                dd.mandate_id,
          mandate_date_of_signature: dd.sig_date,

          local_instrument: 'CORE',
          sequence_type: dd.sequence_type,
          requested_date: requested_date

          # OPTIONAL: Enables or disables batch booking, in German "Sammelbuchung / Einzelbuchung"
          #batch_booking: true
        )
      end

      sdd.to_xml 
    end

    def create_credit_transfer credit_transfers
      # First: Create the main object
      sct = Sepa::CreditTransfer.new(
        name:       self.company,
        bic:        self.bic,
        iban:       self.iban,
      )

      credit_transfers.each do |c|

        Rails.logger.debug("Credit Transfer: #{c.iban} BIC: #{c.bic}")
        # Second: Add transactions
        sct.add_transaction(
          name:                   c.customer.account_owner,
          bic:                    c.bic,
          iban:                   c.iban,
          amount:                 c.amount,

          # OPTIONAL: End-To-End-Identification, will be submitted to the creditor
          # String, max. 35 char
          #reference:              'XYZ-1234/123',

          # OPTIONAL: Unstructured remittance information, in German "Verwendungszweck"
          # String, max. 140 char
          remittance_information: c.remittance_txt,

          # OPTIONAL: Requested execution date, in German "Ausführungstermin"
          # Date
          #requested_date: Date.new(2013,9,5),

          # OPTIONAL: Enables or disables batch booking, in German "Sammelbuchung / Einzelbuchung"
          # True or False
          #batch_booking: true,

          #service_level: 'URGP'
        )
      end

      sct.to_xml # Use latest schema pain.001.003.03
      # old FORMAT: xml_string = sct.to_xml('pain.001.002.03') 
    end
  end
end
