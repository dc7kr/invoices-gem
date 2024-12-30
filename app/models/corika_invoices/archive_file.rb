class ArchiveFile
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

    raise DocumentGenerationException("File does not exist: #{src_file_name}") unless File.exist? srcFileName

    Rails.logger.debug("move #{srcFileName} to #{target.full_path}")
    FileUtils.mv(srcFileName, target.full_path)

    target
  end

  def initialize(filename, orig_filename, archive_folder = nil)
    @visible_filename = filename
    @orig_filename = orig_filename

    @archive_folder = if archive_folder.nil?
                        Time.now.year.to_s
                      else
                        archive_folder.to_s
                      end
  end

  def full_dir
    File.join(CORIKA_SETTINGS['documents_archive_dir'], @archive_folder)
  end

  def relative_filename
    File.join(@archive_folder, @orig_filename)
  end

  def full_path
    File.join(full_dir, @orig_filename)
  end

  def to_s
    full_path
  end
end
