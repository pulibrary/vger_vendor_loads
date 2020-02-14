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

### All Mary Martin materials are books
def mary_martin_generic_008_value(date_val)
  string = ''
  string << date_val # date entered
  string << 'n' # date type unknown
  string << 'uuuu' # date1 unknown
  string << 'uuuu' # date2 unknown
  string << 'xx ' # unknown pub place
  string << '||||' # illustrations no attempt
  string << ' ' # unknown audience
  string << ' ' # not microform, online, etc.
  string << '    ' # unspecified nature of contents
  string << 'u' # unknown gov pub status
  string << '|' # no attempt to code for conference publication
  string << '|' # no attempt to code for festschrift
  string << '|' # no attempt to code for index present
  string << ' ' # position 32 is undefined
  string << '0' # literary form not fiction
  string << '|' # no attempt to code for biography
  string << '   ' # no info provided on language
  string << '|' # no attempt to code for romanization of the item info
  string << 'd' # cataloging source is 'Other'
  string
end

### Make generic 008 if 008 length is incorrect (for Mary Martin);
###   date_val is yymmdd
def mary_martin_008(record, date_val)
  f008 = record.fields('008')
  if f008.size > 1
    f008[1..-1].each do |field|
      index = record.fields.index(field)
      record.fields.delete(index)
    end
  elsif f008.empty?
    f008_val = mary_martin_generic_008_value(date_val)
    field = MARC::ControlField.new('008', f008_val)
    first_variable_field = record.fields.index { |field| field.class == 'MARC::DataField' }
    record.fields.insert(first_variable_field, field)
  else
    index = record.fields.index(f008.first)
    record.fields[index].value = mary_martin_generic_008_value(date_val)
  end
  record
end
