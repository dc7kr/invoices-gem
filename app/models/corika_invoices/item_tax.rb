module CorikaInvoices
  class ItemTax
    include Mongoid::Document

    field :tax_rate, type: Float
    field :tax_basis, type: Float

    def to_hash
        retval = { 
          tax_rate: tax_rate,
          tax_basis: tax_basis
        }

        retval
    end
  end
end
