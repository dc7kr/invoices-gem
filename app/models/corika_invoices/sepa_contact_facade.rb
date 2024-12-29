module CorikaInvoices
  class SepaContactFacade
    attr_accessor :customer

    def initialize(customer)
      self.customer = customer
    end

    def postcode
      customer.zip
    end

    def city
      customer.city[0..65]
    end

    def country
      customer.country
    end

    def phone
      nil
    end

    def email
      nil
    end

    def name
      customer.account_owner[0..65]
    end

    def addr
      customer.street[0..65]
    end

    def contact
      customer.fullname[0..65]
    end
  end
end
