module CorikaInvoices
  class Seller
    include Mongoid::Document
    include Hashify
    field :company, type: String
    field :company_short, type: String
    field :bank, type: String
    field :iban, type: String
    field :bic, type: String
    field :phone, type: String
    field :email, type: String
    field :name, type: String
    field :dept, type: String
    field :street, type: String
    field :zip, type: String
    field :city, type: String
    field :country_id, type: String
    field :job, type: String
    field :creditor_id, type: String
    field :vat_id, type: String
    field :tax_reg, type: String
  end

  def self.from_hash(hashmap)
    seller = Seller.new
    hashmap.each do |key|
      instance_variables[key] = hashmap[key]
    end

    seller
  end
end
