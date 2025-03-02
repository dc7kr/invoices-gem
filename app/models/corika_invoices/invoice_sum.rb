module CorikaInvoices
  class InvoiceSum
    include Mongoid::Document
    field :grand_total, type: Float
    field :due_payable, type: Float
    field :tax_basis, type: Float
    field :tax, type: Float

    field :line_total, type: Float

    embeds_many :invoice_taxes, store_as: 'taxes'
  end
end
