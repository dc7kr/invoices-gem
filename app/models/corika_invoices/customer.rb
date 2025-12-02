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

    def direct_debit?
      direct_debit and !(iban.blank? or bic.blank?)
    end

    def account_owner
      if company.nil? || company.empty?
        full_name
      else
        company
      end
    end

    def entity=(entity)
      self.entity_type = entity.class.name
      self.entity_id = entity.id
    end

    def entity
      entity_type.constantize.find(entity_id)
    end

    def salutation_line
      if salutation == 'M'
        "r Herr #{last_name}"
      elsif salutation == 'W'
        " Frau #{last_name}"
      else
        ' Damen und Herren'
      end
    end

    def to_hash
      hash = {
        id: customer_id,
        salutation: I18n.t("common.salutations.#{salutation}"),
        greeting:  salutation_line,
        name: "#{first_name} #{last_name}",
        street: street,
        zip: zip,
        city: city,
        country_id: country,
        email: email,
        iban: iban,
        bic: bic,
        account_owner: account_owner,
        company: company,
        mandate_id: mandate_id,
        sig_date: sig_date,
        direct_debit: direct_debit
      }

      hash['dd'] = direct_debit?

      hash
    end
  end
end
