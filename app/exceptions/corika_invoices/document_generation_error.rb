module CorikaInvoices
  class DocumentGenerationError < StandardError
    def initialize(message)
      super(message)
    end
  end
end
