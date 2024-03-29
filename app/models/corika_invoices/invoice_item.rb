module CorikaInvoices
  class InvoiceItem
    include Mongoid::Document

    field :count, type: Integer
    field :net_price, type: Float
    field :price, type: Float
    field :label, type: String

    validates_presence_of :count,:price,:label

    def self.create(count,price,label,net_price=nil)
      i = InvoiceItem.new
      i.count = count
      i.price = price
      i.label = label
      i.net_price=net_price

      i
    end

    def total
      count*price
    end
  end
end
