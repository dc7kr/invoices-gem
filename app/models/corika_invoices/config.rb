module CorikaInvoices
  class Config
    attr_accessor :work_dir, :tool_dir, :archive_dir, :creditor_id, :company, :company_short, :iban, :bic, :bank, :tex_exe,
                  :tex_dir, :tex_branding_dir, :message_prefix, :taxrate, :taxrate_reduced, :header_file

    def initialize(hash)
      throw :invoice_config_data_nil if hash.nil?

      hash.each do |k, v|
        public_send("#{k}=", v) if respond_to? "#{k}="
      end
    end
  end
end
