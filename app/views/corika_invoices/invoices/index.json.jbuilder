json.array! @invoices do |invoice|
  json.(invoice, :invoice_type)
end
