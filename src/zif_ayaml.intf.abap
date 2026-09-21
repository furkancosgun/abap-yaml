INTERFACE zif_ayaml PUBLIC.

  INTERFACES zif_ayaml_reader.
  INTERFACES zif_ayaml_writer.

  ALIASES is_empty FOR zif_ayaml_reader~is_empty.
  ALIASES exists FOR zif_ayaml_reader~exists.
  ALIASES get FOR zif_ayaml_reader~get.
  ALIASES get_string FOR zif_ayaml_reader~get_string.
  ALIASES get_integer FOR zif_ayaml_reader~get_integer.
  ALIASES get_number FOR zif_ayaml_reader~get_number.
  ALIASES get_boolean FOR zif_ayaml_reader~get_boolean.
  ALIASES get_date FOR zif_ayaml_reader~get_date.
  ALIASES get_timestamp FOR zif_ayaml_reader~get_timestamp.
  ALIASES get_node FOR zif_ayaml_reader~get_node.
  ALIASES get_node_type FOR zif_ayaml_reader~get_node_type.
  ALIASES get_keys FOR zif_ayaml_reader~get_keys.
  ALIASES members FOR zif_ayaml_reader~get_keys.
  ALIASES array_length FOR zif_ayaml_reader~array_length.
  ALIASES get_string_table FOR zif_ayaml_reader~get_string_table.
  ALIASES to_abap FOR zif_ayaml_reader~to_abap.
  ALIASES to_yaml FOR zif_ayaml_reader~to_yaml.
  ALIASES stringify FOR zif_ayaml_reader~to_yaml.
  ALIASES slice FOR zif_ayaml_reader~slice.

  ALIASES set FOR zif_ayaml_writer~set.
  ALIASES set_boolean FOR zif_ayaml_writer~set_boolean.
  ALIASES set_string FOR zif_ayaml_writer~set_string.
  ALIASES set_integer FOR zif_ayaml_writer~set_integer.
  ALIASES set_number FOR zif_ayaml_writer~set_number.
  ALIASES set_date FOR zif_ayaml_writer~set_date.
  ALIASES set_timestamp FOR zif_ayaml_writer~set_timestamp.
  ALIASES set_null FOR zif_ayaml_writer~set_null.
  ALIASES delete FOR zif_ayaml_writer~delete.
  ALIASES clear FOR zif_ayaml_writer~clear.
  ALIASES ensure_sequence FOR zif_ayaml_writer~ensure_sequence.
  ALIASES touch_array FOR zif_ayaml_writer~ensure_sequence.
  ALIASES append_to_sequence FOR zif_ayaml_writer~append_to_sequence.
  ALIASES push FOR zif_ayaml_writer~append_to_sequence.

  METHODS clone
    RETURNING VALUE(ri_ayaml) TYPE REF TO zif_ayaml
    RAISING   zcx_ayaml_error.

ENDINTERFACE.
