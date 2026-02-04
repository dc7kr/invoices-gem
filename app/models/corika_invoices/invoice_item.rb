module CorikaInvoices
  class InvoiceItem
    include Mongoid::Document

    include Hashify

    field :count,     type: Float
    field :unit_code, type: String
    field :tax_type,  type: String
    field :tax_rate,  type: Float
    field :basis,     type: Float
    field :label,     type: String
    field :net_price, type: Float
    field :reference_price, type: Float

    validates_presence_of :count, :unit_code, :tax_type, :tax_rate, :basis, :total, :label

    def self.create_gross(count, gross_price, label, unit_code = 'C62', tax_rate = INVOICE_CONFIG.taxrate, tax_type = 'S')
      tax_factor = tax_rate / 100.0
      net_price = gross_price / (1 + tax_factor)
      create(count, net_price, label, unit_code, tax_rate, tax_type)
    end

    def self.create(count, basis, label, unit_code = 'C62', tax_rate: INVOICE_CONFIG.taxrate, tax_type: 'S')
      i = InvoiceItem.new

      i.basis = basis
      i.net_price = basis

      i.count = count
      i.label = label

      i.tax_type = tax_type

      i.tax_rate = if i.tax_type == 'E'
                     0
                   else
                     tax_rate
                   end

      i.unit_code = unit_code

      i
    end

    def tax
      if tax_type == 'E'
        0
      else
        tax_rate * 0.01 * count * basis
      end
    end

    def net_total
      if basis.nil?
        0
      else
        basis * count
      end
    end

    def total
      if basis.nil?
        0
      else
        count * basis
      end
    end

    def to_hash
      hash = {
        count: count,
        unit_code: unit_code,
        tax_type: tax_type,
        tax_rate: tax_rate,
        basis: basis,
        label: label,
        net_amount: net_price,
        total: total
      }

      if not reference_price.nil?
        hash[:reference_price] = reference_price
      end

      hash
    end
  end
end
