module CorikaInvoices
  class InvoiceItem
    include Mongoid::Document

    include Hashify

    field :count, type: Integer
    field :net_price, type: Float
    field :price, type: Float
    field :tax_rate, type: Float
    field :label, type: String

    validates_presence_of :count, :price, :label

    def self.create(count, price, label, net_price = nil, tax_rate = INVOICE_CONFIG.taxrate)
      i = InvoiceItem.new
      i.count = count
      i.price = price
      i.label = label
      i.net_price = net_price
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
