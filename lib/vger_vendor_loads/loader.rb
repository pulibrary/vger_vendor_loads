require 'marc_cleanup'

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
    Dir.glob("#{@in_dir}/*.*")
  end
  def has_files?
    Dir.glob("#{@in_dir}/*.*").size > 0
  end
end

def clean_record(record)
  empty_subfield = false
  leader_error = false
  tab_newline = false
  extra_space = false
  composed_chars = false
  f008 = false
  utf8 = false
  xml = false
  if empty_subfields?(record)
    record = empty_subfield_fix(record)
    empty_subfield = true
  end
  if leader_errors?(record)
    record = leaderfix(record)
    leader_error = true
  end
  if tab_newline_char?(record)
    record = tab_newline_fix(record)
    tab_newline = true
  end
  record = extra_space_fix(record)
  record = composed_chars_normalize(record)
  record = fix_008(record)
  record = bad_utf8_fix(record)
  record = invalid_xml_fix(record)
  record
end
