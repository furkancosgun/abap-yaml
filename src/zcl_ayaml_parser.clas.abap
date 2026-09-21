CLASS zcl_ayaml_parser DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS parse
      IMPORTING iv_yaml         TYPE string
      RETURNING VALUE(rt_nodes) TYPE zif_ayaml_types=>ty_t_nodes
      RAISING   zcx_ayaml_error.

ENDCLASS.


CLASS zcl_ayaml_parser IMPLEMENTATION.

  METHOD parse.
    DATA lo_scanner TYPE REF TO zcl_ayaml_scanner.
    DATA lt_tokens  TYPE zif_ayaml_types=>ty_t_tokens.
    DATA lo_parser  TYPE REF TO zcl_ayaml_ast_parser.
    DATA lo_ast     TYPE REF TO zcl_ayaml_ast_node.

    IF iv_yaml IS INITIAL.
      CLEAR rt_nodes.
      RETURN.
    ENDIF.

    lo_scanner = NEW #( iv_yaml ).
    lt_tokens  = lo_scanner->scan( ).

    lo_parser  = NEW #( lt_tokens ).
    lo_ast     = lo_parser->parse( ).

    rt_nodes   = zcl_ayaml_ast_to_nodes=>convert( lo_ast ).
  ENDMETHOD.

ENDCLASS.
