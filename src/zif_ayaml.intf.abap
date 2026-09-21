INTERFACE zif_ayaml PUBLIC.

  METHODS is_empty
    RETURNING VALUE(rv_yes) TYPE abap_bool.

  METHODS exists
    IMPORTING iv_path       TYPE string
    RETURNING VALUE(rv_yes) TYPE abap_bool.

  METHODS get
    IMPORTING iv_path         TYPE string
    RETURNING VALUE(rv_value) TYPE string.

  METHODS get_string
    IMPORTING iv_path         TYPE string
    RETURNING VALUE(rv_value) TYPE string.

  METHODS get_integer
    IMPORTING iv_path         TYPE string
    RETURNING VALUE(rv_value) TYPE i.

  METHODS get_number
    IMPORTING iv_path         TYPE string
    RETURNING VALUE(rv_value) TYPE f.

  METHODS get_boolean
    IMPORTING iv_path         TYPE string
    RETURNING VALUE(rv_value) TYPE abap_bool.

  METHODS get_date
    IMPORTING iv_path        TYPE string
    RETURNING VALUE(rv_date) TYPE d.

  METHODS get_timestamp
    IMPORTING iv_path             TYPE string
    RETURNING VALUE(rv_timestamp) TYPE timestamp.

  METHODS get_node
    IMPORTING iv_path        TYPE string
    RETURNING VALUE(rs_node) TYPE zif_ayaml_types=>ty_s_node.

  METHODS get_node_type
    IMPORTING iv_path             TYPE string
    RETURNING VALUE(rv_node_type) TYPE zif_ayaml_types=>ty_node_type.

  METHODS members
    IMPORTING iv_path           TYPE string DEFAULT '/'
    RETURNING VALUE(rt_members) TYPE zif_ayaml_types=>ty_t_string.

  METHODS slice
    IMPORTING iv_path            TYPE string
    RETURNING VALUE(ri_fragment) TYPE REF TO zif_ayaml
    RAISING   zcx_ayaml_error.

  METHODS clone
    RETURNING VALUE(ri_ayaml) TYPE REF TO zif_ayaml
    RAISING   zcx_ayaml_error.

  METHODS clear
    RETURNING VALUE(ri_self) TYPE REF TO zif_ayaml
    RAISING   zcx_ayaml_error.

  METHODS set
    IMPORTING iv_path         TYPE string
              iv_val          TYPE any
              iv_node_type    TYPE zif_ayaml_types=>ty_node_type OPTIONAL
              iv_ignore_empty TYPE abap_bool                     DEFAULT abap_true
    RETURNING VALUE(ri_self)  TYPE REF TO zif_ayaml
    RAISING   zcx_ayaml_error.

  METHODS set_boolean
    IMPORTING iv_path        TYPE string
              iv_val         TYPE any
    RETURNING VALUE(ri_self) TYPE REF TO zif_ayaml
    RAISING   zcx_ayaml_error.

  METHODS set_string
    IMPORTING iv_path        TYPE string
              iv_val         TYPE clike
    RETURNING VALUE(ri_self) TYPE REF TO zif_ayaml
    RAISING   zcx_ayaml_error.

  METHODS set_integer
    IMPORTING iv_path        TYPE string
              iv_val         TYPE i
    RETURNING VALUE(ri_self) TYPE REF TO zif_ayaml
    RAISING   zcx_ayaml_error.

  METHODS set_number
    IMPORTING iv_path        TYPE string
              iv_val         TYPE f
    RETURNING VALUE(ri_self) TYPE REF TO zif_ayaml
    RAISING   zcx_ayaml_error.

  METHODS set_date
    IMPORTING iv_path        TYPE string
              iv_val         TYPE d
    RETURNING VALUE(ri_self) TYPE REF TO zif_ayaml
    RAISING   zcx_ayaml_error.

  METHODS set_timestamp
    IMPORTING iv_path        TYPE string
              iv_val         TYPE timestamp
    RETURNING VALUE(ri_self) TYPE REF TO zif_ayaml
    RAISING   zcx_ayaml_error.

  METHODS set_null
    IMPORTING iv_path        TYPE string
    RETURNING VALUE(ri_self) TYPE REF TO zif_ayaml
    RAISING   zcx_ayaml_error.

  METHODS delete
    IMPORTING iv_path        TYPE string
    RETURNING VALUE(ri_self) TYPE REF TO zif_ayaml.

  METHODS touch_array
    IMPORTING iv_path        TYPE string
              iv_clear       TYPE abap_bool DEFAULT abap_false
    RETURNING VALUE(ri_self) TYPE REF TO zif_ayaml
    RAISING   zcx_ayaml_error.

  METHODS push
    IMPORTING iv_path        TYPE string
              iv_val         TYPE any
    RETURNING VALUE(ri_self) TYPE REF TO zif_ayaml
    RAISING   zcx_ayaml_error.

  METHODS stringify
    IMPORTING iv_indent      TYPE i DEFAULT 0
    RETURNING VALUE(rv_yaml) TYPE string
    RAISING   zcx_ayaml_error.

ENDINTERFACE.
