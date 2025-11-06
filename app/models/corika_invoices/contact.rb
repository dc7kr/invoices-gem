require 'yaml'

module CorikaInvoices
  class Contact
    include Mongoid::Document

    field :iban, type: String
    field :bic, type: String
    field :phone, type: String
    field :fax, type: String
    field :email, type: String
    field :name, type: String
    field :dept, type: String
    field :street, type: String
    field :city, type: String
    field :zip, type: String
    field :job, type: String
    field :bank, type: String

    field :company, type: String
    field :company_short, type: String
    field :vat_id, type: String
    field :tax_reg, type: String
    field :creditor_id, type: String
    field :country_id, type: String


    def initialize(hash)
      throw :contact_data_nil if hash.nil?
      super

      hash.each do |k, v|
        public_send("#{k}=", v)
      end

      self.company = INVOICE_CONFIG.payee.company
      self.company_short = INVOICE_CONFIG.payee.company_short
      self.vat_id = INVOICE_CONFIG.payee.vat_id
      self.tax_reg = INVOICE_CONFIG.payee.tax_reg
      self.creditor_id = INVOICE_CONFIG.payee.creditor_id
      
      # only use default IBAN/BIC/Bank if it is not overridden by contact hash
      self.iban = INVOICE_CONFIG.payee.creditor_id if self.iban.nil?
      self.bank = INVOICE_CONFIG.payee.bank if self.bank.nil?
      self.bic = INVOICE_CONFIG.payee.bic if self.bic.nil?
    end

    def valid?
      !(name.nil? or dept.nil? or street.nil? or zip.nil? or city.nil? or job.nil?)
    end

    def bank_account?
      !iban.nil? and !bic.nil?
    end

    def to_hash
      {
        :iban => iban,
        :bic => bic,
        :phone => phone,
        :fax =>  fax,
        :email => email,
        :name => name,
        :dept => dept,
        :street => street,
        :city => city,
        :country_id=> country_id,
        :zip => zip,
        :job => job,
        :bank => bank,
        :company => company,
        :company_short => company_short,
        :vat_id => vat_id,
        :tax_reg => tax_reg,
        :creditor_id => creditor_id
      }
    end
  end
end
