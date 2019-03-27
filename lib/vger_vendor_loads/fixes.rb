require 'marc_cleanup'

def clean_record(record)
  record = bad_utf8_fix(record)
  record = empty_subfield_fix(record)
  record = leaderfix(record)
  record = tab_newline_fix(record)
  record = extra_space_fix(record)
  record = composed_chars_normalize(record)
  record = fix_008(record)
  record = invalid_xml_fix(record)
  record
end

def harrslav_fix(record)
  return record unless record['990'] && record['990']['i']
  field = record['990']
  field_index = record.fields.index(field)
  subf_index = field.subfields.index { |subfield| subfield.code == 'i' }
  subf_val = field['i'].gsub(/USD/, '').strip
  record.fields[field_index].subfields[subf_index].value = subf_val
  record
end
