module CorikaInvoices
  class Customer 

    include Mongoid::Document
    
    field :customer_id, type: String
    field :salutation, type: String
    field :first_name, type: String
    field :last_name, type: String
    field :street, type: String
    field :zip, type: String
    field :city, type: String
    field :country, type: String
    field :email, type: String
    field :iban, type: String
    field :bic, type: String
    field :account_owner, type: String
    field :company, type: String
    field :mandate_id, type: String
    field :sig_date, type: Date
    field :direct_debit, type: Boolean
    field :entity_type, type: String
    field :entity_id, type: Integer


    def full_name
      "#{first_name} #{last_name}"  
    end

    def is_direct_debit?
      direct_debit and not ( iban.blank?  or bic.blank?)
    end

    def account_owner
      if company.nil? or company.length == 0 then
        full_name
      else
        company
      end
    end

    def entity=(entity)
      self.entity_type= entity.class.name
      self.entity_id = entity.id
    end

    def entity
      entity_type.constantize.find(entity_id)
    end
    
    def mandate_id
        INVOICE_CONFIG[:mandate_prefix]+"#{customer_id}"
    end

    def sig_date
      Date.new(2014,1,1)
    end
  end
end
