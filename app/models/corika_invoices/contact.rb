module CorikaInvoices
  class Contact
    attr_accessor :iban, :bic, :phone, :fax, :mail, :name, :dept, :street, :plz, :ort, :job

    def initialize(hash)

      if hash.nil? 
        throw :contact_data_nil
      end

      hash.each do |k,v|
        public_send("#{k}=",v)
      end
    end

    def is_valid?
      not (self.name.nil? or self.dept.nil?  or self.street.nil?  or self.plz.nil?  or self.ort.nil? or self.job.nil?)
    end

    def has_bank_account? 
      not iban.nil? and not bic.nil?
    end
  end
end
