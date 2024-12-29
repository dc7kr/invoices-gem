module CorikaInvoices
  class Contact
    attr_accessor :iban, :bic, :phone, :fax, :mail, :name, :dept, :street, :city, :zip, :job, :bank

    # for yaml generation
    include Hashify

    def initialize(hash)
      throw :contact_data_nil if hash.nil?

      hash.each do |k, v|
        public_send("#{k}=", v)
      end
    end

    def valid?
      !(name.nil? or dept.nil? or street.nil? or zip.nil? or city.nil? or job.nil?)
    end

    def bank_account?
      !iban.nil? and !bic.nil?
    end
  end
end
