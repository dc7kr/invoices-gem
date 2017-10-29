module CorikaInvoices
  class Config 
    attr_accessor  :work_dir, :tool_dir, :archive_dir,:creditor_id,:company,:company_short,:iban,:bic,:bank, :tex_exe, :tex_dir, :tex_branding_dir

    def initialize(hash) 

      if hash.nil? 
        throw :invoice_config_data_nil
      end

      hash.each do |k,v|
        if respond_to? "#{k}="
          public_send("#{k}=",v) 
        end
      end
    end
  end
end
