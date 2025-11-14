module CorikaInvoices
  class ArchiveFile
    include Hashify

    attr_accessor :visible_filename, :orig_filename, :archive_folder

    def self.from_hash(hash)
      if hash.nil?
        nil
      else
        ArchiveFile.new(hash['visible_filename'], hash['orig_filename'], hash['archive_folder'])
      end
    end

    def self.from_source_and_year(srcdir, filename, year)
      target = CorikaInvoices::ArchiveFile.new(filename, filename, year)

      src_file_name = File.join(srcdir, filename)

      raise CorikaInvoices::DocumentGenerationError, "File does not exist: #{src_file_name}" unless File.exist? src_file_name

      Rails.logger.debug("move #{src_file_name} to #{target.full_path}")

      FileUtils.mkdir_p target.full_dir unless Dir.exist? target.full_dir

      FileUtils.mv(src_file_name, target.full_path)

      target
    end

    def initialize(visible_filename, orig_filename, archive_folder = nil)
      self.visible_filename = visible_filename
      self.orig_filename = orig_filename

      self.archive_folder = if archive_folder.nil?
                          Time.now.year.to_s
      else
                          archive_folder.to_s
      end
    end

    def full_dir
      File.join(INVOICE_CONFIG.archive_dir, self.archive_folder)
    end

    def relative_filename
      File.join(self.archive_folder, self.orig_filename)
    end

    def full_path
      File.join(full_dir, self.orig_filename)
    end

    def to_s
      full_path
    end
  end
end
