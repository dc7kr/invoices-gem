module CorikaInvoices
  class SepaContactFacade
    attr_accessor :customer

    def initialize(customer)
      self.customer=customer
    end

    def postcode
      self.customer.zip
    end

    def city
      self.customer.city[0..65]
    end

    def country
      self.customer.country 
    end

    def phone
      nil
    end

    def email
      nil
    end

    def name
      self.customer.account_owner[0..65]
    end

    def addr
      self.customer.street[0..65]
    end

    def contact
      self.customer.fullname[0..65]
    end
  end
end
