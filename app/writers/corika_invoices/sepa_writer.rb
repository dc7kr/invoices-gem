require 'sepa_king'

module CorikaInvoices
  class SepaWriter
    attr_accessor :date_prefix, :outfile, :workdir, :direct_debits, :credit_transfers, :year, :company, :bic, :iban,
                  :creditor_id, :message_prefix, :settings, :generator_session_id

    def initialize(date_prefix, settings, year = nil)
      self.workdir = "#{settings.input_dir}/"

      self.date_prefix = if date_prefix.nil?
                           Time.now.strftime '%Y%m%d%H%M%S'
                         else
                           date_prefix
                         end

      self.year = if year.nil?
                    Time.now.year
                  else
                    year
                  end

      self.settings = settings
      self.direct_debits = []
      self.credit_transfers = []

      payee = settings.payee

      self.company = payee.company
      self.bic = payee.bic
      self.iban = payee.iban.gsub(/ /, '')
      self.creditor_id = payee.creditor_id
      self.message_prefix = settings.message_prefix

      self.message_prefix = 'KRI' if message_prefix.nil?
      self.generator_session_id = SecureRandom.uuid
    end

    def override_date(pref)
      self.date_prefix = "#{pref}_"
    end

    def add_invoice(invoice, prefix)
      dd = SepaDirectDebit.new(invoice.customer, nil)
      dd.remittance_txt = "#{prefix} #{invoice.number}"
      dd.amount = invoice.sum
      @direct_debits << dd
    end

    def add_direct_debit(customer, amount, remittance_txt, sequence_type = nil)
      if credit_transfers.count.positive?
        throw :invalid_request
      else
        dd = SepaDirectDebit.new(customer, sequence_type)
        dd.remittance_txt = remittance_txt
        dd.amount = amount

        Rails.logger.debug("New booking: #{customer.id}: #{dd.sequence_type}: #{amount}")
        direct_debits << dd

        true
      end
    end

    def add_credit_transfer(customer, remittance_txt, amount)
      if direct_debits.count.positive?
        throw :invalid_request
      else
        unless customer.direct_debit?
          Rails.logger.info("Customer #{customer.customer_id} is not considered for CreditTransfer - no IBAN/BIC!")
          return false
        end

        ct = SepaCreditTransfer.new(customer, amount)
        ct.remittance_txt = remittance_txt

        credit_transfers << ct

        true
      end
    end

    def filename
      if direct_debits.count.positive?
        "#{date_prefix}_sepa_dd.xml"
      elsif credit_transfers.positive?
        "#{date_prefix}_sepa_ct.xml"
      end
    end

    def ensure_target_dir_exists(file_path)
      dir = File.dirname(file_path)
      return if File.directory?(dir)

      FileUtils.mkdir_p(dir)
    end

    def generate_file
      outfile = CorikaInvoices::ArchiveFile.new(filename, filename, year.to_s)
      ensure_target_dir_exists(outfile.full_path)

      sepa_file = File.open(outfile.full_path, 'w')
      sepa_file << generate_xml
      sepa_file.close

      outfile
    end

    def generate_xml
      if direct_debits.count.zero? && credit_transfers.count.zero?
        Rails.logger.warn('No SEPA bookings - not generating empty file')
        return nil
      end

      sepaxml = nil

      if direct_debits.count.positive?
        sepaxml = create_sepa_direct_debit_order(direct_debits)
      elsif credit_transfers.count.positive?
        sepaxml = create_credit_transfer(credit_transfers)
      end

    end

    private
    def create_sepa_direct_debit_order(direct_debits, requested_date = nil)
      requested_date = 5.day.from_now.to_date if requested_date.nil?

      sdd = SEPA::DirectDebit.new(
        name: company,
        bic: bic,
        iban: iban,
        creditor_identifier: creditor_id
      )

      # REQUIRES sepa_king > 0.1.0
      sdd.message_identification = "#{message_prefix}/#{Time.now.to_i}"

      direct_debits.each do |dd|
        sdd.add_transaction(
          name: dd.name,
          bic: dd.bic,
          iban: dd.iban,
          amount: dd.amount,

          # OPTIONAL: End-To-End-Identification, will be submitted to the debtor
          # String, max. 35 char
          # reference:                 'XYZ/2013-08-ABO/6789',

          remittance_information: dd.remittance_txt,
          mandate_id: dd.mandate_id,
          mandate_date_of_signature: dd.sig_date,

          local_instrument: 'CORE',
          sequence_type: dd.sequence_type,
          requested_date: requested_date
          # OPTIONAL: Enables or disables batch booking, in German "Sammelbuchung / Einzelbuchung"
          # batch_booking: true
        )
      end

      sdd.to_xml
    end

    def create_credit_transfer(credit_transfers)
      # First: Create the main object
      sct = SEPA::CreditTransfer.new(
        name: company,
        bic: bic,
        iban: iban
      )

      credit_transfers.each do |c|
        Rails.logger.debug("Credit Transfer: #{c.iban} BIC: #{c.bic}")
        # Second: Add transactions
        sct.add_transaction(
          name: c.customer.account_owner,
          bic: c.bic,
          iban: c.iban,
          amount: c.amount,

          # OPTIONAL: End-To-End-Identification, will be submitted to the creditor
          # String, max. 35 char
          # reference:              'XYZ-1234/123',

          # OPTIONAL: Unstructured remittance information, in German "Verwendungszweck"
          # String, max. 140 char
          remittance_information: c.remittance_txt
          # OPTIONAL: Requested execution date, in German "Ausführungstermin"
          # Date
          # requested_date: Date.new(2013,9,5),

          # OPTIONAL: Enables or disables batch booking, in German "Sammelbuchung / Einzelbuchung"
          # True or False
          # batch_booking: true,

          # service_level: 'URGP'
        )
      end

      sct.to_xml # Use latest schema pain.001.003.03
      # old FORMAT: xml_string = sct.to_xml('pain.001.002.03')
    end
  end
end
