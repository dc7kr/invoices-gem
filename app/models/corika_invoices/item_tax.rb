module CorikaInvoices
  class ItemTax
    include Mongoid::Document

    field :tax_rate, type: Float
    field :tax_basis, type: Float
    field :label, type: String

    def to_hash
        retval = {
          tax_rate: tax_rate,
          tax_basis: tax_basis,
          label: label
        }

        retval
    end

    def self.create(rate, basis, label = nil)
      it = ItemTax.new
      it.tax_basis = basis
      it.tax_rate = rate
      it.label = label

      it
    end

    def tax_amount
      (tax_rate/100.0) * tax_basis
    end
  end
end
