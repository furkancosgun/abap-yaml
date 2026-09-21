CLASS lcl_ast_node DEFINITION FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES ty_t_nodes TYPE STANDARD TABLE OF REF TO lcl_ast_node WITH DEFAULT KEY.

    METHODS constructor
      IMPORTING iv_node_type TYPE zif_ayaml_types=>ty_node_type
                iv_value     TYPE string OPTIONAL
                iv_key       TYPE string OPTIONAL
                iv_line      TYPE i      OPTIONAL
                iv_column    TYPE i      OPTIONAL.

    METHODS add_child
      IMPORTING io_child TYPE REF TO lcl_ast_node.

    METHODS get_children
      RETURNING VALUE(rt_children) TYPE ty_t_nodes.

    METHODS get_key
      RETURNING VALUE(rv_key) TYPE string.

    METHODS set_key
      IMPORTING iv_key TYPE string.

    METHODS get_value
      RETURNING VALUE(rv_value) TYPE string.

    METHODS set_value
      IMPORTING iv_value TYPE string.

    METHODS get_type
      RETURNING VALUE(rv_type) TYPE zif_ayaml_types=>ty_node_type.

    METHODS get_anchor
      RETURNING VALUE(rv_anchor) TYPE string.

    METHODS set_anchor
      IMPORTING iv_anchor TYPE string.

    METHODS get_line
      RETURNING VALUE(rv_line) TYPE i.

    METHODS get_column
      RETURNING VALUE(rv_col) TYPE i.

    METHODS get_child_by_key
      IMPORTING iv_key         TYPE string
      RETURNING VALUE(ro_node) TYPE REF TO lcl_ast_node.

    METHODS clone
      RETURNING VALUE(ro_node) TYPE REF TO lcl_ast_node.

  PRIVATE SECTION.
    DATA mv_key      TYPE string.
    DATA mv_type     TYPE zif_ayaml_types=>ty_node_type.
    DATA mv_value    TYPE string.
    DATA mv_anchor   TYPE string.
    DATA mv_line     TYPE i.
    DATA mv_column   TYPE i.
    DATA mt_children TYPE ty_t_nodes.

ENDCLASS.


CLASS lcl_scanner DEFINITION FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING iv_yaml TYPE string.

    METHODS scan
      RETURNING VALUE(rt_tokens) TYPE zif_ayaml_types=>ty_t_tokens
      RAISING   zcx_ayaml_error.

  PRIVATE SECTION.
    DATA mv_source        TYPE string.
    DATA mv_len           TYPE i.
    DATA mv_pos           TYPE i.
    DATA mv_line          TYPE i.
    DATA mv_col           TYPE i.
    DATA mv_indent        TYPE i.
    DATA mv_is_line_start TYPE abap_bool.
    DATA mv_flow_depth    TYPE i.
    DATA mt_tokens        TYPE zif_ayaml_types=>ty_t_tokens.

    METHODS peek
      IMPORTING iv_offset      TYPE i DEFAULT 0
      RETURNING VALUE(rv_char) TYPE string.

    METHODS advance
      IMPORTING iv_count TYPE i DEFAULT 1.

    METHODS is_eof
      RETURNING VALUE(rv_yes) TYPE abap_bool.

    METHODS skip_spaces.

    METHODS scan_line_start
      RAISING zcx_ayaml_error.

    METHODS scan_single_quote
      RETURNING VALUE(rv_val) TYPE string
      RAISING   zcx_ayaml_error.

    METHODS scan_double_quote
      RETURNING VALUE(rv_val) TYPE string
      RAISING   zcx_ayaml_error.

    METHODS scan_block_scalar
      IMPORTING iv_indicator  TYPE string
      RETURNING VALUE(rv_val) TYPE string
      RAISING   zcx_ayaml_error.

    METHODS collect_block_lines
      IMPORTING iv_base_indent  TYPE i
      RETURNING VALUE(rt_lines) TYPE string_table.

    METHODS format_block_lines
      IMPORTING it_lines      TYPE string_table
                iv_indicator  TYPE string
                iv_chomping   TYPE string
      RETURNING VALUE(rv_val) TYPE string.

    METHODS scan_plain_scalar
      RETURNING VALUE(rv_val) TYPE string.

    METHODS scan_document_boundary
      IMPORTING iv_start_col  TYPE i
                iv_char       TYPE string
      RETURNING VALUE(rv_hit) TYPE abap_bool.

    METHODS scan_flow_token
      IMPORTING iv_char       TYPE string
                iv_start_line TYPE i
                iv_start_col  TYPE i
      RETURNING VALUE(rv_hit) TYPE abap_bool.

    METHODS scan_anchor_or_alias
      IMPORTING iv_char       TYPE string
                iv_start_line TYPE i
                iv_start_col  TYPE i
      RETURNING VALUE(rv_hit) TYPE abap_bool.

    METHODS emit_token
      IMPORTING iv_type   TYPE zif_ayaml_types=>ty_token_type
                iv_value  TYPE string
                iv_line   TYPE i OPTIONAL
                iv_column TYPE i OPTIONAL.

ENDCLASS.


CLASS lcl_ast_parser DEFINITION FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING it_tokens TYPE zif_ayaml_types=>ty_t_tokens.

    METHODS parse
      RETURNING VALUE(ro_root) TYPE REF TO lcl_ast_node
      RAISING   zcx_ayaml_error.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_s_anchor,
        name TYPE string,
        node TYPE REF TO lcl_ast_node,
      END OF ty_s_anchor,
      ty_t_anchors TYPE HASHED TABLE OF ty_s_anchor WITH UNIQUE KEY name.

    DATA mt_tokens  TYPE zif_ayaml_types=>ty_t_tokens.
    DATA mv_pos     TYPE i.
    DATA mv_count   TYPE i.
    DATA mt_anchors TYPE ty_t_anchors.

    METHODS is_eof
      RETURNING VALUE(rv_yes) TYPE abap_bool.

    METHODS current
      RETURNING VALUE(rs_token) TYPE zif_ayaml_types=>ty_s_token.

    METHODS advance.

    METHODS parse_node
      IMPORTING iv_indent      TYPE i
      RETURNING VALUE(ro_node) TYPE REF TO lcl_ast_node
      RAISING   zcx_ayaml_error.

    METHODS parse_block_mapping
      IMPORTING iv_indent      TYPE i
      RETURNING VALUE(ro_node) TYPE REF TO lcl_ast_node
      RAISING   zcx_ayaml_error.

    METHODS parse_block_sequence
      IMPORTING iv_indent      TYPE i
      RETURNING VALUE(ro_node) TYPE REF TO lcl_ast_node
      RAISING   zcx_ayaml_error.

    METHODS parse_flow_mapping
      RETURNING VALUE(ro_node) TYPE REF TO lcl_ast_node
      RAISING   zcx_ayaml_error.

    METHODS parse_flow_sequence
      RETURNING VALUE(ro_node) TYPE REF TO lcl_ast_node
      RAISING   zcx_ayaml_error.

    METHODS parse_scalar
      RETURNING VALUE(ro_node) TYPE REF TO lcl_ast_node.

    METHODS register_anchor
      IMPORTING iv_name TYPE string
                io_node TYPE REF TO lcl_ast_node.

    METHODS resolve_alias
      IMPORTING iv_name        TYPE string
      RETURNING VALUE(ro_node) TYPE REF TO lcl_ast_node
      RAISING   zcx_ayaml_error.

ENDCLASS.


CLASS lcl_ast_to_nodes DEFINITION FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS convert
      IMPORTING io_root         TYPE REF TO lcl_ast_node
      RETURNING VALUE(rt_nodes) TYPE zif_ayaml_types=>ty_t_nodes.

  PRIVATE SECTION.
    CLASS-METHODS traverse
      IMPORTING io_node  TYPE REF TO lcl_ast_node
                iv_path  TYPE string
                iv_name  TYPE string
                iv_index TYPE i
      CHANGING  ct_nodes TYPE zif_ayaml_types=>ty_t_nodes
                cv_order TYPE i.

ENDCLASS.


CLASS lcl_serializer DEFINITION FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS stringify
      IMPORTING it_nodes       TYPE zif_ayaml_types=>ty_t_nodes
                iv_indent      TYPE i DEFAULT 0
      RETURNING VALUE(rv_yaml) TYPE string
      RAISING   zcx_ayaml_error.

  PRIVATE SECTION.
    CLASS-METHODS build_yaml
      IMPORTING it_nodes       TYPE zif_ayaml_types=>ty_t_nodes
                iv_path        TYPE string
                iv_indent      TYPE i
      RETURNING VALUE(rv_yaml) TYPE string.

    CLASS-METHODS format_scalar
      IMPORTING is_node       TYPE zif_ayaml_types=>ty_s_node
      RETURNING VALUE(rv_out) TYPE string.

ENDCLASS.


CLASS lcl_deserializer DEFINITION FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS deserialize
      IMPORTING it_nodes TYPE zif_ayaml_types=>ty_t_nodes
      EXPORTING ev_data  TYPE any
      RAISING   zcx_ayaml_error.

  PRIVATE SECTION.
    CLASS-METHODS map_node
      IMPORTING it_nodes  TYPE zif_ayaml_types=>ty_t_nodes
                iv_path   TYPE string
      CHANGING  cv_target TYPE any
      RAISING   zcx_ayaml_error.

    CLASS-METHODS map_structure
      IMPORTING it_nodes  TYPE zif_ayaml_types=>ty_t_nodes
                iv_path   TYPE string
                io_struct TYPE REF TO cl_abap_structdescr
      CHANGING  cv_target TYPE any
      RAISING   zcx_ayaml_error.

    CLASS-METHODS map_table
      IMPORTING it_nodes  TYPE zif_ayaml_types=>ty_t_nodes
                iv_path   TYPE string
                io_table  TYPE REF TO cl_abap_tabledescr
      CHANGING  cv_target TYPE any
      RAISING   zcx_ayaml_error.

    CLASS-METHODS map_elementary
      IMPORTING is_node   TYPE zif_ayaml_types=>ty_s_node
                io_elem   TYPE REF TO cl_abap_elemdescr
      CHANGING  cv_target TYPE any
      RAISING   zcx_ayaml_error.

ENDCLASS.
