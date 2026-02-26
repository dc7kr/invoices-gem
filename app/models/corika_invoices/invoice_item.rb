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

    embeds_many :item_taxes, store_as: 'taxes'

    validates_presence_of :count, :unit_code, :tax_type, :tax_rate, :basis, :total, :label

    def self.create_gross(count, gross_price, label, unit_code: 'C62', tax_rate: INVOICE_CONFIG.taxrate, tax_type: 'S')
      tax_factor = tax_rate / 100.0
      net_price = gross_price / (1 + tax_factor)
      create(count, net_price, label, unit_code: unit_code, tax_rate: tax_rate, tax_type: tax_type)
    end

    def self.create(count, basis, label, unit_code: 'C62', tax_rate: INVOICE_CONFIG.taxrate, tax_type: 'S')
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
      if tax_type != 'E'
        tax = ItemTax.new
        tax.tax_basis = basis
        tax.tax_rate = tax_rate
        i.item_taxes << tax
      end

      i.unit_code = unit_code

      i
    end

    def add_split_tax(rate, basis, label = nil )
      tax = ItemTax.new
      tax.tax_basis = basis
      tax.tax_rate = rate
      tax.label = label

      item_taxes << tax
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

    def tax_total
      if basis.nil?
        return 0
      end

      sum = 0
      item_taxes.each do |tx|
        sum += tx.tax_amount*count
      end
      Rails.logger.debug("tax_total: #{sum}")

      sum
    end

    def total
      if basis.nil?
        0
      else
        count * basis
      end
    end

    def to_hash
      tx_array = []

      item_taxes.each do |tx|
        tx_array.append(tx.to_hash)
      end

      hash = {
        count: count,
        unit_code: unit_code,
        tax_type: tax_type,
        tax_rate: tax_rate,
        taxes: tx_array,
        basis: basis,
        label: label,
        net_amount: net_price,
        tax_total: tax_total,
        total: total
      }

      if not reference_price.nil?
        hash[:reference_price] = reference_price
      end

      hash
    end
  end
end
