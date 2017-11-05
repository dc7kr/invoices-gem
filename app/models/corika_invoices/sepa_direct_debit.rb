module CorikaInvoices 
  class SepaDirectDebit  < SepaContactFacade
    attr_accessor :end_to_end_id,:amount,:remittance_txt,:sequence_type

    def initialize(customer, seq_type="RCUR")
      super(customer)

      if (seq_type.nil?) then
        seq_type = "RCUR"
      end

      self.sequence_type=seq_type
    end

    def iban
      self.customer.iban
    end

    def bic
      self.customer.bic
    end

    def mandate_id
      self.customer.mandate_id
    end

    def sig_date
      self.customer.sig_date
    end

    def end_to_end_id(prefix)
      prefix+"_"+self.customer.customer_id.to_s
    end
  end
end
