require 'marc_cleanup'

def clean_record(record)
  record = bad_utf8_fix(record)
  record = empty_subfield_fix(record)
  record = leaderfix(record)
  record = tab_newline_fix(record)
  record = extra_space_fix(record)
  record = composed_chars_normalize(record)
  record = fix_008(record)
  record = fix_007(record)
  record = fix_006(record)
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

### Date_val is in the format yyyymmdd
def gobi_904(record, operator_initials, date_val)
  f904 = MARC::DataField.new('904', ' ', ' ')
  f904.append(MARC::Subfield.new('a', operator_initials))
  f904.append(MARC::Subfield.new('b', 'o'))
  f904.append(MARC::Subfield.new('h', 'm'))
  f904.append(MARC::Subfield.new('c', 'b'))
  f904.append(MARC::Subfield.new('e', date_val))
  record.append(f904)
  record
end
