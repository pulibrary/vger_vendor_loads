class LoadProfile
  @@dir_prefix = ENV['VENDOR_FILE_PATH']
  def initialize(dir, code, emails, encoding = 'UTF-8')
    @in_dir = "#{@@dir_prefix}/#{dir}_input"
    @out_dir = "#{@@dir_prefix}/#{dir}_output"
    @error_dir = "#{@@dir_prefix}/#{dir}_error"
    @import_code = code
    @emails = emails
    @encoding = encoding
  end
  attr_accessor :in_dir, :out_dir, :error_dir, :import_code, :emails, :encoding
  def incoming_files
    Dir.glob("#{@in_dir}/*")
  end
  def has_files?
    Dir.glob("#{@in_dir}/*").size > 0
  end
end
