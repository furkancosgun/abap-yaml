INTERFACE zif_ayaml PUBLIC.

  METHODS is_empty
    RETURNING VALUE(rv_result) TYPE abap_bool.

  METHODS exists
    IMPORTING iv_path          TYPE string
    RETURNING VALUE(rv_result) TYPE abap_bool.

  METHODS get
    IMPORTING iv_path          TYPE string
              iv_default       TYPE string OPTIONAL
    RETURNING VALUE(rv_result) TYPE string.

  METHODS get_string
    IMPORTING iv_path          TYPE string
              iv_default       TYPE string OPTIONAL
    RETURNING VALUE(rv_result) TYPE string.

  METHODS get_integer
    IMPORTING iv_path          TYPE string
              iv_default       TYPE i OPTIONAL
    RETURNING VALUE(rv_result) TYPE i.

  METHODS get_number
    IMPORTING iv_path          TYPE string
              iv_default       TYPE f OPTIONAL
    RETURNING VALUE(rv_result) TYPE f.

  METHODS get_boolean
    IMPORTING iv_path          TYPE string
              iv_default       TYPE abap_bool OPTIONAL
    RETURNING VALUE(rv_result) TYPE abap_bool.

  METHODS get_date
    IMPORTING iv_path          TYPE string
              iv_default       TYPE d OPTIONAL
    RETURNING VALUE(rv_result) TYPE d.

  METHODS get_timestamp
    IMPORTING iv_path          TYPE string
              iv_default       TYPE timestamp OPTIONAL
    RETURNING VALUE(rv_result) TYPE timestamp.

  METHODS get_node
    IMPORTING iv_path          TYPE string
    RETURNING VALUE(rs_result) TYPE zif_ayaml_types=>ty_s_node.

  METHODS get_node_type
    IMPORTING iv_path          TYPE string
    RETURNING VALUE(rv_result) TYPE zif_ayaml_types=>ty_node_type.

  METHODS get_keys
    IMPORTING iv_path          TYPE string DEFAULT '/'
    RETURNING VALUE(rt_result) TYPE zif_ayaml_types=>ty_t_string.

  METHODS get_array_length
    IMPORTING iv_path          TYPE string
    RETURNING VALUE(rv_result) TYPE i.

  METHODS get_string_table
    IMPORTING iv_path          TYPE string
    RETURNING VALUE(rt_result) TYPE string_table.

  METHODS to_abap
    EXPORTING ev_data TYPE any
    RAISING   zcx_ayaml_error.

  METHODS to_yaml
    IMPORTING iv_indent        TYPE i DEFAULT 0
    RETURNING VALUE(rv_result) TYPE string
    RAISING   zcx_ayaml_error.

  METHODS slice
    IMPORTING iv_path            TYPE string
    RETURNING VALUE(ro_instance) TYPE REF TO zif_ayaml
    RAISING   zcx_ayaml_error.

  METHODS set
    IMPORTING iv_path            TYPE string
              iv_value           TYPE any
              iv_node_type       TYPE zif_ayaml_types=>ty_node_type OPTIONAL
    RETURNING VALUE(ro_instance) TYPE REF TO zif_ayaml
    RAISING   zcx_ayaml_error.

  METHODS set_boolean
    IMPORTING iv_path            TYPE string
              iv_value           TYPE any
    RETURNING VALUE(ro_instance) TYPE REF TO zif_ayaml
    RAISING   zcx_ayaml_error.

  METHODS set_string
    IMPORTING iv_path            TYPE string
              iv_value           TYPE clike
    RETURNING VALUE(ro_instance) TYPE REF TO zif_ayaml
    RAISING   zcx_ayaml_error.

  METHODS set_integer
    IMPORTING iv_path            TYPE string
              iv_value           TYPE i
    RETURNING VALUE(ro_instance) TYPE REF TO zif_ayaml
    RAISING   zcx_ayaml_error.

  METHODS set_number
    IMPORTING iv_path            TYPE string
              iv_value           TYPE f
    RETURNING VALUE(ro_instance) TYPE REF TO zif_ayaml
    RAISING   zcx_ayaml_error.

  METHODS set_date
    IMPORTING iv_path            TYPE string
              iv_value           TYPE d
    RETURNING VALUE(ro_instance) TYPE REF TO zif_ayaml
    RAISING   zcx_ayaml_error.

  METHODS set_timestamp
    IMPORTING iv_path            TYPE string
              iv_value           TYPE timestamp
    RETURNING VALUE(ro_instance) TYPE REF TO zif_ayaml
    RAISING   zcx_ayaml_error.

  METHODS set_null
    IMPORTING iv_path            TYPE string
    RETURNING VALUE(ro_instance) TYPE REF TO zif_ayaml
    RAISING   zcx_ayaml_error.

  METHODS delete
    IMPORTING iv_path            TYPE string
    RETURNING VALUE(ro_instance) TYPE REF TO zif_ayaml.

  METHODS clear
    RETURNING VALUE(ro_instance) TYPE REF TO zif_ayaml
    RAISING   zcx_ayaml_error.

  METHODS init_array
    IMPORTING iv_path            TYPE string
              iv_clear           TYPE abap_bool DEFAULT abap_false
    RETURNING VALUE(ro_instance) TYPE REF TO zif_ayaml
    RAISING   zcx_ayaml_error.

  METHODS push
    IMPORTING iv_path            TYPE string
              iv_value           TYPE any
    RETURNING VALUE(ro_instance) TYPE REF TO zif_ayaml
    RAISING   zcx_ayaml_error.

  METHODS clone
    RETURNING VALUE(ro_instance) TYPE REF TO zif_ayaml
    RAISING   zcx_ayaml_error.

ENDINTERFACE.
