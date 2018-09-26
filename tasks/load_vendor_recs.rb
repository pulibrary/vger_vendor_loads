require_relative './../lib/vger_vendor_loads'
require 'fileutils'
require 'mail'
require 'psych'

Mail.defaults do
  delivery_method :sendmail
end

from_email = ENV['SYS_EMAIL']
import_command = ENV['BULK_IMPORT_COMMAND']
default_options = '-K ADDKEY'
operator_initials = ENV['VENDOR_LOAD_INITIALS']
err_email = ENV['VENDOR_ERR_EMAIL']
all_profiles = Psych.load_file(ENV['LOAD_PROFILE_FILE'])
all_profiles.each do |profile|
  load_profile = LoadProfile.new(profile['dir'], profile['code'], profile['emails'], profile['encoding'])
  to_email = load_profile.emails.join(',')
  load_profile.incoming_files.each do |file|
    filename = File.basename(file)
    utf_name = "#{load_profile.error_dir}/utf8#{filename}"
    f245_name = "#{load_profile.error_dir}/bad245#{filename}"
    f008_name = "#{load_profile.error_dir}/error008#{filename}"
    utf_flag = false
    inv_xml_flag = false
    f245_flag = false
    f008_flag = false
    not_marc = false
    no_recs = false
    reader = MARC::Reader.new(file, external_encoding: load_profile.encoding)
    record = nil
    begin
      record = reader.first
    rescue
      not_marc = true
    end
    if not_marc
      FileUtils.mv(file, "#{load_profile.out_dir}/nonmarc_#{filename}")
      subject = "non-MARC file #{filename} submitted for bulk load"
      message_body = "A non-MARC file was submitted for bulk load.\r\n\r\nFile: #{file}"
    else
      subject = "Error records from bulk load #{filename}"
      message_body = "Error records attached for #{filename}"
      proc_file = "#{load_profile.in_dir}/proc_#{filename}"
      out_file = "#{load_profile.out_dir}/proc_#{filename}"
      writer = MARC::Writer.new(proc_file)
      utf_name = "#{load_profile.error_dir}/utf8_#{filename}"
      xml_name = "#{load_profile.error_dir}/invxml_#{filename}"
      f245_name = "#{load_profile.error_dir}/bad245_#{filename}"
      f008_name = "#{load_profile.error_dir}/error008_#{filename}"
      bad_utf8_writer = MARC::Writer.new(utf_name)
      inv_xml_writer = MARC::Writer.new(xml_name)
      error_245_writer = MARC::Writer.new(f245_name)
      error_008_writer = MARC::Writer.new(f008_name)
      reader = MARC::Reader.new(file, external_encoding: load_profile.encoding)
      reader.each do |record|
        if bad_utf8?(record)
          bad_utf8_writer.write(bad_utf8_identify(record))
        end
        if invalid_xml_chars?(record)
          inv_xml_writer.write(invalid_xml_identify(record))
        end
        if multiple_no_245?(record)
          error_245_writer.write(record)
        elsif multiple_no_008?(record)
          error_008_writer.write(record)
        else
          record = clean_record(record)
          writer.write(record)
        end
      end
      writer.close
      bad_utf8_writer.close
      inv_xml_writer.close
      error_245_writer.close
      error_008_writer.close
      if File.size(utf_name) == 0 
        FileUtils.rm(utf_name)
      else
        utf_flag = true
      end
      if File.size(xml_name) == 0 
        FileUtils.rm(xml_name)
      else
        inv_xml_flag = true
      end
      if File.size(f245_name) == 0 
        FileUtils.rm(f245_name)
      else
        f245_flag = true
      end
      if File.size(f008_name) == 0 
        FileUtils.rm(f008_name)
      else
        f008_flag = true
      end
      if File.size(proc_file) == 0
        FileUtils.rm(proc_file)
        no_recs = true
        subject = "no valid records found in #{filename} submitted for bulk load"
        message_body = "No valid records were found in the file submitted for bulk load.\r\n\r\nFile: #{file}"
        FileUtils.mv(file, "#{load_profile.out_dir}/no_recs#{filename}")
      else
        full_command = import_command + ' ' + default_options + ' ' + '-i ' + load_profile.import_code + ' ' + '-o ' + operator_initials + ' ' + '-f ' + proc_file + ' -N ' + to_email
        puts full_command
        response = system(full_command)
        if response
          FileUtils.mv(proc_file, out_file)
          FileUtils.rm(file)
        end
      end
    end
    if utf_flag || inv_xml_flag || f245_flag || f008_flag || not_marc || no_recs
      puts 'there were errors'
      puts subject
      puts message_body
      Mail.deliver do
        from        "#{from_email}"
        to	        "#{err_email}"
        subject     "#{subject}"
        body        "#{message_body}"
        add_file utf_name if utf_flag
        add_file xml_name if inv_xml_flag
        add_file f245_name if f245_flag
        add_file f008_name if f008_flag
      end
    end
  end
end
