INTERFACE zif_ayaml_writer PUBLIC.

  METHODS set
    IMPORTING iv_path         TYPE string
              iv_val          TYPE any
              iv_node_type    TYPE zif_ayaml_types=>ty_node_type OPTIONAL
              iv_ignore_empty TYPE abap_bool                     DEFAULT abap_true
    RETURNING VALUE(ri_self)  TYPE REF TO zif_ayaml_writer
    RAISING   zcx_ayaml_error.

  METHODS set_boolean
    IMPORTING iv_path        TYPE string
              iv_val         TYPE any
    RETURNING VALUE(ri_self) TYPE REF TO zif_ayaml_writer
    RAISING   zcx_ayaml_error.

  METHODS set_string
    IMPORTING iv_path        TYPE string
              iv_val         TYPE clike
    RETURNING VALUE(ri_self) TYPE REF TO zif_ayaml_writer
    RAISING   zcx_ayaml_error.

  METHODS set_integer
    IMPORTING iv_path        TYPE string
              iv_val         TYPE i
    RETURNING VALUE(ri_self) TYPE REF TO zif_ayaml_writer
    RAISING   zcx_ayaml_error.

  METHODS set_number
    IMPORTING iv_path        TYPE string
              iv_val         TYPE f
    RETURNING VALUE(ri_self) TYPE REF TO zif_ayaml_writer
    RAISING   zcx_ayaml_error.

  METHODS set_date
    IMPORTING iv_path        TYPE string
              iv_val         TYPE d
    RETURNING VALUE(ri_self) TYPE REF TO zif_ayaml_writer
    RAISING   zcx_ayaml_error.

  METHODS set_timestamp
    IMPORTING iv_path        TYPE string
              iv_val         TYPE timestamp
    RETURNING VALUE(ri_self) TYPE REF TO zif_ayaml_writer
    RAISING   zcx_ayaml_error.

  METHODS set_null
    IMPORTING iv_path        TYPE string
    RETURNING VALUE(ri_self) TYPE REF TO zif_ayaml_writer
    RAISING   zcx_ayaml_error.

  METHODS delete
    IMPORTING iv_path        TYPE string
    RETURNING VALUE(ri_self) TYPE REF TO zif_ayaml_writer.

  METHODS clear
    RETURNING VALUE(ri_self) TYPE REF TO zif_ayaml_writer
    RAISING   zcx_ayaml_error.

  METHODS ensure_sequence
    IMPORTING iv_path        TYPE string
              iv_clear       TYPE abap_bool DEFAULT abap_false
    RETURNING VALUE(ri_self) TYPE REF TO zif_ayaml_writer
    RAISING   zcx_ayaml_error.

  METHODS append_to_sequence
    IMPORTING iv_path        TYPE string
              iv_val         TYPE any
    RETURNING VALUE(ri_self) TYPE REF TO zif_ayaml_writer
    RAISING   zcx_ayaml_error.

ENDINTERFACE.
