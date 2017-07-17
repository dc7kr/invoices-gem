class InvoiceItem
  include Mongoid::Document

  field :count, type: Integer
  field :price, type: Float
  field :label, type: String

  validates_presence_of :count,:price,:label

  def self.create(count,price,label)
    i = InvoiceItem.new
    i.count = count
    i.price = price
    i.label = label

    i
  end

  def total
    count*price
  end
end
