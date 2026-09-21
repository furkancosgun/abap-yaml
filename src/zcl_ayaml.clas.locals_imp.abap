CLASS lcl_ast_node IMPLEMENTATION.
  METHOD constructor.
    mv_type   = iv_node_type.
    mv_value  = iv_value.
    mv_key    = iv_key.
    mv_line   = iv_line.
    mv_column = iv_column.
  ENDMETHOD.

  METHOD add_child.
    FIELD-SYMBOLS <fs_child> TYPE REF TO lcl_ast_node.

    IF io_child->get_key( ) IS NOT INITIAL.
      LOOP AT mt_children ASSIGNING <fs_child>.
        IF <fs_child>->get_key( ) = io_child->get_key( ).
          <fs_child> = io_child.
          RETURN.
        ENDIF.
      ENDLOOP.
    ENDIF.
    INSERT io_child INTO TABLE mt_children.
  ENDMETHOD.

  METHOD get_children.
    rt_children = mt_children.
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

  METHOD get_type.
    rv_type = mv_type.
  ENDMETHOD.

  METHOD get_anchor.
    rv_anchor = mv_anchor.
  ENDMETHOD.

  METHOD set_anchor.
    mv_anchor = iv_anchor.
  ENDMETHOD.

  METHOD get_line.
    rv_line = mv_line.
  ENDMETHOD.

  METHOD get_column.
    rv_col = mv_column.
  ENDMETHOD.

  METHOD get_child_by_key.
    FIELD-SYMBOLS <fs_child> TYPE REF TO lcl_ast_node.

    LOOP AT mt_children ASSIGNING <fs_child>.
      IF <fs_child>->get_key( ) = iv_key.
        ro_node = <fs_child>.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD clone.
    FIELD-SYMBOLS <fs_child> TYPE REF TO lcl_ast_node.

    CREATE OBJECT ro_node
      EXPORTING iv_node_type = mv_type
                iv_value     = mv_value
                iv_key       = mv_key
                iv_line      = mv_line
                iv_column    = mv_column.
    ro_node->set_anchor( mv_anchor ).

    LOOP AT mt_children ASSIGNING <fs_child>.
      ro_node->add_child( <fs_child>->clone( ) ).
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_scanner IMPLEMENTATION.
  METHOD constructor.
    DATA lv_cr TYPE c LENGTH 1.

    mv_source = iv_yaml.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN mv_source
            WITH cl_abap_char_utilities=>newline.

    lv_cr = cl_abap_char_utilities=>cr_lf(1).
    REPLACE ALL OCCURRENCES OF lv_cr IN mv_source
            WITH cl_abap_char_utilities=>newline.
    mv_len           = strlen( mv_source ).
    mv_pos           = 0.
    mv_line          = 1.
    mv_col           = 1.
    mv_indent        = 0.
    mv_is_line_start = abap_true.
    mv_flow_depth    = 0.
  ENDMETHOD.

  METHOD is_eof.
    rv_yes = boolc( mv_pos >= mv_len ).
  ENDMETHOD.

  METHOD peek.
    DATA lv_target TYPE i.

    lv_target = mv_pos + iv_offset.
    IF lv_target < mv_len AND lv_target >= 0.
      rv_char = mv_source+lv_target(1).
    ELSE.
      CLEAR rv_char.
    ENDIF.
  ENDMETHOD.

  METHOD advance.
    DATA lv_char TYPE string.

    DO iv_count TIMES.
      IF mv_pos >= mv_len.
        EXIT.
      ENDIF.

      lv_char = mv_source+mv_pos(1).
      mv_pos = mv_pos + 1.
      IF lv_char = cl_abap_char_utilities=>newline.
        mv_line = mv_line + 1.
        mv_col = 1.
        mv_is_line_start = abap_true.
        mv_indent = 0.
      ELSE.
        mv_col = mv_col + 1.
      ENDIF.
    ENDDO.
  ENDMETHOD.

  METHOD skip_spaces.
    WHILE is_eof( ) = abap_false AND peek( ) = ` `.
      advance( ).
    ENDWHILE.
  ENDMETHOD.

  METHOD emit_token.
    DATA ls_token TYPE zif_ayaml_types=>ty_s_token.

    ls_token-type  = iv_type.
    ls_token-value = iv_value.
    IF iv_line IS NOT INITIAL.
      ls_token-line = iv_line.
    ELSE.
      ls_token-line = mv_line.
    ENDIF.
    IF iv_column IS NOT INITIAL.
      ls_token-column = iv_column.
    ELSE.
      ls_token-column = mv_col.
    ENDIF.
    ls_token-indent_num = mv_indent.
    INSERT ls_token INTO TABLE mt_tokens.
  ENDMETHOD.

  METHOD scan_line_start.
    DATA lv_char TYPE string.

    WHILE is_eof( ) = abap_false AND mv_is_line_start = abap_true.
      lv_char = peek( ).
      CASE lv_char.
        WHEN ` `.
          mv_indent = mv_indent + 1.
          advance( ).
        WHEN cl_abap_char_utilities=>horizontal_tab.
          RAISE EXCEPTION TYPE zcx_ayaml_error
            EXPORTING iv_msg = |Tab character not allowed at line { mv_line }|.
        WHEN cl_abap_char_utilities=>newline.
          advance( ).
          mv_indent = 0.
          mv_is_line_start = abap_true.
        WHEN `#`.
          WHILE is_eof( ) = abap_false AND peek( ) <> cl_abap_char_utilities=>newline.
            advance( ).
          ENDWHILE.
          IF is_eof( ) = abap_false.
            advance( ).
          ENDIF.
          mv_indent = 0.
          mv_is_line_start = abap_true.
        WHEN OTHERS.
          mv_is_line_start = abap_false.
          EXIT.
      ENDCASE.
    ENDWHILE.
  ENDMETHOD.

  METHOD scan_single_quote.
    DATA lv_char TYPE string.

    advance( ).
    CLEAR rv_val.
    WHILE is_eof( ) = abap_false.
      lv_char = peek( ).
      CASE lv_char.
        WHEN `'`.
          IF peek( 1 ) = `'`.
            rv_val = |{ rv_val }'|.
            advance( 2 ).
          ELSE.
            advance( 1 ).
            RETURN.
          ENDIF.
        WHEN cl_abap_char_utilities=>newline.
          rv_val = |{ rv_val }\n|.
          advance( ).
        WHEN OTHERS.
          rv_val = |{ rv_val }{ lv_char }|.
          advance( ).
      ENDCASE.
    ENDWHILE.

    RAISE EXCEPTION TYPE zcx_ayaml_error
      EXPORTING iv_msg = |Unterminated single-quoted string at line { mv_line }|.
  ENDMETHOD.

  METHOD scan_double_quote.
    DATA lv_char TYPE string.
    DATA lv_next TYPE string.

    advance( ).
    CLEAR rv_val.
    WHILE is_eof( ) = abap_false.
      lv_char = peek( ).
      CASE lv_char.
        WHEN `"`.
          advance( 1 ).
          RETURN.
        WHEN `\`.
          advance( 1 ).
          lv_next = peek( ).
          advance( 1 ).
          CASE lv_next.
            WHEN `"`.
              rv_val = |{ rv_val }"|.
            WHEN `\`.
              rv_val = |{ rv_val }\\|.
            WHEN `n`.
              rv_val = |{ rv_val }{ cl_abap_char_utilities=>newline }|.
            WHEN `t`.
              rv_val = |{ rv_val }{ cl_abap_char_utilities=>horizontal_tab }|.
            WHEN `r`.
              rv_val = |{ rv_val }{ cl_abap_char_utilities=>cr_lf(1) }|.
            WHEN `0`.
              rv_val = |{ rv_val } |.
            WHEN OTHERS.
              rv_val = |{ rv_val }{ lv_next }|.
          ENDCASE.
        WHEN cl_abap_char_utilities=>newline.
          rv_val = |{ rv_val }{ cl_abap_char_utilities=>newline }|.
          advance( ).
        WHEN OTHERS.
          rv_val = |{ rv_val }{ lv_char }|.
          advance( ).
      ENDCASE.
    ENDWHILE.

    RAISE EXCEPTION TYPE zcx_ayaml_error
      EXPORTING iv_msg = |Unterminated double-quoted string at line { mv_line }|.
  ENDMETHOD.

  METHOD collect_block_lines.
    DATA lv_line_buf      TYPE string.
    DATA lv_scalar_indent TYPE i.
    DATA lv_line_indent   TYPE i.
    DATA lv_extra         TYPE i.

    lv_scalar_indent = -1.
    CLEAR rt_lines.

    WHILE is_eof( ) = abap_false.
      lv_line_indent = 0.
      WHILE is_eof( ) = abap_false AND peek( ) = ` `.
        lv_line_indent = lv_line_indent + 1.
        advance( ).
      ENDWHILE.

      IF peek( ) = cl_abap_char_utilities=>newline.
        advance( ).
        INSERT `` INTO TABLE rt_lines.
        CONTINUE.
      ENDIF.

      IF is_eof( ) = abap_true.
        EXIT.
      ENDIF.

      IF lv_scalar_indent < 0.
        IF lv_line_indent <= iv_base_indent.
          EXIT.
        ENDIF.
        lv_scalar_indent = lv_line_indent.
      ELSEIF lv_line_indent < lv_scalar_indent.
        mv_pos = mv_pos - lv_line_indent.
        mv_col = mv_col - lv_line_indent.
        mv_indent = lv_line_indent.
        mv_is_line_start = abap_false.
        EXIT.
      ENDIF.

      CLEAR lv_line_buf.
      lv_extra = lv_line_indent - lv_scalar_indent.
      DO lv_extra TIMES.
        lv_line_buf = |{ lv_line_buf } |.
      ENDDO.

      WHILE is_eof( ) = abap_false AND peek( ) <> cl_abap_char_utilities=>newline.
        lv_line_buf = |{ lv_line_buf }{ peek( ) }|.
        advance( ).
      ENDWHILE.
      IF is_eof( ) = abap_false.
        advance( ).
      ENDIF.
      INSERT lv_line_buf INTO TABLE rt_lines.
    ENDWHILE.
  ENDMETHOD.

  METHOD format_block_lines.
    DATA lv_count    TYPE i.
    DATA lv_idx      TYPE i.
    DATA lv_prev_idx TYPE i.
    FIELD-SYMBOLS <fs_line>      TYPE string.
    FIELD-SYMBOLS <fs_prev_line> TYPE string.

    lv_count = lines( it_lines ).
    IF iv_indicator = `|`.
      LOOP AT it_lines ASSIGNING <fs_line>.
        lv_idx = lv_idx + 1.
        IF lv_idx = 1.
          rv_val = <fs_line>.
        ELSE.
          rv_val = |{ rv_val }{ cl_abap_char_utilities=>newline }{ <fs_line> }|.
        ENDIF.
      ENDLOOP.
    ELSE.
      LOOP AT it_lines ASSIGNING <fs_line>.
        lv_idx = lv_idx + 1.
        IF lv_idx = 1.
          rv_val = <fs_line>.
        ELSEIF <fs_line> IS INITIAL.
          rv_val = |{ rv_val }{ cl_abap_char_utilities=>newline }|.
        ELSE.
          lv_prev_idx = lv_idx - 1.
          READ TABLE it_lines INDEX lv_prev_idx ASSIGNING <fs_prev_line>.
          IF sy-subrc = 0 AND <fs_prev_line> IS INITIAL.
            rv_val = |{ rv_val }{ <fs_line> }|.
          ELSE.
            rv_val = |{ rv_val } { <fs_line> }|.
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDIF.

    IF iv_chomping <> `-` AND lv_count > 0.
      rv_val = |{ rv_val }{ cl_abap_char_utilities=>newline }|.
    ENDIF.
  ENDMETHOD.

  METHOD scan_block_scalar.
    DATA lt_lines    TYPE string_table.
    DATA lv_char     TYPE string.
    DATA lv_chomping TYPE string.

    advance( ).
    lv_char = peek( ).
    IF lv_char = `-` OR lv_char = `+`.
      lv_chomping = lv_char.
      advance( ).
    ENDIF.

    WHILE is_eof( ) = abap_false AND peek( ) <> cl_abap_char_utilities=>newline.
      advance( ).
    ENDWHILE.
    IF is_eof( ) = abap_false.
      advance( ).
    ENDIF.

    lt_lines = collect_block_lines( mv_indent ).
    rv_val = format_block_lines( it_lines     = lt_lines
                                 iv_indicator = iv_indicator
                                 iv_chomping  = lv_chomping ).
  ENDMETHOD.

  METHOD scan_plain_scalar.
    DATA lv_char     TYPE string.
    DATA lv_p_pos    TYPE i.
    DATA lv_last_pos TYPE i.

    CLEAR rv_val.
    WHILE is_eof( ) = abap_false.
      lv_char = peek( ).
      IF lv_char = cl_abap_char_utilities=>newline.
        EXIT.
      ENDIF.
      IF lv_char = `#` AND rv_val IS NOT INITIAL.
        lv_p_pos = mv_pos - 1.
        IF lv_p_pos >= 0 AND mv_source+lv_p_pos(1) = ` `.
          EXIT.
        ENDIF.
      ENDIF.
      IF lv_char = `:` AND ( peek( 1 ) = ` ` OR peek( 1 ) = cl_abap_char_utilities=>newline OR peek( 1 ) IS INITIAL ).
        EXIT.
      ENDIF.
      IF mv_flow_depth > 0 AND ( lv_char = `,` OR lv_char = `]` OR lv_char = `}` ).
        EXIT.
      ENDIF.
      rv_val = |{ rv_val }{ lv_char }|.
      advance( ).
    ENDWHILE.

    WHILE strlen( rv_val ) > 0.
      lv_last_pos = strlen( rv_val ) - 1.
      IF rv_val+lv_last_pos(1) = ` `.
        rv_val = rv_val(lv_last_pos).
      ELSE.
        EXIT.
      ENDIF.
    ENDWHILE.
  ENDMETHOD.

  METHOD scan_document_boundary.
    IF NOT ( iv_start_col = 1 AND mv_indent = 0 ).
      RETURN.
    ENDIF.

    IF iv_char = `-` AND peek( 1 ) = `-` AND peek( 2 ) = `-`.
      advance( 3 ).
      emit_token( iv_type  = zif_ayaml_types=>cs_token_type-doc_start
                  iv_value = `---` ).
      rv_hit = abap_true.
    ELSEIF iv_char = `.` AND peek( 1 ) = `.` AND peek( 2 ) = `.`.
      advance( 3 ).
      emit_token( iv_type  = zif_ayaml_types=>cs_token_type-doc_end
                  iv_value = `...` ).
      rv_hit = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD scan_flow_token.
    CASE iv_char.
      WHEN `{`.
        mv_flow_depth = mv_flow_depth + 1.
        advance( 1 ).
        emit_token( iv_type   = zif_ayaml_types=>cs_token_type-flow_map_start
                    iv_value  = `{`
                    iv_line   = iv_start_line
                    iv_column = iv_start_col ).
        rv_hit = abap_true.
      WHEN `}`.
        IF mv_flow_depth > 0.
          mv_flow_depth = mv_flow_depth - 1.
        ENDIF.
        advance( 1 ).
        emit_token( iv_type   = zif_ayaml_types=>cs_token_type-flow_map_end
                    iv_value  = `}`
                    iv_line   = iv_start_line
                    iv_column = iv_start_col ).
        rv_hit = abap_true.
      WHEN `[`.
        mv_flow_depth = mv_flow_depth + 1.
        advance( 1 ).
        emit_token( iv_type   = zif_ayaml_types=>cs_token_type-flow_seq_start
                    iv_value  = `[`
                    iv_line   = iv_start_line
                    iv_column = iv_start_col ).
        rv_hit = abap_true.
      WHEN `]`.
        IF mv_flow_depth > 0.
          mv_flow_depth = mv_flow_depth - 1.
        ENDIF.
        advance( 1 ).
        emit_token( iv_type   = zif_ayaml_types=>cs_token_type-flow_seq_end
                    iv_value  = `]`
                    iv_line   = iv_start_line
                    iv_column = iv_start_col ).
        rv_hit = abap_true.
      WHEN `,`.
        advance( 1 ).
        emit_token( iv_type   = zif_ayaml_types=>cs_token_type-flow_entry
                    iv_value  = `,`
                    iv_line   = iv_start_line
                    iv_column = iv_start_col ).
        rv_hit = abap_true.
    ENDCASE.
  ENDMETHOD.

  METHOD scan_anchor_or_alias.
    DATA lv_name TYPE string.

    CASE iv_char.
      WHEN `&`.
        advance( 1 ).
        CLEAR lv_name.
        WHILE is_eof( ) = abap_false AND peek( ) <> ` ` AND peek( ) <> cl_abap_char_utilities=>newline.
          lv_name = |{ lv_name }{ peek( ) }|.
          advance( 1 ).
        ENDWHILE.
        emit_token( iv_type   = zif_ayaml_types=>cs_token_type-anchor
                    iv_value  = lv_name
                    iv_line   = iv_start_line
                    iv_column = iv_start_col ).
        rv_hit = abap_true.
      WHEN `*`.
        advance( 1 ).
        CLEAR lv_name.
        WHILE is_eof( ) = abap_false AND peek( ) <> ` ` AND peek( ) <> cl_abap_char_utilities=>newline.
          lv_name = |{ lv_name }{ peek( ) }|.
          advance( 1 ).
        ENDWHILE.
        emit_token( iv_type   = zif_ayaml_types=>cs_token_type-alias
                    iv_value  = lv_name
                    iv_line   = iv_start_line
                    iv_column = iv_start_col ).
        rv_hit = abap_true.
    ENDCASE.
  ENDMETHOD.

  METHOD scan.
    DATA lv_char       TYPE string.
    DATA lv_start_line TYPE i.
    DATA lv_start_col  TYPE i.
    DATA lv_scalar_val TYPE string.
    DATA lv_peek1      TYPE string.

    CLEAR mt_tokens.

    WHILE is_eof( ) = abap_false.
      IF mv_is_line_start = abap_true.
        scan_line_start( ).
        IF is_eof( ) = abap_true.
          EXIT.
        ENDIF.
      ENDIF.

      skip_spaces( ).
      IF is_eof( ) = abap_true.
        EXIT.
      ENDIF.

      lv_char = peek( ).
      lv_start_line = mv_line.
      lv_start_col = mv_col.

      IF scan_document_boundary( iv_start_col = lv_start_col
                                 iv_char      = lv_char ) = abap_true.
        CONTINUE.
      ENDIF.

      IF lv_char = `#`.
        WHILE is_eof( ) = abap_false AND peek( ) <> cl_abap_char_utilities=>newline.
          advance( ).
        ENDWHILE.
        CONTINUE.
      ENDIF.

      IF lv_char = cl_abap_char_utilities=>newline.
        advance( ).
        CONTINUE.
      ENDIF.

      IF lv_char = `-` AND ( peek( 1 ) = ` ` OR peek( 1 ) = cl_abap_char_utilities=>newline OR peek( 1 ) IS INITIAL ).
        advance( 1 ).
        emit_token( iv_type   = zif_ayaml_types=>cs_token_type-seq_entry
                    iv_value  = `-`
                    iv_line   = lv_start_line
                    iv_column = lv_start_col ).
        CONTINUE.
      ENDIF.

      IF scan_flow_token( iv_char       = lv_char
                          iv_start_line = lv_start_line
                          iv_start_col  = lv_start_col ) = abap_true.
        CONTINUE.
      ENDIF.

      IF scan_anchor_or_alias( iv_char       = lv_char
                               iv_start_line = lv_start_line
                               iv_start_col  = lv_start_col ) = abap_true.
        CONTINUE.
      ENDIF.

      IF ( lv_char = `|` OR lv_char = `>` ) AND mv_flow_depth = 0.
        lv_scalar_val = scan_block_scalar( lv_char ).
        emit_token( iv_type   = zif_ayaml_types=>cs_token_type-scalar
                    iv_value  = lv_scalar_val
                    iv_line   = lv_start_line
                    iv_column = lv_start_col ).
        CONTINUE.
      ENDIF.

      CASE lv_char.
        WHEN `'`.
          lv_scalar_val = scan_single_quote( ).
          skip_spaces( ).
          lv_peek1 = peek( 1 ).
          IF peek( ) = `:` AND ( lv_peek1 = ` ` OR lv_peek1 = cl_abap_char_utilities=>newline OR lv_peek1 IS INITIAL ).
            advance( 1 ).
            emit_token( iv_type   = zif_ayaml_types=>cs_token_type-map_key
                        iv_value  = lv_scalar_val
                        iv_line   = lv_start_line
                        iv_column = lv_start_col ).
            emit_token( iv_type   = zif_ayaml_types=>cs_token_type-map_val
                        iv_value  = `:`
                        iv_line   = mv_line
                        iv_column = mv_col ).
          ELSE.
            emit_token( iv_type   = zif_ayaml_types=>cs_token_type-scalar
                        iv_value  = lv_scalar_val
                        iv_line   = lv_start_line
                        iv_column = lv_start_col ).
          ENDIF.
          CONTINUE.
        WHEN `"`.
          lv_scalar_val = scan_double_quote( ).
          skip_spaces( ).
          lv_peek1 = peek( 1 ).
          IF peek( ) = `:` AND ( lv_peek1 = ` ` OR lv_peek1 = cl_abap_char_utilities=>newline OR lv_peek1 IS INITIAL ).
            advance( 1 ).
            emit_token( iv_type   = zif_ayaml_types=>cs_token_type-map_key
                        iv_value  = lv_scalar_val
                        iv_line   = lv_start_line
                        iv_column = lv_start_col ).
            emit_token( iv_type   = zif_ayaml_types=>cs_token_type-map_val
                        iv_value  = `:`
                        iv_line   = mv_line
                        iv_column = mv_col ).
          ELSE.
            emit_token( iv_type   = zif_ayaml_types=>cs_token_type-scalar
                        iv_value  = lv_scalar_val
                        iv_line   = lv_start_line
                        iv_column = lv_start_col ).
          ENDIF.
          CONTINUE.
      ENDCASE.

      IF lv_char = `:` AND ( peek( 1 ) = ` ` OR peek( 1 ) = cl_abap_char_utilities=>newline OR peek( 1 ) IS INITIAL ).
        advance( 1 ).
        emit_token( iv_type   = zif_ayaml_types=>cs_token_type-map_val
                    iv_value  = `:`
                    iv_line   = lv_start_line
                    iv_column = lv_start_col ).
        CONTINUE.
      ENDIF.

      lv_scalar_val = scan_plain_scalar( ).
      skip_spaces( ).
      IF peek( ) = `:` AND ( peek( 1 ) = ` ` OR peek( 1 ) = cl_abap_char_utilities=>newline OR peek( 1 ) IS INITIAL ).
        advance( 1 ).
        emit_token( iv_type   = zif_ayaml_types=>cs_token_type-map_key
                    iv_value  = lv_scalar_val
                    iv_line   = lv_start_line
                    iv_column = lv_start_col ).
        emit_token( iv_type   = zif_ayaml_types=>cs_token_type-map_val
                    iv_value  = `:`
                    iv_line   = mv_line
                    iv_column = mv_col ).
      ELSE.
        emit_token( iv_type   = zif_ayaml_types=>cs_token_type-scalar
                    iv_value  = lv_scalar_val
                    iv_line   = lv_start_line
                    iv_column = lv_start_col ).
      ENDIF.
    ENDWHILE.

    emit_token( iv_type  = zif_ayaml_types=>cs_token_type-eof
                iv_value = `` ).
    rt_tokens = mt_tokens.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_ast_parser IMPLEMENTATION.
  METHOD constructor.
    mt_tokens = it_tokens.
    mv_pos    = 1.
    mv_count  = lines( mt_tokens ).
  ENDMETHOD.

  METHOD is_eof.
    FIELD-SYMBOLS <fs_tk> TYPE zif_ayaml_types=>ty_s_token.

    IF mv_pos > mv_count.
      rv_yes = abap_true.
    ELSE.
      READ TABLE mt_tokens INDEX mv_pos ASSIGNING <fs_tk>.
      IF sy-subrc = 0 AND <fs_tk>-type = zif_ayaml_types=>cs_token_type-eof.
        rv_yes = abap_true.
      ELSE.
        rv_yes = abap_false.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD current.
    FIELD-SYMBOLS <fs_tk> TYPE zif_ayaml_types=>ty_s_token.

    IF mv_pos <= mv_count.
      READ TABLE mt_tokens INDEX mv_pos ASSIGNING <fs_tk>.
      IF sy-subrc = 0.
        rs_token = <fs_tk>.
      ELSE.
        CLEAR rs_token.
      ENDIF.
    ELSE.
      rs_token-type = zif_ayaml_types=>cs_token_type-eof.
    ENDIF.
  ENDMETHOD.

  METHOD advance.
    mv_pos = mv_pos + 1.
  ENDMETHOD.

  METHOD register_anchor.
    DATA ls_anchor TYPE ty_s_anchor.

    ls_anchor-name = iv_name.
    ls_anchor-node = io_node.
    INSERT ls_anchor INTO TABLE mt_anchors.
  ENDMETHOD.

  METHOD resolve_alias.
    FIELD-SYMBOLS <fs_anchor> TYPE ty_s_anchor.

    READ TABLE mt_anchors WITH TABLE KEY name = iv_name ASSIGNING <fs_anchor>.
    IF sy-subrc = 0.
      ro_node = <fs_anchor>-node->clone( ).
    ELSE.
      RAISE EXCEPTION TYPE zcx_ayaml_error
        EXPORTING iv_msg = |Undefined alias: *{ iv_name }|.
    ENDIF.
  ENDMETHOD.

  METHOD parse_scalar.
    DATA lv_type TYPE zif_ayaml_types=>ty_node_type.
    DATA lv_val  TYPE string.
    DATA ls_tk   TYPE zif_ayaml_types=>ty_s_token.

    ls_tk = current( ).
    advance( ).

    zcl_ayaml_utils=>detect_yaml_scalar( EXPORTING iv_raw   = ls_tk-value
                                         IMPORTING ev_type  = lv_type
                                                   ev_value = lv_val ).

    CREATE OBJECT ro_node
      EXPORTING iv_node_type = lv_type
                iv_value     = lv_val
                iv_line      = ls_tk-line
                iv_column    = ls_tk-column.
  ENDMETHOD.

  METHOD parse_flow_mapping.
    DATA ls_tk  TYPE zif_ayaml_types=>ty_s_token.
    DATA lv_key TYPE string.
    DATA lo_val TYPE REF TO lcl_ast_node.

    ls_tk = current( ).
    advance( ).

    CREATE OBJECT ro_node
      EXPORTING iv_node_type = zif_ayaml_types=>cs_type-mapping
                iv_line      = ls_tk-line
                iv_column    = ls_tk-column.

    WHILE is_eof( ) = abap_false AND current( )-type <> zif_ayaml_types=>cs_token_type-flow_map_end.
      IF current( )-type = zif_ayaml_types=>cs_token_type-flow_entry.
        advance( ).
        CONTINUE.
      ENDIF.

      IF current( )-type <> zif_ayaml_types=>cs_token_type-map_key.
        RAISE EXCEPTION TYPE zcx_ayaml_error
          EXPORTING iv_msg = |Expected map key in flow mapping at line { current( )-line }|.
      ENDIF.

      lv_key = current( )-value.
      advance( ).

      IF current( )-type <> zif_ayaml_types=>cs_token_type-map_val.
        RAISE EXCEPTION TYPE zcx_ayaml_error
          EXPORTING iv_msg = |Expected ':' in flow mapping at line { current( )-line }|.
      ENDIF.
      advance( ).

      lo_val = parse_node( 0 ).
      lo_val->set_key( lv_key ).
      ro_node->add_child( lo_val ).

      IF current( )-type = zif_ayaml_types=>cs_token_type-flow_entry.
        advance( ).
      ENDIF.
    ENDWHILE.

    IF current( )-type = zif_ayaml_types=>cs_token_type-flow_map_end.
      advance( ).
    ELSE.
      RAISE EXCEPTION TYPE zcx_ayaml_error
        EXPORTING iv_msg = `Unterminated flow mapping, missing '}'`.
    ENDIF.
  ENDMETHOD.

  METHOD parse_flow_sequence.
    DATA ls_tk  TYPE zif_ayaml_types=>ty_s_token.
    DATA lo_val TYPE REF TO lcl_ast_node.

    ls_tk = current( ).
    advance( ).

    CREATE OBJECT ro_node
      EXPORTING iv_node_type = zif_ayaml_types=>cs_type-sequence
                iv_line      = ls_tk-line
                iv_column    = ls_tk-column.

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
      advance( ).
    ELSE.
      RAISE EXCEPTION TYPE zcx_ayaml_error
        EXPORTING iv_msg = `Unterminated flow sequence, missing ']'`.
    ENDIF.
  ENDMETHOD.

  METHOD parse_block_sequence.
    DATA lv_anchor   TYPE string.
    DATA ls_tk       TYPE zif_ayaml_types=>ty_s_token.
    DATA lv_entry_in TYPE i.
    DATA ls_next     TYPE zif_ayaml_types=>ty_s_token.
    DATA lo_elem     TYPE REF TO lcl_ast_node.

    ls_tk = current( ).
    CREATE OBJECT ro_node
      EXPORTING iv_node_type = zif_ayaml_types=>cs_type-sequence
                iv_line      = ls_tk-line
                iv_column    = ls_tk-column.

    WHILE is_eof( ) = abap_false.
      ls_tk = current( ).
      IF    ls_tk-type = zif_ayaml_types=>cs_token_type-eof
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
      advance( ).
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
        CREATE OBJECT lo_elem
          EXPORTING iv_node_type = zif_ayaml_types=>cs_type-null
                    iv_value     = ``.
      ENDIF.

      IF lv_anchor IS NOT INITIAL.
        lo_elem->set_anchor( lv_anchor ).
        register_anchor( iv_name = lv_anchor
                         io_node = lo_elem ).
      ENDIF.

      ro_node->add_child( lo_elem ).
    ENDWHILE.
  ENDMETHOD.

  METHOD parse_block_mapping.
    DATA lv_anchor         TYPE string.
    DATA ls_tk             TYPE zif_ayaml_types=>ty_s_token.
    DATA lv_key            TYPE string.
    DATA ls_next           TYPE zif_ayaml_types=>ty_s_token.
    DATA lo_val            TYPE REF TO lcl_ast_node.
    DATA lt_merge_children TYPE lcl_ast_node=>ty_t_nodes.
    DATA lo_existing       TYPE REF TO lcl_ast_node.
    FIELD-SYMBOLS <fs_m_child> TYPE REF TO lcl_ast_node.

    ls_tk = current( ).
    CREATE OBJECT ro_node
      EXPORTING iv_node_type = zif_ayaml_types=>cs_type-mapping
                iv_line      = ls_tk-line
                iv_column    = ls_tk-column.

    WHILE is_eof( ) = abap_false.
      ls_tk = current( ).
      IF    ls_tk-type = zif_ayaml_types=>cs_token_type-eof
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
      advance( ).

      IF current( )-type <> zif_ayaml_types=>cs_token_type-map_val.
        RAISE EXCEPTION TYPE zcx_ayaml_error
          EXPORTING iv_msg = |Expected ':' after '{ lv_key }' at line { ls_tk-line }|.
      ENDIF.
      advance( ).

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
        CREATE OBJECT lo_val
          EXPORTING iv_node_type = zif_ayaml_types=>cs_type-null
                    iv_value     = ``.
      ENDIF.

      IF lv_key = `<<`.
        lt_merge_children = lo_val->get_children( ).
        LOOP AT lt_merge_children ASSIGNING <fs_m_child>.
          lo_existing = ro_node->get_child_by_key( <fs_m_child>->get_key( ) ).
          IF lo_existing IS INITIAL.
            ro_node->add_child( <fs_m_child>->clone( ) ).
          ENDIF.
        ENDLOOP.
      ELSE.
        lo_val->set_key( lv_key ).
        IF lv_anchor IS NOT INITIAL.
          lo_val->set_anchor( lv_anchor ).
          register_anchor( iv_name = lv_anchor
                           io_node = lo_val ).
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
      WHEN zif_ayaml_types=>cs_token_type-doc_end.
        advance( ).
        CREATE OBJECT ro_node
          EXPORTING iv_node_type = zif_ayaml_types=>cs_type-null
                    iv_value     = ``.
      WHEN OTHERS.
        RAISE EXCEPTION TYPE zcx_ayaml_error
          EXPORTING iv_msg = |Unexpected token '{ ls_tk-type }' at line { ls_tk-line }|.
    ENDCASE.
  ENDMETHOD.

  METHOD parse.
    IF is_eof( ) = abap_true.
      CREATE OBJECT ro_root
        EXPORTING iv_node_type = zif_ayaml_types=>cs_type-null
                  iv_value     = ``.
      RETURN.
    ENDIF.

    IF current( )-type = zif_ayaml_types=>cs_token_type-doc_start.
      advance( ).
    ENDIF.

    IF is_eof( ) = abap_true OR current( )-type = zif_ayaml_types=>cs_token_type-doc_end.
      CREATE OBJECT ro_root
        EXPORTING iv_node_type = zif_ayaml_types=>cs_type-null
                  iv_value     = ``.
      RETURN.
    ENDIF.

    ro_root = parse_node( current( )-indent_num ).
  ENDMETHOD.
ENDCLASS.


CLASS lcl_ast_to_nodes IMPLEMENTATION.
  METHOD convert.
    DATA lv_order TYPE i VALUE 0.

    CLEAR rt_nodes.
    IF io_root IS INITIAL.
      RETURN.
    ENDIF.

    IF     io_root->get_type( )               = zif_ayaml_types=>cs_type-null
       AND io_root->get_value( )             IS INITIAL
       AND lines( io_root->get_children( ) )  = 0.
      RETURN.
    ENDIF.

    traverse( EXPORTING io_node  = io_root
                        iv_path  = `/`
                        iv_name  = ``
                        iv_index = 0
              CHANGING  ct_nodes = rt_nodes
                        cv_order = lv_order ).
  ENDMETHOD.

  METHOD traverse.
    DATA ls_node       TYPE zif_ayaml_types=>ty_s_node.
    DATA lv_node_type  TYPE zif_ayaml_types=>ty_node_type.
    DATA lv_child_path TYPE string.
    DATA lt_children   TYPE lcl_ast_node=>ty_t_nodes.
    DATA lv_seq_idx    TYPE i.
    FIELD-SYMBOLS <fs_child> TYPE REF TO lcl_ast_node.

    IF io_node IS INITIAL.
      RETURN.
    ENDIF.

    lv_node_type = io_node->get_type( ).

    IF iv_name IS NOT INITIAL.
      cv_order = cv_order + 1.
      ls_node-path  = iv_path.
      ls_node-name  = iv_name.
      ls_node-type  = lv_node_type.
      ls_node-value = io_node->get_value( ).
      ls_node-index = iv_index.
      ls_node-order = cv_order.
      INSERT ls_node INTO TABLE ct_nodes.
    ELSEIF     lv_node_type <> zif_ayaml_types=>cs_type-mapping
           AND lv_node_type <> zif_ayaml_types=>cs_type-sequence.
      cv_order = cv_order + 1.
      ls_node-path  = `/`.
      ls_node-name  = ``.
      ls_node-type  = lv_node_type.
      ls_node-value = io_node->get_value( ).
      ls_node-index = 0.
      ls_node-order = cv_order.
      INSERT ls_node INTO TABLE ct_nodes.
      RETURN.
    ENDIF.

    IF iv_name IS INITIAL.
      lv_child_path = `/`.
    ELSE.
      lv_child_path = zcl_ayaml_utils=>append_path( iv_base = iv_path
                                                    iv_name = iv_name ).
    ENDIF.

    lt_children = io_node->get_children( ).

    CASE lv_node_type.
      WHEN zif_ayaml_types=>cs_type-mapping.
        LOOP AT lt_children ASSIGNING <fs_child>.
          traverse( EXPORTING io_node  = <fs_child>
                              iv_path  = lv_child_path
                              iv_name  = <fs_child>->get_key( )
                              iv_index = 0
                    CHANGING  ct_nodes = ct_nodes
                              cv_order = cv_order ).
        ENDLOOP.
      WHEN zif_ayaml_types=>cs_type-sequence.
        lv_seq_idx = 0.
        LOOP AT lt_children ASSIGNING <fs_child>.
          lv_seq_idx = lv_seq_idx + 1.
          traverse( EXPORTING io_node  = <fs_child>
                              iv_path  = lv_child_path
                              iv_name  = |{ lv_seq_idx }|
                              iv_index = lv_seq_idx
                    CHANGING  ct_nodes = ct_nodes
                              cv_order = cv_order ).
        ENDLOOP.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_serializer IMPLEMENTATION.
  METHOD stringify.
    DATA lv_base TYPE i.

    lv_base = iv_indent.
    IF lv_base < 0.
      lv_base = 0.
    ENDIF.
    rv_yaml = build_yaml( it_nodes  = it_nodes
                          iv_path   = '/'
                          iv_indent = lv_base ).
  ENDMETHOD.

  METHOD format_scalar.
    CASE is_node-type.
      WHEN zif_ayaml_types=>cs_type-null.
        rv_out = `null`.
      WHEN zif_ayaml_types=>cs_type-boolean.
        rv_out = is_node-value.
      WHEN zif_ayaml_types=>cs_type-number.
        rv_out = is_node-value.
      WHEN zif_ayaml_types=>cs_type-date.
        rv_out = is_node-value.
      WHEN OTHERS.
        IF zcl_ayaml_utils=>is_plain_scalar( is_node-value ) = abap_true.
          rv_out = is_node-value.
        ELSE.
          rv_out = |"{ zcl_ayaml_utils=>escape_text( is_node-value ) }"|.
        ENDIF.
    ENDCASE.
  ENDMETHOD.

  METHOD build_yaml.
    DATA lt_children   TYPE zif_ayaml_types=>ty_t_nodes_flat.
    DATA lv_indent     TYPE string.
    DATA lv_is_seq     TYPE abap_bool.
    DATA lv_child_yaml TYPE string.
    DATA lv_line       TYPE string.
    DATA lv_first_line TYPE string.
    DATA lv_rest       TYPE string.
    DATA lv_escaped    TYPE string.
    DATA lv_sub_len    TYPE i.
    FIELD-SYMBOLS <fs_node>  TYPE zif_ayaml_types=>ty_s_node.
    FIELD-SYMBOLS <fs_child> TYPE zif_ayaml_types=>ty_s_node.

    LOOP AT it_nodes ASSIGNING <fs_node> USING KEY path_key WHERE path = iv_path.
      INSERT <fs_node> INTO TABLE lt_children.
    ENDLOOP.

    SORT lt_children BY order.

    lv_is_seq = zcl_ayaml_utils=>is_sequence_path( it_nodes = it_nodes
                                                   iv_path  = iv_path ).

    LOOP AT lt_children ASSIGNING <fs_child>.
      CLEAR lv_indent.
      DO iv_indent TIMES.
        lv_indent = |{ lv_indent }  |.
      ENDDO.

      CASE lv_is_seq.
        WHEN abap_true.
          CASE <fs_child>-type.
            WHEN zif_ayaml_types=>cs_type-mapping.
              lv_child_yaml = build_yaml( it_nodes  = it_nodes
                                          iv_path   = |{ iv_path }{ <fs_child>-name }/|
                                          iv_indent = iv_indent + 1 ).
              IF lv_child_yaml IS INITIAL.
                lv_line = |{ lv_indent }- { <fs_child>-name }:|.
                rv_yaml = rv_yaml && lv_line && cl_abap_char_utilities=>newline.
              ELSE.
                lv_sub_len = strlen( lv_child_yaml ) - ( ( iv_indent + 1 ) * 2 ).
                lv_first_line = substring( val = lv_child_yaml
                                           off = ( iv_indent + 1 ) * 2
                                           len = lv_sub_len ).
                rv_yaml = |{ rv_yaml }{ lv_indent }- { lv_first_line }|.
                lv_rest = substring( val = lv_child_yaml
                                     off = ( ( iv_indent + 1 ) * 2 ) + strlen( lv_first_line ) ).
                IF lv_rest IS NOT INITIAL.
                  rv_yaml = rv_yaml && lv_rest.
                ENDIF.
              ENDIF.
            WHEN zif_ayaml_types=>cs_type-sequence.
              lv_line = |{ lv_indent }-|.
              lv_child_yaml = build_yaml( it_nodes  = it_nodes
                                          iv_path   = |{ iv_path }{ <fs_child>-name }/|
                                          iv_indent = iv_indent + 1 ).
              rv_yaml = rv_yaml && lv_line && cl_abap_char_utilities=>newline && lv_child_yaml.
            WHEN OTHERS.
              lv_escaped = format_scalar( <fs_child> ).
              lv_line = |{ lv_indent }- { lv_escaped }|.
              rv_yaml = rv_yaml && lv_line && cl_abap_char_utilities=>newline.
          ENDCASE.
        WHEN OTHERS.
          CASE <fs_child>-type.
            WHEN zif_ayaml_types=>cs_type-mapping.
              lv_line = |{ lv_indent }{ <fs_child>-name }:|.
              lv_child_yaml = build_yaml( it_nodes  = it_nodes
                                          iv_path   = |{ iv_path }{ <fs_child>-name }/|
                                          iv_indent = iv_indent + 1 ).
              IF lv_child_yaml IS INITIAL.
                rv_yaml = rv_yaml && lv_line && cl_abap_char_utilities=>newline.
              ELSE.
                rv_yaml = rv_yaml && lv_line && cl_abap_char_utilities=>newline && lv_child_yaml.
              ENDIF.
            WHEN zif_ayaml_types=>cs_type-sequence.
              lv_line = |{ lv_indent }{ <fs_child>-name }:|.
              lv_child_yaml = build_yaml( it_nodes  = it_nodes
                                          iv_path   = |{ iv_path }{ <fs_child>-name }/|
                                          iv_indent = iv_indent + 1 ).
              IF lv_child_yaml IS INITIAL.
                rv_yaml = |{ rv_yaml }{ lv_line } []{ cl_abap_char_utilities=>newline }|.
              ELSE.
                rv_yaml = rv_yaml && lv_line && cl_abap_char_utilities=>newline && lv_child_yaml.
              ENDIF.
            WHEN OTHERS.
              lv_escaped = format_scalar( <fs_child> ).
              lv_line = |{ lv_indent }{ <fs_child>-name }: { lv_escaped }|.
              rv_yaml = rv_yaml && lv_line && cl_abap_char_utilities=>newline.
          ENDCASE.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_deserializer IMPLEMENTATION.
  METHOD deserialize.
    map_node( EXPORTING it_nodes  = it_nodes
                        iv_path   = `/`
              CHANGING  cv_target = ev_data ).
  ENDMETHOD.

  METHOD map_node.
    DATA lo_descr  TYPE REF TO cl_abap_typedescr.
    DATA lo_struct TYPE REF TO cl_abap_structdescr.
    DATA lo_table  TYPE REF TO cl_abap_tabledescr.
    DATA lo_elem   TYPE REF TO cl_abap_elemdescr.
    DATA lv_parent TYPE string.
    DATA lv_name   TYPE string.
    FIELD-SYMBOLS <fs_node> TYPE zif_ayaml_types=>ty_s_node.

    lo_descr = cl_abap_typedescr=>describe_by_data( cv_target ).
    CASE lo_descr->kind.
      WHEN cl_abap_typedescr=>kind_struct.
        lo_struct ?= lo_descr.
        map_structure( EXPORTING it_nodes  = it_nodes
                                 iv_path   = iv_path
                                 io_struct = lo_struct
                       CHANGING  cv_target = cv_target ).
      WHEN cl_abap_typedescr=>kind_table.
        lo_table ?= lo_descr.
        map_table( EXPORTING it_nodes  = it_nodes
                             iv_path   = iv_path
                             io_table  = lo_table
                   CHANGING  cv_target = cv_target ).
      WHEN cl_abap_typedescr=>kind_elem.
        lo_elem ?= lo_descr.
        zcl_ayaml_utils=>split_path( EXPORTING iv_path = iv_path
                                     IMPORTING ev_path = lv_parent
                                               ev_name = lv_name ).
        READ TABLE it_nodes WITH KEY path = lv_parent
                                     name = lv_name ASSIGNING <fs_node>.
        IF sy-subrc = 0.
          map_elementary( EXPORTING is_node   = <fs_node>
                                    io_elem   = lo_elem
                          CHANGING  cv_target = cv_target ).
        ENDIF.
    ENDCASE.
  ENDMETHOD.

  METHOD map_structure.
    DATA lt_comps     TYPE abap_component_tab.
    DATA lv_sub       TYPE string.
    DATA lo_elem      TYPE REF TO cl_abap_elemdescr.
    DATA lv_camel     TYPE string.
    DATA lv_snake     TYPE string.
    DATA lv_lower     TYPE string.
    DATA lv_comp_name TYPE string.
    FIELD-SYMBOLS <fs_comp>  TYPE abap_componentdescr.
    FIELD-SYMBOLS <fs_node>  TYPE zif_ayaml_types=>ty_s_node.
    FIELD-SYMBOLS <fs_field> TYPE any.

    lt_comps = io_struct->get_components( ).
    LOOP AT lt_comps ASSIGNING <fs_comp>.
      ASSIGN COMPONENT <fs_comp>-name OF STRUCTURE cv_target TO <fs_field>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      lv_lower = to_lower( <fs_comp>-name ).
      READ TABLE it_nodes WITH KEY path = iv_path
                                   name = lv_lower ASSIGNING <fs_node>.
      IF sy-subrc <> 0.
        lv_comp_name = <fs_comp>-name.
        lv_camel = zcl_ayaml_utils=>to_camel_case( lv_comp_name ).
        READ TABLE it_nodes WITH KEY path = iv_path
                                     name = lv_camel ASSIGNING <fs_node>.
      ENDIF.
      IF sy-subrc <> 0.
        lv_comp_name = <fs_comp>-name.
        lv_snake = zcl_ayaml_utils=>to_snake_case( lv_comp_name ).
        READ TABLE it_nodes WITH KEY path = iv_path
                                     name = lv_snake ASSIGNING <fs_node>.
      ENDIF.
      IF sy-subrc <> 0.
        READ TABLE it_nodes WITH KEY path = iv_path
                                     name = <fs_comp>-name ASSIGNING <fs_node>.
      ENDIF.

      IF sy-subrc = 0.
        IF <fs_node>-type = zif_ayaml_types=>cs_type-mapping OR <fs_node>-type = zif_ayaml_types=>cs_type-sequence.
          lv_sub = |{ iv_path }{ <fs_node>-name }/|.
          map_node( EXPORTING it_nodes  = it_nodes
                              iv_path   = lv_sub
                    CHANGING  cv_target = <fs_field> ).
        ELSE.
          lo_elem ?= cl_abap_typedescr=>describe_by_data( <fs_field> ).
          map_elementary( EXPORTING is_node   = <fs_node>
                                    io_elem   = lo_elem
                          CHANGING  cv_target = <fs_field> ).
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD map_table.
    DATA lo_line_descr TYPE REF TO cl_abap_datadescr.
    DATA lt_children   TYPE zif_ayaml_types=>ty_t_nodes_flat.
    DATA lr_line       TYPE REF TO data.
    DATA lv_item_path  TYPE string.
    DATA lo_elem       TYPE REF TO cl_abap_elemdescr.
    FIELD-SYMBOLS <fs_tab>   TYPE ANY TABLE.
    FIELD-SYMBOLS <fs_line>  TYPE any.
    FIELD-SYMBOLS <fs_node>  TYPE zif_ayaml_types=>ty_s_node.
    FIELD-SYMBOLS <fs_child> TYPE zif_ayaml_types=>ty_s_node.

    ASSIGN cv_target TO <fs_tab>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    CLEAR <fs_tab>.

    LOOP AT it_nodes ASSIGNING <fs_node> USING KEY path_key WHERE path = iv_path.
      INSERT <fs_node> INTO TABLE lt_children.
    ENDLOOP.
    SORT lt_children BY order.

    lo_line_descr = io_table->get_table_line_type( ).
    CREATE DATA lr_line TYPE HANDLE lo_line_descr.
    ASSIGN lr_line->* TO <fs_line>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    LOOP AT lt_children ASSIGNING <fs_child>.
      CLEAR <fs_line>.
      IF <fs_child>-type = zif_ayaml_types=>cs_type-mapping OR <fs_child>-type = zif_ayaml_types=>cs_type-sequence.
        lv_item_path = |{ iv_path }{ <fs_child>-name }/|.
        map_node( EXPORTING it_nodes  = it_nodes
                            iv_path   = lv_item_path
                  CHANGING  cv_target = <fs_line> ).
      ELSEIF lo_line_descr->kind = cl_abap_typedescr=>kind_elem.
        lo_elem ?= lo_line_descr.
        map_elementary( EXPORTING is_node   = <fs_child>
                                  io_elem   = lo_elem
                        CHANGING  cv_target = <fs_line> ).
      ENDIF.
      INSERT <fs_line> INTO TABLE <fs_tab>.
    ENDLOOP.
  ENDMETHOD.

  METHOD map_elementary.
    DATA lv_val TYPE string.
    DATA lv_int TYPE i.
    DATA lv_flt TYPE f.

    lv_val = is_node-value.

    CASE io_elem->type_kind.
      WHEN cl_abap_typedescr=>typekind_int
          OR cl_abap_typedescr=>typekind_int1
          OR cl_abap_typedescr=>typekind_int2
          OR cl_abap_typedescr=>typekind_int8.
        TRY.
            lv_int = lv_val.
            cv_target = lv_int.
          CATCH cx_root.
            CLEAR cv_target.
        ENDTRY.
      WHEN cl_abap_typedescr=>typekind_float
          OR cl_abap_typedescr=>typekind_decfloat
          OR cl_abap_typedescr=>typekind_decfloat16
          OR cl_abap_typedescr=>typekind_decfloat34
          OR cl_abap_typedescr=>typekind_packed.
        TRY.
            lv_flt = lv_val.
            cv_target = lv_flt.
          CATCH cx_root.
            CLEAR cv_target.
        ENDTRY.
      WHEN cl_abap_typedescr=>typekind_date.
        TRY.
            cv_target = zcl_ayaml_utils=>parse_date( lv_val ).
          CATCH cx_root.
            CLEAR cv_target.
        ENDTRY.
      WHEN cl_abap_typedescr=>typekind_char
          OR cl_abap_typedescr=>typekind_string
          OR cl_abap_typedescr=>typekind_clike
          OR cl_abap_typedescr=>typekind_csequence.
        IF     io_elem->output_length = 1
           AND (    io_elem->absolute_name CS `ABAP_BOOL`
                 OR io_elem->absolute_name CS `ABAP_BOOLEAN`
                 OR io_elem->absolute_name CS `XSDBOOL` ).
          cv_target = boolc( lv_val = `true` OR lv_val = `X` OR lv_val = `1` ).
          RETURN.
        ENDIF.
        cv_target = lv_val.
      WHEN OTHERS.
        cv_target = lv_val.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
