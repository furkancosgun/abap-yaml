CLASS zcl_ayaml_ast_parser DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING it_tokens TYPE zif_ayaml_types=>ty_t_tokens.

    METHODS parse
      RETURNING VALUE(ro_root) TYPE REF TO zcl_ayaml_ast_node
      RAISING   zcx_ayaml_error.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_s_anchor,
        name TYPE string,
        node TYPE REF TO zcl_ayaml_ast_node,
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
      RETURNING VALUE(ro_node) TYPE REF TO zcl_ayaml_ast_node
      RAISING   zcx_ayaml_error.

    METHODS parse_block_mapping
      IMPORTING iv_indent      TYPE i
      RETURNING VALUE(ro_node) TYPE REF TO zcl_ayaml_ast_node
      RAISING   zcx_ayaml_error.

    METHODS parse_block_sequence
      IMPORTING iv_indent      TYPE i
      RETURNING VALUE(ro_node) TYPE REF TO zcl_ayaml_ast_node
      RAISING   zcx_ayaml_error.

    METHODS parse_flow_mapping
      RETURNING VALUE(ro_node) TYPE REF TO zcl_ayaml_ast_node
      RAISING   zcx_ayaml_error.

    METHODS parse_flow_sequence
      RETURNING VALUE(ro_node) TYPE REF TO zcl_ayaml_ast_node
      RAISING   zcx_ayaml_error.

    METHODS parse_scalar
      RETURNING VALUE(ro_node) TYPE REF TO zcl_ayaml_ast_node.

    METHODS detect_scalar_type
      IMPORTING iv_val         TYPE string
      EXPORTING ev_type        TYPE zif_ayaml_types=>ty_node_type
                ev_val         TYPE string.

    METHODS register_anchor
      IMPORTING iv_name TYPE string
                io_node TYPE REF TO zcl_ayaml_ast_node.

    METHODS resolve_alias
      IMPORTING iv_name        TYPE string
      RETURNING VALUE(ro_node) TYPE REF TO zcl_ayaml_ast_node
      RAISING   zcx_ayaml_error.

ENDCLASS.


CLASS zcl_ayaml_ast_parser IMPLEMENTATION.

  METHOD constructor.
    mt_tokens = it_tokens.
    mv_pos    = 1.
    mv_count  = lines( mt_tokens ).
  ENDMETHOD.

  METHOD is_eof.
    DATA ls_tk TYPE zif_ayaml_types=>ty_s_token.
    IF mv_pos > mv_count.
      rv_yes = abap_true.
    ELSE.

      READ TABLE mt_tokens INDEX mv_pos INTO ls_tk.
      IF sy-subrc = 0 AND ls_tk-type = zif_ayaml_types=>cs_token_type-eof.
        rv_yes = abap_true.
      ELSE.
        rv_yes = abap_false.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD current.
    IF mv_pos <= mv_count.
      READ TABLE mt_tokens INDEX mv_pos INTO rs_token.
      IF sy-subrc <> 0.
        CLEAR rs_token.
      ENDIF.
    ELSE.
      rs_token-type = zif_ayaml_types=>cs_token_type-eof.
    ENDIF.
  ENDMETHOD.



  METHOD advance.
    mv_pos += 1.
  ENDMETHOD.

  METHOD register_anchor.
    DATA ls_anchor TYPE ty_s_anchor.
    ls_anchor-name = iv_name.
    ls_anchor-node = io_node.
    INSERT ls_anchor INTO TABLE mt_anchors.
  ENDMETHOD.

  METHOD resolve_alias.
    DATA ls_anchor TYPE ty_s_anchor.
    READ TABLE mt_anchors WITH TABLE KEY name = iv_name INTO ls_anchor.
    IF sy-subrc = 0.
      ro_node = ls_anchor-node->clone( ).
    ELSE.
      RAISE EXCEPTION NEW zcx_ayaml_error( iv_msg = |Undefined alias: *{ iv_name }| ).
    ENDIF.
  ENDMETHOD.

  METHOD detect_scalar_type.
    DATA lv_lower TYPE string.
    lv_lower = to_lower( iv_val ).

    IF lv_lower = `true` OR lv_lower = `false`.
      ev_type = zif_ayaml_types=>cs_type-boolean.
      ev_val  = lv_lower.
      RETURN.
    ENDIF.

    IF lv_lower = `null` OR lv_lower = `~` OR iv_val IS INITIAL.
      ev_type = zif_ayaml_types=>cs_type-null.
      ev_val  = `null`.
      RETURN.
    ENDIF.

    FIND REGEX `^\d{4}-\d{2}-\d{2}$` IN iv_val.
    IF sy-subrc = 0.
      ev_type = zif_ayaml_types=>cs_type-date.
      ev_val  = iv_val.
      RETURN.
    ENDIF.

    FIND REGEX `^[+-]?\d+$` IN iv_val.
    IF sy-subrc = 0.
      ev_type = zif_ayaml_types=>cs_type-number.
      ev_val  = iv_val.
      RETURN.
    ENDIF.

    FIND REGEX `^[+-]?\d+\.\d+([eE][+-]?\d+)?$` IN iv_val.
    IF sy-subrc = 0.
      ev_type = zif_ayaml_types=>cs_type-number.
      ev_val  = iv_val.
      RETURN.
    ENDIF.

    ev_type = zif_ayaml_types=>cs_type-string.
    ev_val  = iv_val.
  ENDMETHOD.

  METHOD parse_scalar.
    DATA ls_tk   TYPE zif_ayaml_types=>ty_s_token.
    DATA lv_type TYPE zif_ayaml_types=>ty_node_type.
    DATA lv_val  TYPE string.

    ls_tk = current( ).
    advance( ).

    detect_scalar_type( EXPORTING iv_val  = ls_tk-value
                        IMPORTING ev_type = lv_type
                                  ev_val  = lv_val ).

    ro_node = NEW #(
      iv_node_type = lv_type
      iv_value     = lv_val
      iv_line      = ls_tk-line
      iv_column    = ls_tk-column ).
  ENDMETHOD.

  METHOD parse_flow_mapping.
    DATA ls_tk       TYPE zif_ayaml_types=>ty_s_token.
    DATA lv_key      TYPE string.
    DATA lo_val      TYPE REF TO zcl_ayaml_ast_node.

    ls_tk = current( ).
    advance( ). " skip {

    ro_node = NEW #(
      iv_node_type = zif_ayaml_types=>cs_type-mapping
      iv_line      = ls_tk-line
      iv_column    = ls_tk-column ).

    WHILE is_eof( ) = abap_false AND current( )-type <> zif_ayaml_types=>cs_token_type-flow_map_end.
      IF current( )-type = zif_ayaml_types=>cs_token_type-flow_entry.
        advance( ).
        CONTINUE.
      ENDIF.

      IF current( )-type <> zif_ayaml_types=>cs_token_type-map_key.
        RAISE EXCEPTION NEW zcx_ayaml_error(
          iv_msg = |Expected map key in flow mapping at line { current( )-line }| ).
      ENDIF.

      lv_key = current( )-value.
      advance( ). " skip key

      IF current( )-type <> zif_ayaml_types=>cs_token_type-map_val.
        RAISE EXCEPTION NEW zcx_ayaml_error(
          iv_msg = |Expected ':' in flow mapping at line { current( )-line }| ).
      ENDIF.
      advance( ). " skip :

      lo_val = parse_node( 0 ).
      lo_val->set_key( lv_key ).
      ro_node->add_child( lo_val ).

      IF current( )-type = zif_ayaml_types=>cs_token_type-flow_entry.
        advance( ).
      ENDIF.
    ENDWHILE.

    IF current( )-type = zif_ayaml_types=>cs_token_type-flow_map_end.
      advance( ). " skip }
    ELSE.
      RAISE EXCEPTION NEW zcx_ayaml_error( iv_msg = `Unterminated flow mapping, missing '}'` ).
    ENDIF.
  ENDMETHOD.

  METHOD parse_flow_sequence.
    DATA ls_tk  TYPE zif_ayaml_types=>ty_s_token.
    DATA lo_val TYPE REF TO zcl_ayaml_ast_node.

    ls_tk = current( ).
    advance( ). " skip [

    ro_node = NEW #(
      iv_node_type = zif_ayaml_types=>cs_type-sequence
      iv_line      = ls_tk-line
      iv_column    = ls_tk-column ).

    WHILE is_eof( ) = abap_false AND current( )-type <> zif_ayaml_types=>cs_token_type-flow_seq_end.
      IF current( )-type = zif_ayaml_types=>cs_token_type-flow_entry.
        advance( ).
        CONTINUE.
      ENDIF.

      lo_val = parse_node( 0 ).
      ro_node->add_child( lo_val ).

      IF current( )-type = zif_ayaml_types=>cs_token_type-flow_entry.
        advance( ).
      ENDIF.
    ENDWHILE.

    IF current( )-type = zif_ayaml_types=>cs_token_type-flow_seq_end.
      advance( ). " skip ]
    ELSE.
      RAISE EXCEPTION NEW zcx_ayaml_error( iv_msg = `Unterminated flow sequence, missing ']'` ).
    ENDIF.
  ENDMETHOD.

  METHOD parse_block_sequence.
    DATA ls_tk       TYPE zif_ayaml_types=>ty_s_token.
    DATA lv_anchor   TYPE string.
    DATA lo_elem     TYPE REF TO zcl_ayaml_ast_node.
    DATA lv_entry_in TYPE i.
    DATA ls_next TYPE zif_ayaml_types=>ty_s_token.

    ls_tk = current( ).
    ro_node = NEW #(
      iv_node_type = zif_ayaml_types=>cs_type-sequence
      iv_line      = ls_tk-line
      iv_column    = ls_tk-column ).

    WHILE is_eof( ) = abap_false.
      ls_tk = current( ).
      IF ls_tk-type = zif_ayaml_types=>cs_token_type-eof
          OR ls_tk-type = zif_ayaml_types=>cs_token_type-doc_end
          OR ls_tk-type = zif_ayaml_types=>cs_token_type-doc_start.
        EXIT.
      ENDIF.

      IF ls_tk-indent_num < iv_indent.
        EXIT.
      ENDIF.

      IF ls_tk-type <> zif_ayaml_types=>cs_token_type-seq_entry.
        EXIT.
      ENDIF.

      lv_entry_in = ls_tk-indent_num.
      advance( ). " skip -
      CLEAR lv_anchor.

      IF current( )-type = zif_ayaml_types=>cs_token_type-anchor.
        lv_anchor = current( )-value.
        advance( ).
      ENDIF.


      ls_next = current( ).

      IF ls_next-line = ls_tk-line AND ls_next-type <> zif_ayaml_types=>cs_token_type-eof.
        IF ls_next-type = zif_ayaml_types=>cs_token_type-map_key.
          lo_elem = parse_block_mapping( ls_next-indent_num ).
        ELSE.
          lo_elem = parse_node( ls_tk-indent_num ).
        ENDIF.
      ELSEIF ls_next-indent_num > lv_entry_in.
        lo_elem = parse_node( ls_next-indent_num ).
      ELSE.
        lo_elem = NEW #( iv_node_type = zif_ayaml_types=>cs_type-null iv_value = `` ).
      ENDIF.

      IF lv_anchor IS NOT INITIAL.
        lo_elem->set_anchor( lv_anchor ).
        register_anchor( iv_name = lv_anchor io_node = lo_elem ).
      ENDIF.

      ro_node->add_child( lo_elem ).
    ENDWHILE.
  ENDMETHOD.

  METHOD parse_block_mapping.
    DATA ls_tk       TYPE zif_ayaml_types=>ty_s_token.
    DATA lv_key      TYPE string.
    DATA lv_anchor   TYPE string.
    DATA lo_val      TYPE REF TO zcl_ayaml_ast_node.
    DATA ls_next     TYPE zif_ayaml_types=>ty_s_token.
    DATA lt_merge_children TYPE zcl_ayaml_ast_node=>ty_t_nodes.
    DATA lo_m_child TYPE REF TO zcl_ayaml_ast_node.
    DATA lo_existing TYPE REF TO zcl_ayaml_ast_node.

    ls_tk = current( ).
    ro_node = NEW #(
      iv_node_type = zif_ayaml_types=>cs_type-mapping
      iv_line      = ls_tk-line
      iv_column    = ls_tk-column ).

    WHILE is_eof( ) = abap_false.
      ls_tk = current( ).
      IF ls_tk-type = zif_ayaml_types=>cs_token_type-eof
          OR ls_tk-type = zif_ayaml_types=>cs_token_type-doc_end
          OR ls_tk-type = zif_ayaml_types=>cs_token_type-doc_start.
        EXIT.
      ENDIF.

      IF ls_tk-indent_num < iv_indent.
        EXIT.
      ENDIF.

      IF ls_tk-type <> zif_ayaml_types=>cs_token_type-map_key.
        EXIT.
      ENDIF.

      lv_key = ls_tk-value.
      advance( ). " skip key

      IF current( )-type <> zif_ayaml_types=>cs_token_type-map_val.
        RAISE EXCEPTION NEW zcx_ayaml_error(
          iv_msg = |Expected ':' after '{ lv_key }' at line { ls_tk-line }| ).
      ENDIF.
      advance( ). " skip :

      CLEAR lv_anchor.
      IF current( )-type = zif_ayaml_types=>cs_token_type-anchor.
        lv_anchor = current( )-value.
        advance( ).
      ENDIF.

      ls_next = current( ).

      IF ls_next-line = ls_tk-line AND ls_next-type <> zif_ayaml_types=>cs_token_type-eof.
        lo_val = parse_node( ls_tk-indent_num ).
      ELSEIF ls_next-indent_num > ls_tk-indent_num.
        lo_val = parse_node( ls_next-indent_num ).
      ELSE.
        lo_val = NEW #( iv_node_type = zif_ayaml_types=>cs_type-null iv_value = `` ).
      ENDIF.

      IF lv_key = `<<`.
        " Merge key handling



        lt_merge_children = lo_val->get_children( ).
        LOOP AT lt_merge_children INTO lo_m_child.
          lo_existing = ro_node->get_child_by_key( lo_m_child->get_key( ) ).
          IF lo_existing IS INITIAL.
            ro_node->add_child( lo_m_child->clone( ) ).
          ENDIF.
        ENDLOOP.
      ELSE.
        lo_val->set_key( lv_key ).
        IF lv_anchor IS NOT INITIAL.
          lo_val->set_anchor( lv_anchor ).
          register_anchor( iv_name = lv_anchor io_node = lo_val ).
        ENDIF.
        ro_node->add_child( lo_val ).
      ENDIF.
    ENDWHILE.
  ENDMETHOD.

  METHOD parse_node.
    DATA ls_tk TYPE zif_ayaml_types=>ty_s_token.
    ls_tk = current( ).

    CASE ls_tk-type.
      WHEN zif_ayaml_types=>cs_token_type-flow_map_start.
        ro_node = parse_flow_mapping( ).
      WHEN zif_ayaml_types=>cs_token_type-flow_seq_start.
        ro_node = parse_flow_sequence( ).
      WHEN zif_ayaml_types=>cs_token_type-seq_entry.
        ro_node = parse_block_sequence( iv_indent ).
      WHEN zif_ayaml_types=>cs_token_type-map_key.
        ro_node = parse_block_mapping( iv_indent ).
      WHEN zif_ayaml_types=>cs_token_type-alias.
        advance( ).
        ro_node = resolve_alias( ls_tk-value ).
      WHEN zif_ayaml_types=>cs_token_type-scalar.
        ro_node = parse_scalar( ).
      WHEN OTHERS.
        RAISE EXCEPTION NEW zcx_ayaml_error(
          iv_msg = |Unexpected token '{ ls_tk-type }' at line { ls_tk-line }| ).
    ENDCASE.
  ENDMETHOD.

  METHOD parse.
    IF is_eof( ) = abap_true.
      ro_root = NEW #( iv_node_type = zif_ayaml_types=>cs_type-null iv_value = `` ).
      RETURN.
    ENDIF.

    IF current( )-type = zif_ayaml_types=>cs_token_type-doc_start.
      advance( ).
    ENDIF.

    IF is_eof( ) = abap_true.
      ro_root = NEW #( iv_node_type = zif_ayaml_types=>cs_type-null iv_value = `` ).
      RETURN.
    ENDIF.

    ro_root = parse_node( current( )-indent_num ).
  ENDMETHOD.

ENDCLASS.
