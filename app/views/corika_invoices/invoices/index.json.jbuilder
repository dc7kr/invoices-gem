json.array! @invoices do |invoice|
  json.call(invoice, :invoice_type)
end
