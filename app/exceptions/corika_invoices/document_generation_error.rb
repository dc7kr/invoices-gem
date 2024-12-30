module CorikaInvoices
  class DocumentGenerationError < StandardError
    def initialize(message)
      @message = message
    end
  end
end
