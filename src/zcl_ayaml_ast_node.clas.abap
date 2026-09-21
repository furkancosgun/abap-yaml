CLASS zcl_ayaml_ast_node DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES ty_t_nodes TYPE STANDARD TABLE OF REF TO zcl_ayaml_ast_node WITH EMPTY KEY.

    METHODS constructor
      IMPORTING iv_node_type TYPE zif_ayaml_types=>ty_node_type
                iv_value     TYPE string OPTIONAL
                iv_key       TYPE string OPTIONAL
                iv_line      TYPE i      OPTIONAL
                iv_column    TYPE i      OPTIONAL.

    METHODS get_node_type
      RETURNING VALUE(rv_type) TYPE zif_ayaml_types=>ty_node_type.

    METHODS set_node_type
      IMPORTING iv_type TYPE zif_ayaml_types=>ty_node_type.

    METHODS get_key
      RETURNING VALUE(rv_key) TYPE string.

    METHODS set_key
      IMPORTING iv_key TYPE string.

    METHODS get_value
      RETURNING VALUE(rv_value) TYPE string.

    METHODS set_value
      IMPORTING iv_value TYPE string.

    METHODS get_anchor
      RETURNING VALUE(rv_anchor) TYPE string.

    METHODS set_anchor
      IMPORTING iv_anchor TYPE string.

    METHODS get_tag
      RETURNING VALUE(rv_tag) TYPE string.

    METHODS set_tag
      IMPORTING iv_tag TYPE string.

    METHODS get_line
      RETURNING VALUE(rv_line) TYPE i.

    METHODS get_column
      RETURNING VALUE(rv_column) TYPE i.

    METHODS get_children
      RETURNING VALUE(rt_children) TYPE ty_t_nodes.

    METHODS add_child
      IMPORTING io_child TYPE REF TO zcl_ayaml_ast_node.

    METHODS get_child
      IMPORTING iv_index        TYPE i
      RETURNING VALUE(ro_child) TYPE REF TO zcl_ayaml_ast_node.

    METHODS get_child_by_key
      IMPORTING iv_key          TYPE string
      RETURNING VALUE(ro_child) TYPE REF TO zcl_ayaml_ast_node.

    METHODS clone
      RETURNING VALUE(ro_clone) TYPE REF TO zcl_ayaml_ast_node.

  PRIVATE SECTION.
    DATA mv_node_type TYPE zif_ayaml_types=>ty_node_type.
    DATA mv_key       TYPE string.
    DATA mv_value     TYPE string.
    DATA mv_anchor    TYPE string.
    DATA mv_tag       TYPE string.
    DATA mv_line      TYPE i.
    DATA mv_column    TYPE i.
    DATA mt_children  TYPE ty_t_nodes.

ENDCLASS.


CLASS zcl_ayaml_ast_node IMPLEMENTATION.

  METHOD constructor.
    mv_node_type = iv_node_type.
    mv_value     = iv_value.
    mv_key       = iv_key.
    mv_line      = iv_line.
    mv_column    = iv_column.
  ENDMETHOD.

  METHOD get_node_type.
    rv_type = mv_node_type.
  ENDMETHOD.

  METHOD set_node_type.
    mv_node_type = iv_type.
  ENDMETHOD.

  METHOD get_key.
    rv_key = mv_key.
  ENDMETHOD.

  METHOD set_key.
    mv_key = iv_key.
  ENDMETHOD.

  METHOD get_value.
    rv_value = mv_value.
  ENDMETHOD.

  METHOD set_value.
    mv_value = iv_value.
  ENDMETHOD.

  METHOD get_anchor.
    rv_anchor = mv_anchor.
  ENDMETHOD.

  METHOD set_anchor.
    mv_anchor = iv_anchor.
  ENDMETHOD.

  METHOD get_tag.
    rv_tag = mv_tag.
  ENDMETHOD.

  METHOD set_tag.
    mv_tag = iv_tag.
  ENDMETHOD.

  METHOD get_line.
    rv_line = mv_line.
  ENDMETHOD.

  METHOD get_column.
    rv_column = mv_column.
  ENDMETHOD.

  METHOD get_children.
    rt_children = mt_children.
  ENDMETHOD.

  METHOD add_child.
    INSERT io_child INTO TABLE mt_children.
  ENDMETHOD.

  METHOD get_child.
    READ TABLE mt_children INDEX iv_index INTO ro_child.
    IF sy-subrc <> 0.
      CLEAR ro_child.
    ENDIF.
  ENDMETHOD.

  METHOD get_child_by_key.
    DATA lo_child TYPE REF TO zcl_ayaml_ast_node.
    LOOP AT mt_children INTO lo_child.
      IF lo_child->get_key( ) = iv_key.
        ro_child = lo_child.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD clone.
    DATA lo_child       TYPE REF TO zcl_ayaml_ast_node.
    DATA lo_child_clone TYPE REF TO zcl_ayaml_ast_node.

    ro_clone = NEW #(
      iv_node_type = mv_node_type
      iv_value     = mv_value
      iv_key       = mv_key
      iv_line      = mv_line
      iv_column    = mv_column ).

    ro_clone->set_anchor( mv_anchor ).
    ro_clone->set_tag( mv_tag ).

    LOOP AT mt_children INTO lo_child.
      lo_child_clone = lo_child->clone( ).
      ro_clone->add_child( lo_child_clone ).
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
