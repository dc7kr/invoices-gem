module CorikaInvoices
  class PdfGenerator
    attr_accessor :config

    include ApplicationHelper
    include ActionView::Helpers::NumberHelper

    def initialize(config)
      throw :invoice_input_dir_nil if config.input_dir.nil?
      throw :invoice_output_dir_nil if config.output_dir.nil?
      throw :invoice_tool_dir_nil if config.tool_dir.nil?

      self.config = config
    end

    def gen_pdf(invoice, template_subdir = nil)
      uuid = SecureRandom.uuid

      work_file_name = "#{uuid}.yml"
      out_file_name = "#{uuid}.pdf"

      File.open("#{config.input_dir}/#{work_file_name}", 'w') do |out_file|
        out_file.write(invoice.to_yaml)
      end

      cmd = File.join(config.tool_dir, 'bin/gen_invoice.sh')
      cli = "#{cmd} #{File.join(config.input_dir, work_file_name)}"

      env = {}
      env['INVOICE_INPUT_DIR'] = config.input_dir
      env['INVOICE_OUTPUT_DIR'] = config.output_dir

      template_dir = if !template_subdir.nil?
                       File.join(config.custom_dir, template_subdir)
                     else
                       config.custom_dir
                     end

      Rails.logger.debug("Template dir: #{template_dir}")

      env['INVOICE_CUSTOM_DIR'] = template_dir
      env['INVOICE_TEX_BIN'] = config.tex_bin
      env['INVOICE_TEX_DIR'] = File.join(config.tool_dir, 'tex')
      env['INVOICE_FONT_DIR'] = config.fonts_dir
      env['INVOICE_LOCALE_CONFIG'] = File.join(config.tool_dir, 'locale.yml')

      # env['INVOICE_CFG'] = File.join(config.tool_dir, "config", config_file)

      Rails.logger.debug("Env: #{env}")
      Rails.logger.debug("Exec: #{cli}")

      ENV.update(env)

      IO.popen(cli) { |io| while (line = io.gets) do Rails.logger.debug line end }

      out_file_name
    end

    def archive_generated_file(generated_file, target_filename, year)
      target_dir = File.join(config.archive_dir, year.to_s)

      FileUtils.mkdir_p target_dir unless Dir.exist? target_dir
      src_file_path = File.join(config.output_dir, generated_file)
      
      if not File.exist? src_file_path
        raise "Error generating PDF"
      end

      dest_file_path = File.join(target_dir, target_filename)

      FileUtils.mv src_file_path, dest_file_path
    end
  end
end
