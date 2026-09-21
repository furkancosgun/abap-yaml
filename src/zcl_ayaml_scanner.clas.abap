CLASS zcl_ayaml_scanner DEFINITION PUBLIC FINAL CREATE PUBLIC.

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
      IMPORTING iv_indicator  TYPE c
      RETURNING VALUE(rv_val) TYPE string
      RAISING   zcx_ayaml_error.

    METHODS scan_plain_scalar
      RETURNING VALUE(rv_val) TYPE string.

    METHODS emit_token
      IMPORTING iv_type   TYPE zif_ayaml_types=>ty_token_type
                iv_value  TYPE string
                iv_line   TYPE i OPTIONAL
                iv_column TYPE i OPTIONAL.



ENDCLASS.


CLASS zcl_ayaml_scanner IMPLEMENTATION.

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
    rv_yes = xsdbool( mv_pos >= mv_len ).
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
      mv_pos += 1.
      IF lv_char = cl_abap_char_utilities=>newline.
        mv_line += 1.
        mv_col = 1.
        mv_is_line_start = abap_true.
        mv_indent = 0.
      ELSE.
        mv_col += 1.
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
    ls_token-type       = iv_type.
    ls_token-value      = iv_value.
    IF iv_line IS NOT INITIAL.
      ls_token-line     = iv_line.
    ELSE.
      ls_token-line     = mv_line.
    ENDIF.
    IF iv_column IS NOT INITIAL.
      ls_token-column   = iv_column.
    ELSE.
      ls_token-column   = mv_col.
    ENDIF.
    ls_token-indent_num = mv_indent.
    INSERT ls_token INTO TABLE mt_tokens.
  ENDMETHOD.

  METHOD scan_line_start.
    DATA lv_char TYPE string.
    WHILE is_eof( ) = abap_false AND mv_is_line_start = abap_true.
      lv_char = peek( ).
      IF lv_char = ` `.
        mv_indent += 1.
        advance( ).
      ELSEIF lv_char = cl_abap_char_utilities=>horizontal_tab.
        RAISE EXCEPTION NEW zcx_ayaml_error( iv_msg = |Tab character not allowed at line { mv_line }| ).
      ELSEIF lv_char = cl_abap_char_utilities=>newline.
        advance( ).
        mv_indent = 0.
        mv_is_line_start = abap_true.
      ELSEIF lv_char = `#`.
        WHILE is_eof( ) = abap_false AND peek( ) <> cl_abap_char_utilities=>newline.
          advance( ).
        ENDWHILE.
        IF is_eof( ) = abap_false.
          advance( ).
        ENDIF.
        mv_indent = 0.
        mv_is_line_start = abap_true.
      ELSE.
        mv_is_line_start = abap_false.
        EXIT.
      ENDIF.
    ENDWHILE.
  ENDMETHOD.



  METHOD scan_single_quote.
    DATA lv_char TYPE c LENGTH 1.
    advance( ). " skip opening '
    CLEAR rv_val.
    WHILE is_eof( ) = abap_false.
      lv_char = peek( ).
      IF lv_char = `'`.
        IF peek( 1 ) = `'`.
          rv_val = |{ rv_val }'|.
          advance( 2 ).
        ELSE.
          advance( 1 ). " skip closing '
          RETURN.
        ENDIF.
      ELSEIF lv_char = cl_abap_char_utilities=>newline.
        rv_val = |{ rv_val }\n|.
        advance( ).
      ELSE.
        rv_val = |{ rv_val }{ lv_char }|.
        advance( ).
      ENDIF.
    ENDWHILE.
    RAISE EXCEPTION NEW zcx_ayaml_error( iv_msg = |Unterminated single-quoted string at line { mv_line }| ).
  ENDMETHOD.

  METHOD scan_double_quote.
    DATA lv_char TYPE c LENGTH 1.
    DATA lv_next TYPE c LENGTH 1.
    advance( ). " skip opening "
    CLEAR rv_val.
    WHILE is_eof( ) = abap_false.
      lv_char = peek( ).
      IF lv_char = `"`.
        advance( 1 ). " skip closing "
        RETURN.
      ELSEIF lv_char = `\`.
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
      ELSEIF lv_char = cl_abap_char_utilities=>newline.
        rv_val = |{ rv_val }{ cl_abap_char_utilities=>newline }|.
        advance( ).
      ELSE.
        rv_val = |{ rv_val }{ lv_char }|.
        advance( ).
      ENDIF.
    ENDWHILE.
    RAISE EXCEPTION NEW zcx_ayaml_error( iv_msg = |Unterminated double-quoted string at line { mv_line }| ).
  ENDMETHOD.

  METHOD scan_block_scalar.
    DATA lv_chomping       TYPE c LENGTH 1. " ' ' (clip), '-' (strip), '+' (keep)
    DATA lv_char           TYPE c LENGTH 1.
    DATA lv_scalar_indent  TYPE i VALUE -1.
    DATA lv_line_indent    TYPE i.
    DATA lv_line_buf       TYPE string.
    DATA lt_lines          TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA lv_result         TYPE string.
    DATA lv_extra TYPE i.
    DATA lv_idx TYPE i.
    DATA lv_count TYPE i.
    DATA lv_line TYPE string.
    DATA lv_prev_idx TYPE i.
    DATA lv_prev_line TYPE string.

    advance( ). " skip | or >
    lv_char = peek( ).
    IF lv_char = `-` OR lv_char = `+`.
      lv_chomping = lv_char.
      advance( ).
    ENDIF.

    " Skip rest of header line
    WHILE is_eof( ) = abap_false AND peek( ) <> cl_abap_char_utilities=>newline.
      advance( ).
    ENDWHILE.
    IF is_eof( ) = abap_false.
      advance( ). " consume newline
    ENDIF.

    " Read scalar content lines
    WHILE is_eof( ) = abap_false.
      " Count indent of current line
      lv_line_indent = 0.
      WHILE is_eof( ) = abap_false AND peek( ) = ` `.
        lv_line_indent += 1.
        advance( ).
      ENDWHILE.

      " Empty line in block scalar
      IF peek( ) = cl_abap_char_utilities=>newline.
        advance( ).
        INSERT `` INTO TABLE lt_lines.
        CONTINUE.
      ENDIF.

      IF is_eof( ) = abap_true.
        EXIT.
      ENDIF.

      " Determine scalar base indent from first non-empty line
      IF lv_scalar_indent < 0.
        IF lv_line_indent <= mv_indent.
          " Scalar ended immediately
          EXIT.
        ENDIF.
        lv_scalar_indent = lv_line_indent.
      ELSEIF lv_line_indent < lv_scalar_indent.
        " Indentation dropped below scalar base indent -> scalar block ended!
        " Backtrack spaces so next token can read indent
        mv_pos -= lv_line_indent.
        mv_col -= lv_line_indent.
        mv_indent = lv_line_indent.
        mv_is_line_start = abap_false.
        EXIT.
      ENDIF.

      " Read the rest of line
      CLEAR lv_line_buf.
      " If line had extra indent beyond base indent, preserve it

      lv_extra = lv_line_indent - lv_scalar_indent.
      DO lv_extra TIMES.
        lv_line_buf = |{ lv_line_buf } |.
      ENDDO.

      WHILE is_eof( ) = abap_false AND peek( ) <> cl_abap_char_utilities=>newline.
        lv_line_buf = |{ lv_line_buf }{ peek( ) }|.
        advance( ).
      ENDWHILE.
      IF is_eof( ) = abap_false.
        advance( ). " consume newline
      ENDIF.
      INSERT lv_line_buf INTO TABLE lt_lines.
    ENDWHILE.

    " Assemble lines according to style (| vs >)



    lv_count = lines( lt_lines ).

    IF iv_indicator = `|`.
      LOOP AT lt_lines INTO lv_line.
        lv_idx += 1.
        IF lv_idx = 1.
          lv_result = lv_line.
        ELSE.
          lv_result = |{ lv_result }{ cl_abap_char_utilities=>newline }{ lv_line }|.
        ENDIF.
      ENDLOOP.
      IF lv_chomping <> `-` AND lv_count > 0.
        lv_result = |{ lv_result }{ cl_abap_char_utilities=>newline }|.
      ENDIF.
    ELSE.
      " Folded style (>)
      LOOP AT lt_lines INTO lv_line.
        lv_idx += 1.
        IF lv_idx = 1.
          lv_result = lv_line.
        ELSEIF lv_line IS INITIAL.
          lv_result = |{ lv_result }{ cl_abap_char_utilities=>newline }|.
        ELSE.

          lv_prev_idx = lv_idx - 1.

          READ TABLE lt_lines INDEX lv_prev_idx INTO lv_prev_line.
          IF lv_prev_line IS INITIAL.
            lv_result = |{ lv_result }{ lv_line }|.
          ELSE.
            lv_result = |{ lv_result } { lv_line }|.
          ENDIF.
        ENDIF.
      ENDLOOP.
      IF lv_chomping <> `-` AND lv_count > 0.
        lv_result = |{ lv_result }{ cl_abap_char_utilities=>newline }|.
      ENDIF.
    ENDIF.

    rv_val = lv_result.
  ENDMETHOD.

  METHOD scan_plain_scalar.
    DATA lv_char TYPE c LENGTH 1.


    DATA lv_p_pos TYPE i.
    DATA lv_last_pos TYPE i.
    CLEAR rv_val.

    WHILE is_eof( ) = abap_false.
      lv_char = peek( ).
      IF lv_char = cl_abap_char_utilities=>newline.
        EXIT.
      ENDIF.
      IF lv_char = `#` AND rv_val IS NOT INITIAL.
        " Comment delimiter


        lv_p_pos = mv_pos - 1.
        IF lv_p_pos >= 0 AND mv_source+lv_p_pos(1) = ` `.
          EXIT.
        ENDIF.
      ENDIF.
      IF lv_char = `:` AND ( peek( 1 ) = ` ` OR peek( 1 ) = cl_abap_char_utilities=>newline OR peek( 1 ) IS INITIAL ).
        " Mapping key colon
        EXIT.
      ENDIF.
      IF mv_flow_depth > 0 AND ( lv_char = `,` OR lv_char = `]` OR lv_char = `}` ).
        EXIT.
      ENDIF.
      rv_val = |{ rv_val }{ lv_char }|.
      advance( ).
    ENDWHILE.

    " Trim trailing spaces
    WHILE strlen( rv_val ) > 0.

      lv_last_pos = strlen( rv_val ) - 1.
      IF rv_val+lv_last_pos(1) = ` `.
        rv_val = rv_val(lv_last_pos).
      ELSE.
        EXIT.
      ENDIF.
    ENDWHILE.
  ENDMETHOD.

  METHOD scan.
    DATA lv_char       TYPE c LENGTH 1.
    DATA lv_start_line TYPE i.
    DATA lv_start_col  TYPE i.
    DATA lv_scalar_val TYPE string.
    DATA lv_anchor_name TYPE string.
    DATA lv_alias_name TYPE string.

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

      lv_char       = peek( ).
      lv_start_line = mv_line.
      lv_start_col  = mv_col.

      " Document start / end
      IF lv_start_col = 1 AND mv_indent = 0.
        IF lv_char = `-` AND peek( 1 ) = `-` AND peek( 2 ) = `-`.
          advance( 3 ).
          emit_token( iv_type = zif_ayaml_types=>cs_token_type-doc_start iv_value = `---` ).
          CONTINUE.
        ELSEIF lv_char = `.` AND peek( 1 ) = `.` AND peek( 2 ) = `.`.
          advance( 3 ).
          emit_token( iv_type = zif_ayaml_types=>cs_token_type-doc_end iv_value = `...` ).
          CONTINUE.
        ENDIF.
      ENDIF.

      " Comment
      IF lv_char = `#`.
        WHILE is_eof( ) = abap_false AND peek( ) <> cl_abap_char_utilities=>newline.
          advance( ).
        ENDWHILE.
        CONTINUE.
      ENDIF.

      " Newline
      IF lv_char = cl_abap_char_utilities=>newline.
        advance( ).
        CONTINUE.
      ENDIF.

      " Block Sequence Entry
      IF lv_char = `-` AND ( peek( 1 ) = ` ` OR peek( 1 ) = cl_abap_char_utilities=>newline OR peek( 1 ) IS INITIAL ).
        advance( 1 ).
        emit_token( iv_type   = zif_ayaml_types=>cs_token_type-seq_entry
                    iv_value  = `-`
                    iv_line   = lv_start_line
                    iv_column = lv_start_col ).
        CONTINUE.
      ENDIF.

      " Flow syntax
      IF lv_char = `{`.
        mv_flow_depth += 1.
        advance( 1 ).
        emit_token( iv_type   = zif_ayaml_types=>cs_token_type-flow_map_start
                    iv_value  = `{`
                    iv_line   = lv_start_line
                    iv_column = lv_start_col ).
        CONTINUE.
      ELSEIF lv_char = `}`.
        IF mv_flow_depth > 0.
          mv_flow_depth -= 1.
        ENDIF.
        advance( 1 ).
        emit_token( iv_type   = zif_ayaml_types=>cs_token_type-flow_map_end
                    iv_value  = `}`
                    iv_line   = lv_start_line
                    iv_column = lv_start_col ).
        CONTINUE.
      ELSEIF lv_char = `[`.
        mv_flow_depth += 1.
        advance( 1 ).
        emit_token( iv_type   = zif_ayaml_types=>cs_token_type-flow_seq_start
                    iv_value  = `[`
                    iv_line   = lv_start_line
                    iv_column = lv_start_col ).
        CONTINUE.
      ELSEIF lv_char = `]`.
        IF mv_flow_depth > 0.
          mv_flow_depth -= 1.
        ENDIF.
        advance( 1 ).
        emit_token( iv_type   = zif_ayaml_types=>cs_token_type-flow_seq_end
                    iv_value  = `]`
                    iv_line   = lv_start_line
                    iv_column = lv_start_col ).
        CONTINUE.
      ELSEIF lv_char = `,`.
        advance( 1 ).
        emit_token( iv_type   = zif_ayaml_types=>cs_token_type-flow_entry
                    iv_value  = `,`
                    iv_line   = lv_start_line
                    iv_column = lv_start_col ).
        CONTINUE.
      ENDIF.

      " Anchor
      IF lv_char = `&`.
        advance( 1 ).

        CLEAR lv_anchor_name.
        WHILE is_eof( ) = abap_false AND peek( ) <> ` ` AND peek( ) <> cl_abap_char_utilities=>newline.
          lv_anchor_name = |{ lv_anchor_name }{ peek( ) }|.
          advance( 1 ).
        ENDWHILE.
        emit_token( iv_type   = zif_ayaml_types=>cs_token_type-anchor
                    iv_value  = lv_anchor_name
                    iv_line   = lv_start_line
                    iv_column = lv_start_col ).
        CONTINUE.
      ENDIF.

      " Alias
      IF lv_char = `*`.
        advance( 1 ).

        CLEAR lv_alias_name.
        WHILE is_eof( ) = abap_false AND peek( ) <> ` ` AND peek( ) <> cl_abap_char_utilities=>newline.
          lv_alias_name = |{ lv_alias_name }{ peek( ) }|.
          advance( 1 ).
        ENDWHILE.
        emit_token( iv_type   = zif_ayaml_types=>cs_token_type-alias
                    iv_value  = lv_alias_name
                    iv_line   = lv_start_line
                    iv_column = lv_start_col ).
        CONTINUE.
      ENDIF.

      " Literal or Folded Block Scalar
      IF ( lv_char = `|` OR lv_char = `>` ) AND mv_flow_depth = 0.
        lv_scalar_val = scan_block_scalar( lv_char ).
        emit_token( iv_type   = zif_ayaml_types=>cs_token_type-scalar
                    iv_value  = lv_scalar_val
                    iv_line   = lv_start_line
                    iv_column = lv_start_col ).
        CONTINUE.
      ENDIF.

      " Quoted String
      IF lv_char = `'`.
        lv_scalar_val = scan_single_quote( ).
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
        CONTINUE.
      ELSEIF lv_char = `"`.
        lv_scalar_val = scan_double_quote( ).
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
        CONTINUE.
      ENDIF.

      " Mapping Colon by itself (e.g. key was already scanned or blank)
      IF lv_char = `:` AND ( peek( 1 ) = ` ` OR peek( 1 ) = cl_abap_char_utilities=>newline OR peek( 1 ) IS INITIAL ).
        advance( 1 ).
        emit_token( iv_type   = zif_ayaml_types=>cs_token_type-map_val
                    iv_value  = `:`
                    iv_line   = lv_start_line
                    iv_column = lv_start_col ).
        CONTINUE.
      ENDIF.

      " Plain scalar or unquoted mapping key
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

    emit_token( iv_type = zif_ayaml_types=>cs_token_type-eof iv_value = `` ).
    rt_tokens = mt_tokens.
  ENDMETHOD.

ENDCLASS.
