INTERFACE zif_ayaml_reader PUBLIC.

  METHODS is_empty
    RETURNING VALUE(rv_yes) TYPE abap_bool.

  METHODS exists
    IMPORTING iv_path       TYPE string
    RETURNING VALUE(rv_yes) TYPE abap_bool.

  METHODS get
    IMPORTING iv_path         TYPE string
              iv_default      TYPE string OPTIONAL
    RETURNING VALUE(rv_value) TYPE string.

  METHODS get_string
    IMPORTING iv_path         TYPE string
              iv_default      TYPE string OPTIONAL
    RETURNING VALUE(rv_value) TYPE string.

  METHODS get_integer
    IMPORTING iv_path         TYPE string
              iv_default      TYPE i OPTIONAL
    RETURNING VALUE(rv_value) TYPE i.

  METHODS get_number
    IMPORTING iv_path         TYPE string
              iv_default      TYPE f OPTIONAL
    RETURNING VALUE(rv_value) TYPE f.

  METHODS get_boolean
    IMPORTING iv_path         TYPE string
              iv_default      TYPE abap_bool OPTIONAL
    RETURNING VALUE(rv_value) TYPE abap_bool.

  METHODS get_date
    IMPORTING iv_path        TYPE string
              iv_default     TYPE d OPTIONAL
    RETURNING VALUE(rv_date) TYPE d.

  METHODS get_timestamp
    IMPORTING iv_path             TYPE string
              iv_default          TYPE timestamp OPTIONAL
    RETURNING VALUE(rv_timestamp) TYPE timestamp.

  METHODS get_node
    IMPORTING iv_path        TYPE string
    RETURNING VALUE(rs_node) TYPE zif_ayaml_types=>ty_s_node.

  METHODS get_node_type
    IMPORTING iv_path             TYPE string
    RETURNING VALUE(rv_node_type) TYPE zif_ayaml_types=>ty_node_type.

  METHODS get_keys
    IMPORTING iv_path        TYPE string DEFAULT '/'
    RETURNING VALUE(rt_keys) TYPE zif_ayaml_types=>ty_t_string.

  METHODS array_length
    IMPORTING iv_path          TYPE string
    RETURNING VALUE(rv_length) TYPE i.

  METHODS get_string_table
    IMPORTING iv_path          TYPE string
    RETURNING VALUE(rt_values) TYPE string_table.

  METHODS to_abap
    EXPORTING ev_data TYPE any
    RAISING   zcx_ayaml_error.

  METHODS to_yaml
    IMPORTING iv_indent      TYPE i DEFAULT 0
    RETURNING VALUE(rv_yaml) TYPE string
    RAISING   zcx_ayaml_error.

  METHODS slice
    IMPORTING iv_path            TYPE string
    RETURNING VALUE(ri_fragment) TYPE REF TO zif_ayaml
    RAISING   zcx_ayaml_error.

ENDINTERFACE.
