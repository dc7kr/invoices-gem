module CorikaInvoices
  class Config
    attr_accessor :input_dir, :output_dir, :tool_dir, :archive_dir, :template_dir,
                  :payee, :message_prefix, :taxrate, :taxrate_reduced,
                  :tex_bin, :tex_dir, :fonts_dir, :custom_dir, :default_tax_mode

    def initialize(hash)
      throw :invoice_config_data_nil if hash.nil?

      hash.each do |k, v|
        if k == 'payee'
          self.payee = CorikaInvoices::PayeeContact.new(v)
        elsif respond_to? "#{k}="
          public_send("#{k}=", v)
        end
      end
    end
  end
end
