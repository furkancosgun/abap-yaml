CLASS zcl_ayaml_parser DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS parse
      IMPORTING iv_yaml         TYPE string
      RETURNING VALUE(rt_nodes) TYPE zif_ayaml_types=>ty_t_nodes
      RAISING   zcx_ayaml_error.

  PRIVATE SECTION.
    CLASS-METHODS detect_type_and_value
      IMPORTING iv_raw   TYPE string
      EXPORTING ev_type  TYPE zif_ayaml_types=>ty_node_type
                ev_value TYPE string.

    CLASS-METHODS trim_stack
      IMPORTING iv_level TYPE i
      CHANGING  ct_stack TYPE zif_ayaml_types=>ty_t_string.

    CLASS-METHODS get_next_seq_index
      IMPORTING it_nodes        TYPE zif_ayaml_types=>ty_t_nodes
                iv_path         TYPE string
      RETURNING VALUE(rv_index) TYPE i.

    CLASS-METHODS ensure_parent_is_sequence
      IMPORTING iv_parent TYPE string
      CHANGING  ct_nodes  TYPE zif_ayaml_types=>ty_t_nodes.

    CLASS-METHODS parse_document
      IMPORTING iv_trimmed TYPE string
                iv_parent  TYPE string
                iv_level   TYPE i
      CHANGING  ct_nodes   TYPE zif_ayaml_types=>ty_t_nodes
                ct_stack   TYPE zif_ayaml_types=>ty_t_string
                cv_order   TYPE i
      RAISING   zcx_ayaml_error.

    CLASS-METHODS parse_block
      IMPORTING iv_key       TYPE string
                iv_raw_value TYPE string
                iv_parent    TYPE string
                iv_level     TYPE i
      CHANGING  ct_nodes     TYPE zif_ayaml_types=>ty_t_nodes
                ct_stack     TYPE zif_ayaml_types=>ty_t_string
                cv_order     TYPE i.

    CLASS-METHODS parse_inline
      IMPORTING iv_key       TYPE string
                iv_raw_value TYPE string
                iv_parent    TYPE string
                iv_level     TYPE i
      CHANGING  ct_nodes     TYPE zif_ayaml_types=>ty_t_nodes
                ct_stack     TYPE zif_ayaml_types=>ty_t_string
                cv_order     TYPE i.

ENDCLASS.


CLASS zcl_ayaml_parser IMPLEMENTATION.
  METHOD parse.
    DATA lt_lines   TYPE zif_ayaml_types=>ty_t_string.
    DATA lv_line    TYPE string.
    DATA lv_trimmed TYPE string.
    DATA lv_indent  TYPE i.
    DATA lv_level   TYPE i.
    DATA lv_parent  TYPE string.
    DATA lv_order   TYPE i.
    DATA lt_stack   TYPE zif_ayaml_types=>ty_t_string.

    IF iv_yaml CS cl_abap_char_utilities=>horizontal_tab.
      RAISE EXCEPTION NEW zcx_ayaml_error( iv_msg = `Tab character not allowed` ).
    ENDIF.
    SPLIT iv_yaml AT cl_abap_char_utilities=>newline INTO TABLE lt_lines.
    CLEAR rt_nodes.
    CLEAR lt_stack.
    INSERT `/` INTO TABLE lt_stack.
    lv_order = 0.

    LOOP AT lt_lines INTO lv_line.
      IF lv_line CS cl_abap_char_utilities=>horizontal_tab.
        RAISE EXCEPTION NEW zcx_ayaml_error( iv_msg = `Tab character not allowed` ).
      ENDIF.
      lv_trimmed = lv_line.
      SHIFT lv_trimmed LEFT DELETING LEADING ` `.
      IF lv_trimmed IS INITIAL.
        CONTINUE.
      ENDIF.
      IF substring( val = lv_trimmed
                    off = 0
                    len = 1 ) = `#`.
        CONTINUE.
      ENDIF.
      lv_indent = strlen( lv_line ) - strlen( lv_trimmed ).
      IF lv_indent MOD 2 <> 0.
        RAISE EXCEPTION NEW zcx_ayaml_error( iv_msg = `Invalid indent` ).
      ENDIF.
      lv_level = lv_indent / 2.
      IF lv_level >= lines( lt_stack ).
        RAISE EXCEPTION NEW zcx_ayaml_error( iv_msg = `Invalid indent level` ).
      ENDIF.
      READ TABLE lt_stack INDEX lv_level + 1 INTO lv_parent.
      ASSERT sy-subrc = 0.

      parse_document( EXPORTING iv_trimmed = lv_trimmed
                                iv_parent  = lv_parent
                                iv_level   = lv_level
                      CHANGING  ct_nodes   = rt_nodes
                                ct_stack   = lt_stack
                                cv_order   = lv_order ).
    ENDLOOP.
  ENDMETHOD.

  METHOD parse_document.
    DATA lv_len       TYPE i.
    DATA lv_first_two TYPE string.
    DATA lv_seq_value TYPE string.
    DATA lv_key       TYPE string.
    DATA lv_raw_value TYPE string.
    DATA lv_pos       TYPE i.
    DATA lv_seq_index TYPE i.
    DATA ls_node      TYPE zif_ayaml_types=>ty_s_node.
    DATA lv_type      TYPE zif_ayaml_types=>ty_node_type.
    DATA lv_value     TYPE string.

    lv_len = strlen( iv_trimmed ).
    IF lv_len >= 2.
      lv_first_two = substring( val = iv_trimmed
                                off = 0
                                len = 2 ).
    ELSE.
      lv_first_two = iv_trimmed.
    ENDIF.

    IF substring( val = iv_trimmed
                  off = 0
                  len = 1 ) = `-` AND ( lv_len = 1 OR lv_first_two = `- ` ).
      IF lv_len = 1.
        lv_seq_value = ``.
      ELSE.
        lv_seq_value = substring( val = iv_trimmed
                                  off = 2
                                  len = lv_len - 2 ).
        lv_seq_value = condense( lv_seq_value ).
      ENDIF.

      cv_order += 1.
      lv_seq_index = get_next_seq_index( it_nodes = ct_nodes
                                         iv_path  = iv_parent ).

      IF lv_seq_value IS INITIAL.
        ls_node-path  = iv_parent.
        ls_node-name  = |{ lv_seq_index }|.
        ls_node-type  = zif_ayaml_types=>cs_type-mapping.
        ls_node-value = ``.
        ls_node-index = lv_seq_index.
        ls_node-order = cv_order.
        INSERT ls_node INTO TABLE ct_nodes.
      ELSE.
        FIND FIRST OCCURRENCE OF `:` IN lv_seq_value MATCH OFFSET lv_pos.
        IF sy-subrc = 0.
          lv_key = substring( val = lv_seq_value
                              len = lv_pos ).
          lv_raw_value = substring( val = lv_seq_value
                                    off = lv_pos + 1
                                    len = strlen( lv_seq_value ) - lv_pos - 1 ).
          lv_key = condense( lv_key ).
          lv_raw_value = condense( lv_raw_value ).
          detect_type_and_value( EXPORTING iv_raw   = lv_raw_value
                                 IMPORTING ev_type  = lv_type
                                           ev_value = lv_value ).
          ls_node-path  = iv_parent.
          ls_node-name  = |{ lv_seq_index }|.
          ls_node-type  = zif_ayaml_types=>cs_type-mapping.
          ls_node-value = ``.
          ls_node-index = lv_seq_index.
          ls_node-order = cv_order.
          INSERT ls_node INTO TABLE ct_nodes.
          DATA(lv_item_path) = |{ iv_parent }{ lv_seq_index }/|.
          ls_node-path  = lv_item_path.
          ls_node-name  = lv_key.
          ls_node-type  = lv_type.
          ls_node-value = lv_value.
          ls_node-index = 0.
          ls_node-order = cv_order + 1.
          INSERT ls_node INTO TABLE ct_nodes.
          cv_order += 1.
        ELSE.
          detect_type_and_value( EXPORTING iv_raw   = lv_seq_value
                                 IMPORTING ev_type  = lv_type
                                           ev_value = lv_value ).
          ls_node-path  = iv_parent.
          ls_node-name  = |{ lv_seq_index }|.
          ls_node-type  = lv_type.
          ls_node-value = lv_value.
          ls_node-index = lv_seq_index.
          ls_node-order = cv_order.
          INSERT ls_node INTO TABLE ct_nodes.
        ENDIF.
      ENDIF.

      ensure_parent_is_sequence( EXPORTING iv_parent = iv_parent
                                 CHANGING  ct_nodes  = ct_nodes ).
      RETURN.
    ENDIF.

    FIND FIRST OCCURRENCE OF `:` IN iv_trimmed MATCH OFFSET lv_pos.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    lv_key = substring( val = iv_trimmed
                        len = lv_pos ).
    lv_raw_value = substring( val = iv_trimmed
                              off = lv_pos + 1
                              len = strlen( iv_trimmed ) - lv_pos - 1 ).
    lv_key = condense( lv_key ).
    lv_raw_value = condense( lv_raw_value ).

    IF lv_raw_value IS INITIAL.
      parse_block( EXPORTING iv_key       = lv_key
                             iv_raw_value = lv_raw_value
                             iv_parent    = iv_parent
                             iv_level     = iv_level
                   CHANGING  ct_nodes     = ct_nodes
                             ct_stack     = ct_stack
                             cv_order     = cv_order ).
    ELSEIF lv_raw_value(1) = `[`.
      parse_inline( EXPORTING iv_key       = lv_key
                              iv_raw_value = lv_raw_value
                              iv_parent    = iv_parent
                              iv_level     = iv_level
                    CHANGING  ct_nodes     = ct_nodes
                              ct_stack     = ct_stack
                              cv_order     = cv_order ).
    ELSE.
      parse_block( EXPORTING iv_key       = lv_key
                             iv_raw_value = lv_raw_value
                             iv_parent    = iv_parent
                             iv_level     = iv_level
                   CHANGING  ct_nodes     = ct_nodes
                             ct_stack     = ct_stack
                             cv_order     = cv_order ).
    ENDIF.
  ENDMETHOD.

  METHOD parse_block.
    DATA ls_node  TYPE zif_ayaml_types=>ty_s_node.
    DATA lv_type  TYPE zif_ayaml_types=>ty_node_type.
    DATA lv_value TYPE string.

    cv_order += 1.
    IF iv_raw_value IS INITIAL.
      ls_node-path  = iv_parent.
      ls_node-name  = iv_key.
      ls_node-type  = zif_ayaml_types=>cs_type-mapping.
      ls_node-value = ``.
      ls_node-index = 0.
      ls_node-order = cv_order.
      INSERT ls_node INTO TABLE ct_nodes.
      trim_stack( EXPORTING iv_level = iv_level
                  CHANGING  ct_stack = ct_stack ).
      READ TABLE ct_stack INDEX iv_level + 1 INTO DATA(lv_parent_tmp).
      ASSERT sy-subrc = 0.
      INSERT |{ lv_parent_tmp }{ iv_key }/| INTO TABLE ct_stack.
    ELSE.
      detect_type_and_value( EXPORTING iv_raw   = iv_raw_value
                             IMPORTING ev_type  = lv_type
                                       ev_value = lv_value ).
      ls_node-path  = iv_parent.
      ls_node-name  = iv_key.
      ls_node-type  = lv_type.
      ls_node-value = lv_value.
      ls_node-index = 0.
      ls_node-order = cv_order.
      INSERT ls_node INTO TABLE ct_nodes.
      trim_stack( EXPORTING iv_level = iv_level
                  CHANGING  ct_stack = ct_stack ).
    ENDIF.
  ENDMETHOD.

  METHOD parse_inline.
    DATA ls_node   TYPE zif_ayaml_types=>ty_s_node.
    DATA lt_items  TYPE zif_ayaml_types=>ty_t_string.
    DATA lv_inline TYPE string.
    DATA lv_type   TYPE zif_ayaml_types=>ty_node_type.
    DATA lv_value  TYPE string.

    cv_order += 1.
    ls_node-path  = iv_parent.
    ls_node-name  = iv_key.
    ls_node-type  = zif_ayaml_types=>cs_type-sequence.
    ls_node-value = ``.
    ls_node-index = 0.
    ls_node-order = cv_order.
    INSERT ls_node INTO TABLE ct_nodes.

    lv_inline = substring( val = iv_raw_value
                           off = 1
                           len = strlen( iv_raw_value ) - 2 ).
    SPLIT lv_inline AT `,` INTO TABLE lt_items.
    DATA(lv_item_idx) = 0.
    LOOP AT lt_items INTO DATA(lv_item_raw).
      lv_item_raw = condense( lv_item_raw ).
      lv_item_idx += 1.
      detect_type_and_value( EXPORTING iv_raw   = lv_item_raw
                             IMPORTING ev_type  = lv_type
                                       ev_value = lv_value ).
      CLEAR ls_node.
      ls_node-path  = |{ iv_parent }{ iv_key }/|.
      ls_node-name  = |{ lv_item_idx }|.
      ls_node-type  = lv_type.
      ls_node-value = lv_value.
      ls_node-index = lv_item_idx.
      ls_node-order = cv_order + lv_item_idx.
      INSERT ls_node INTO TABLE ct_nodes.
    ENDLOOP.
    trim_stack( EXPORTING iv_level = iv_level
                CHANGING  ct_stack = ct_stack ).
  ENDMETHOD.

  METHOD trim_stack.
    DATA lt_tmp    TYPE zif_ayaml_types=>ty_t_string.
    DATA lv_parent TYPE string.

    IF iv_level + 1 < lines( ct_stack ).
      CLEAR lt_tmp.
      DO iv_level + 1 TIMES.
        READ TABLE ct_stack INDEX sy-index INTO lv_parent.
        IF sy-subrc = 0.
          INSERT lv_parent INTO TABLE lt_tmp.
        ENDIF.
      ENDDO.
      ct_stack = lt_tmp.
    ENDIF.
  ENDMETHOD.

  METHOD get_next_seq_index.
    rv_index = 0.
    LOOP AT it_nodes TRANSPORTING NO FIELDS USING KEY path_key WHERE path = iv_path.
      rv_index += 1.
    ENDLOOP.
    rv_index += 1.
  ENDMETHOD.

  METHOD ensure_parent_is_sequence.
    DATA lv_parent_path TYPE string.
    DATA lv_parent_name TYPE string.
    DATA ls_node        TYPE zif_ayaml_types=>ty_s_node.

    IF strlen( iv_parent ) <= 1.
      RETURN.
    ENDIF.
    DATA(lv_len) = strlen( iv_parent ).
    IF substring( val = iv_parent
                  off = lv_len - 1
                  len = 1 ) <> `/`.
      RETURN.
    ENDIF.
    DATA(lv_trim) = substring( val = iv_parent
                               len = lv_len - 1 ).
    zcl_ayaml_path_utils=>split( EXPORTING iv_path = lv_trim
                                 IMPORTING ev_path = lv_parent_path
                                           ev_name = lv_parent_name ).
    READ TABLE ct_nodes WITH KEY path = lv_parent_path
                                 name = lv_parent_name INTO ls_node.
    IF sy-subrc = 0 AND ls_node-type = zif_ayaml_types=>cs_type-mapping.
      ls_node-type = zif_ayaml_types=>cs_type-sequence.
      MODIFY TABLE ct_nodes FROM ls_node.
    ENDIF.
  ENDMETHOD.

  METHOD detect_type_and_value.
    zcl_ayaml_type_utils=>detect_yaml_scalar( EXPORTING iv_raw   = iv_raw
                                              IMPORTING ev_type  = ev_type
                                                        ev_value = ev_value ).
  ENDMETHOD.
ENDCLASS.
