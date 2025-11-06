module CorikaInvoices
  class PayeeContact
    attr_accessor :company, :company_short, :iban, :bic, :bank,
                  :tax_reg, :vat_id, :creditor_id 

    def initialize(hash)
      throw :invoice_config_data_nil if hash.nil?

      hash.each do |k, v|
        public_send("#{k}=", v) if respond_to? "#{k}="
      end
    end
  end
end
