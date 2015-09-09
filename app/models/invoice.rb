class Invoice
  include Mongoid::Document

  key :invoice_number, String
  key :customer, ObjectId
  
  timestamps! 

  embeds_many :invoice_items
  

  def initialize(number)
    @invoice_number = number
    @items = Array.new
  end


  def items
    @items
  end

  def addItem(item)
    @items << item
  end

  def considerItem(count, price,label)
    if count.nil? or count == 0 then
      return false
    end

    addItem(InvoiceItem.new(count,price,label))
  end

  def sum
    sum=0.0
    @items.each do  |item|
      sum+=item.count*item.price
    end

    sum
  end

  def <<(item)
    @items << item
  end

end
