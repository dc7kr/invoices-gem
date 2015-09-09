class InvoiceItem
  include MongoMapper::Document
  key :count, Integer
  key :price, Float
  key :label, String

  belongs_to :invoice

  validates_presence_of :count,:price,:label
  def initialize(count,price,label)
    @count = count
    @price = price
    @label = label 
  end

end
