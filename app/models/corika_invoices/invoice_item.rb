module CorikaInvoices
  class InvoiceItem
    include Mongoid::Document

    include Hashify

    field :count, type: Integer
    field :net_price, type: Float
    field :price, type: Float
    field :tax_type, type: String
    field :tax_rate, type: Float
    field :label, type: String
    field :unit_code, type: String

    field :total, type: Float
    field :basis_price, type: Float
    field :basis_count, type: Float

    validates_presence_of :count, :price, :label

    def self.create(count, price, label, tax_rate = INVOICE_CONFIG.taxrate)
      i = InvoiceItem.new
      i.count = count
      i.unit_code = 'C62'
      i.basis = price
      i.net_amount = price
      i.label = label

      i.tax_type = 'S'
      i.tax_rate = tax_rate

      i
    end

    def tax_total
      if net_price.nil? || net_price.zero?
        tax_rate * count * price / (100 + tax_rate)
      else
        tax_rate * count * net_price / 100
      end
    end

    def net_total
      if net_price.nil? || net_price.zero?
        count * price / (1 + tax_rate / 100)
      else
        net_price * count
      end
    end

    def total
      count * price
    end

    def to_yaml
      hash = to_hash
      hash['total'] = total

      hash.to_yaml
    end
  end
end
