class InvoiceCustomer 

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
  field :company, type: String
  field :mandate_id, type: String
  field :sig_date, type: Date


  def full_name
    "#{first_name} #{last_name}"  
  end

  def is_direct_debit?
    not ( iban.blank?  or bic.blank?)
  end

  def account_owner
    if company.nil? or company.length == 0 then
      full_name
    else
      company
    end
  end
end
