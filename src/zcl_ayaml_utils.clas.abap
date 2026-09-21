CLASS zcl_ayaml_utils DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS normalize_path
      IMPORTING iv_path        TYPE string
      RETURNING VALUE(rv_norm) TYPE string.

    CLASS-METHODS split_path
      IMPORTING iv_path TYPE string
      EXPORTING ev_path TYPE string
                ev_name TYPE string.

    CLASS-METHODS get_parent_path
      IMPORTING iv_path          TYPE string
      RETURNING VALUE(rv_parent) TYPE string.

    CLASS-METHODS build_path
      IMPORTING iv_parent      TYPE string
                iv_name        TYPE string
      RETURNING VALUE(rv_path) TYPE string.

    CLASS-METHODS append_path
      IMPORTING iv_base        TYPE string
                iv_name        TYPE string
      RETURNING VALUE(rv_path) TYPE string.

    CLASS-METHODS is_sequence_path
      IMPORTING it_nodes      TYPE zif_ayaml_types=>ty_t_nodes
                iv_path       TYPE string
      RETURNING VALUE(rv_yes) TYPE abap_bool.

    CLASS-METHODS escape_text
      IMPORTING iv_value          TYPE string
      RETURNING VALUE(rv_escaped) TYPE string.

    CLASS-METHODS unescape_text
      IMPORTING iv_value        TYPE string
      RETURNING VALUE(rv_value) TYPE string.

    CLASS-METHODS strip_quotes
      IMPORTING iv_value        TYPE string
      RETURNING VALUE(rv_value) TYPE string.

    CLASS-METHODS is_plain_scalar
      IMPORTING iv_value        TYPE string
      RETURNING VALUE(rv_plain) TYPE abap_bool.

    CLASS-METHODS detect_type
      IMPORTING iv_val         TYPE any
      RETURNING VALUE(rv_type) TYPE zif_ayaml_types=>ty_node_type.

    CLASS-METHODS to_string
      IMPORTING iv_val        TYPE any
                iv_type       TYPE zif_ayaml_types=>ty_node_type
      RETURNING VALUE(rv_str) TYPE string.

    CLASS-METHODS format_date
      IMPORTING iv_date       TYPE d
      RETURNING VALUE(rv_str) TYPE string.

    CLASS-METHODS format_timestamp
      IMPORTING iv_timestamp  TYPE timestamp
      RETURNING VALUE(rv_str) TYPE string.

    CLASS-METHODS parse_date
      IMPORTING iv_value       TYPE string
      RETURNING VALUE(rv_date) TYPE d
      RAISING   zcx_ayaml_error.

    CLASS-METHODS parse_timestamp
      IMPORTING iv_value            TYPE string
      RETURNING VALUE(rv_timestamp) TYPE timestamp
      RAISING   zcx_ayaml_error.

    CLASS-METHODS detect_yaml_scalar
      IMPORTING iv_raw   TYPE string
      EXPORTING ev_type  TYPE zif_ayaml_types=>ty_node_type
                ev_value TYPE string.

    CLASS-METHODS to_camel_case
      IMPORTING iv_name        TYPE string
      RETURNING VALUE(rv_name) TYPE string.

    CLASS-METHODS to_snake_case
      IMPORTING iv_name        TYPE string
      RETURNING VALUE(rv_name) TYPE string.

    CLASS-METHODS format_field_name
      IMPORTING iv_name        TYPE string
                iv_format      TYPE zif_ayaml_types=>ty_format OPTIONAL
      RETURNING VALUE(rv_name) TYPE string.

ENDCLASS.


CLASS zcl_ayaml_utils IMPLEMENTATION.
  METHOD normalize_path.
    DATA lv_len  TYPE i.
    DATA lv_off  TYPE i.
    DATA lv_last TYPE string.

    rv_norm = iv_path.
    IF rv_norm IS INITIAL.
      rv_norm = `/`.
      RETURN.
    ENDIF.
    IF substring( val = rv_norm
                  off = 0
                  len = 1 ) <> `/`.
      rv_norm = |/{ rv_norm }|.
    ENDIF.
    lv_len = strlen( rv_norm ).
    WHILE lv_len > 1.
      lv_off = lv_len - 1.
      lv_last = substring( val = rv_norm
                           off = lv_off
                           len = 1 ).
      IF lv_last <> `/`.
        EXIT.
      ENDIF.
      lv_len = lv_len - 1.
      rv_norm = substring( val = rv_norm
                           len = lv_len ).
    ENDWHILE.
  ENDMETHOD.

  METHOD split_path.
    DATA lv_norm   TYPE string.
    DATA lv_len    TYPE i.
    DATA lv_found  TYPE abap_bool.
    DATA lv_last   TYPE i.
    DATA lv_offset TYPE i.

    lv_norm = normalize_path( iv_path ).
    lv_len = strlen( lv_norm ).

    IF lv_norm = `/`.
      ev_path = `/`.
      ev_name = ``.
      RETURN.
    ENDIF.

    lv_found = abap_false.
    lv_last = 0.
    DO lv_len TIMES.
      lv_offset = sy-index - 1.
      IF substring( val = lv_norm
                    off = lv_offset
                    len = 1 ) = `/`.
        lv_last = lv_offset.
        lv_found = abap_true.
      ENDIF.
    ENDDO.

    IF lv_found = abap_false.
      ev_path = `/`.
      ev_name = lv_norm.
      RETURN.
    ENDIF.

    ev_path = substring( val = lv_norm
                         len = lv_last + 1 ).
    ev_name = substring( val = lv_norm
                         off = lv_last + 1
                         len = lv_len - lv_last - 1 ).
  ENDMETHOD.

  METHOD get_parent_path.
    DATA lv_parent TYPE string.
    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA lv_name   TYPE string.

    split_path( EXPORTING iv_path = iv_path
                IMPORTING ev_path = lv_parent
                          ev_name = lv_name ).
    rv_parent = lv_parent.
  ENDMETHOD.

  METHOD build_path.
    DATA lv_parent_norm TYPE string.

    lv_parent_norm = normalize_path( iv_parent ).
    IF lv_parent_norm = `/`.
      rv_path = |/{ iv_name }|.
    ELSE.
      rv_path = |{ lv_parent_norm }/{ iv_name }|.
    ENDIF.
  ENDMETHOD.

  METHOD append_path.
    DATA lv_base_norm TYPE string.

    lv_base_norm = normalize_path( iv_base ).
    IF lv_base_norm = `/`.
      rv_path = |/{ iv_name }/|.
    ELSE.
      rv_path = |{ lv_base_norm }/{ iv_name }/|.
    ENDIF.
  ENDMETHOD.

  METHOD is_sequence_path.
    DATA lv_parent TYPE string.
    DATA lv_name   TYPE string.
    DATA lv_trim   TYPE string.
    DATA lv_len    TYPE i.
    FIELD-SYMBOLS <fs_node> TYPE zif_ayaml_types=>ty_s_node.

    IF iv_path = `/`.
      READ TABLE it_nodes WITH KEY path_key COMPONENTS path = `/` ASSIGNING <fs_node>.
      IF sy-subrc = 0 AND <fs_node>-index > 0.
        rv_yes = abap_true.
      ELSE.
        rv_yes = abap_false.
      ENDIF.
      RETURN.
    ENDIF.

    lv_trim = iv_path.
    lv_len = strlen( lv_trim ).
    IF lv_len > 1 AND substring( val = lv_trim
                                 off = lv_len - 1
                                 len = 1 ) = `/`.
      lv_trim = substring( val = lv_trim
                           len = lv_len - 1 ).
    ENDIF.
    split_path( EXPORTING iv_path = lv_trim
                IMPORTING ev_path = lv_parent
                          ev_name = lv_name ).
    READ TABLE it_nodes WITH KEY path = lv_parent
                                 name = lv_name ASSIGNING <fs_node>.
    IF sy-subrc = 0.
      rv_yes = boolc( <fs_node>-type = zif_ayaml_types=>cs_type-sequence ).
    ELSE.
      rv_yes = abap_false.
    ENDIF.
  ENDMETHOD.

  METHOD escape_text.
    rv_escaped = iv_value.
    REPLACE ALL OCCURRENCES OF `\` IN rv_escaped WITH `\\`.
    REPLACE ALL OCCURRENCES OF `"` IN rv_escaped WITH `\"`.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN rv_escaped WITH `\t`.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN rv_escaped WITH `\n`.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN rv_escaped WITH `\r`.
  ENDMETHOD.

  METHOD unescape_text.
    rv_value = iv_value.
    REPLACE ALL OCCURRENCES OF `\"` IN rv_value WITH `"`.
    REPLACE ALL OCCURRENCES OF `\\` IN rv_value WITH `\`.
    REPLACE ALL OCCURRENCES OF `\n` IN rv_value WITH cl_abap_char_utilities=>newline.
    REPLACE ALL OCCURRENCES OF `\t` IN rv_value WITH cl_abap_char_utilities=>horizontal_tab.
    REPLACE ALL OCCURRENCES OF `\r` IN rv_value WITH cl_abap_char_utilities=>cr_lf.
  ENDMETHOD.

  METHOD strip_quotes.
    DATA lv_len   TYPE i.
    DATA lv_first TYPE string.
    DATA lv_last  TYPE string.
    DATA lv_off   TYPE i.

    lv_len = strlen( iv_value ).
    IF lv_len >= 2.
      lv_first = substring( val = iv_value
                            off = 0
                            len = 1 ).
      lv_off = lv_len - 1.
      lv_last = substring( val = iv_value
                           off = lv_off
                           len = 1 ).
      IF lv_first = `"` AND lv_last = `"`.
        rv_value = substring( val = iv_value
                              off = 1
                              len = lv_len - 2 ).
        RETURN.
      ENDIF.
      IF lv_first = `'` AND lv_last = `'`.
        rv_value = substring( val = iv_value
                              off = 1
                              len = lv_len - 2 ).
        REPLACE ALL OCCURRENCES OF `''` IN rv_value WITH `'`.
        RETURN.
      ENDIF.
    ENDIF.
    rv_value = iv_value.
  ENDMETHOD.

  METHOD is_plain_scalar.
    DATA lv_len   TYPE i.
    DATA lv_first TYPE string.
    DATA lv_last  TYPE string.
    DATA lv_off   TYPE i.
    DATA lv_lower TYPE string.

    IF iv_value IS INITIAL.
      rv_plain = abap_true.
      RETURN.
    ENDIF.
    IF    iv_value CS `"` OR iv_value CS `\`
       OR iv_value CS cl_abap_char_utilities=>horizontal_tab
       OR iv_value CS cl_abap_char_utilities=>newline
       OR iv_value CS cl_abap_char_utilities=>cr_lf
       OR iv_value CS `:` OR iv_value CS `#`.
      rv_plain = abap_false.
      RETURN.
    ENDIF.
    lv_len = strlen( iv_value ).
    IF lv_len > 0.
      lv_first = substring( val = iv_value
                            off = 0
                            len = 1 ).
      lv_off = lv_len - 1.
      lv_last = substring( val = iv_value
                           off = lv_off
                           len = 1 ).
      IF lv_first = ` ` OR lv_last = ` `.
        rv_plain = abap_false.
        RETURN.
      ENDIF.
    ENDIF.

    lv_lower = to_lower( iv_value ).
    IF lv_lower = `true` OR lv_lower = `false` OR lv_lower = `null` OR lv_lower = `~`.
      rv_plain = abap_false.
      RETURN.
    ENDIF.
    rv_plain = abap_true.
  ENDMETHOD.

  METHOD detect_type.
    DATA lo_descr TYPE REF TO cl_abap_typedescr.
    DATA lo_elem  TYPE REF TO cl_abap_elemdescr.

    TRY.
        lo_descr = cl_abap_typedescr=>describe_by_data( iv_val ).
      CATCH cx_root.
        rv_type = zif_ayaml_types=>cs_type-string.
        RETURN.
    ENDTRY.
    CASE lo_descr->type_kind.
      WHEN cl_abap_typedescr=>typekind_int
          OR cl_abap_typedescr=>typekind_int1
          OR cl_abap_typedescr=>typekind_int2
          OR cl_abap_typedescr=>typekind_int8
          OR cl_abap_typedescr=>typekind_packed
          OR cl_abap_typedescr=>typekind_float
          OR cl_abap_typedescr=>typekind_decfloat
          OR cl_abap_typedescr=>typekind_decfloat16
          OR cl_abap_typedescr=>typekind_decfloat34.
        rv_type = zif_ayaml_types=>cs_type-number.
        RETURN.
      WHEN cl_abap_typedescr=>typekind_date.
        rv_type = zif_ayaml_types=>cs_type-date.
        RETURN.
      WHEN cl_abap_typedescr=>typekind_char
          OR cl_abap_typedescr=>typekind_string
          OR cl_abap_typedescr=>typekind_clike
          OR cl_abap_typedescr=>typekind_csequence.
        TRY.
            lo_elem ?= lo_descr.
            IF     lo_elem->output_length = 1
               AND (    lo_descr->absolute_name CS `ABAP_BOOL`
                     OR lo_descr->absolute_name CS `ABAP_BOOLEAN` ).
              rv_type = zif_ayaml_types=>cs_type-boolean.
              RETURN.
            ENDIF.
          CATCH cx_root.
        ENDTRY.
        rv_type = zif_ayaml_types=>cs_type-string.
        RETURN.
      WHEN OTHERS.
        IF lo_descr->kind = cl_abap_typedescr=>kind_table.
          rv_type = zif_ayaml_types=>cs_type-sequence.
          RETURN.
        ENDIF.
        IF lo_descr->kind = cl_abap_typedescr=>kind_struct.
          rv_type = zif_ayaml_types=>cs_type-mapping.
          RETURN.
        ENDIF.
        rv_type = zif_ayaml_types=>cs_type-string.
    ENDCASE.
  ENDMETHOD.

  METHOD to_string.
    DATA lv_tmp  TYPE string.
    DATA lv_date TYPE d.

    CASE iv_type.
      WHEN zif_ayaml_types=>cs_type-number.
        lv_tmp = |{ iv_val }|.
        rv_str = condense( lv_tmp ).
      WHEN zif_ayaml_types=>cs_type-boolean.
        lv_tmp = |{ iv_val }|.
        IF lv_tmp = `X` OR lv_tmp = `x` OR lv_tmp = `1` OR lv_tmp = `true` OR lv_tmp = `TRUE`.
          rv_str = `true`.
        ELSE.
          rv_str = `false`.
        ENDIF.
      WHEN zif_ayaml_types=>cs_type-date.
        TRY.
            lv_date = iv_val.
            rv_str = format_date( lv_date ).
          CATCH cx_root.
            rv_str = |{ iv_val }|.
        ENDTRY.
      WHEN zif_ayaml_types=>cs_type-null.
        rv_str = `null`.
      WHEN zif_ayaml_types=>cs_type-mapping OR zif_ayaml_types=>cs_type-sequence.
        rv_str = ``.
      WHEN OTHERS.
        TRY.
            rv_str = |{ iv_val }|.
          CATCH cx_root.
            rv_str = ``.
        ENDTRY.
    ENDCASE.
  ENDMETHOD.

  METHOD format_date.
    DATA lv_year  TYPE string.
    DATA lv_month TYPE string.
    DATA lv_day   TYPE string.

    lv_year  = iv_date(4).
    lv_month = iv_date+4(2).
    lv_day   = iv_date+6(2).
    rv_str   = |{ lv_year }-{ lv_month }-{ lv_day }|.
  ENDMETHOD.

  METHOD format_timestamp.
    DATA lv_date TYPE d.
    DATA lv_time TYPE t.

    CONVERT TIME STAMP iv_timestamp TIME ZONE sy-zonlo INTO DATE lv_date TIME lv_time.
    rv_str = |{ format_date( lv_date ) }T{ lv_time(2) }:{ lv_time+2(2) }:{ lv_time+4(2) }Z|.
  ENDMETHOD.

  METHOD parse_date.
    DATA lv_y TYPE c LENGTH 4.
    DATA lv_m TYPE c LENGTH 2.
    DATA lv_d TYPE c LENGTH 2.

    IF iv_value IS INITIAL.
      CLEAR rv_date.
      RETURN.
    ENDIF.
    IF strlen( iv_value ) = 8 AND iv_value CO '0123456789'.
      rv_date = iv_value.
      RETURN.
    ENDIF.
    FIND FIRST OCCURRENCE OF REGEX '^(\d{4})-(\d{2})-(\d{2})(T|$)' IN iv_value
         SUBMATCHES lv_y lv_m lv_d.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_ayaml_error
        EXPORTING iv_msg = `Unexpected date format`.
    ENDIF.
    CONCATENATE lv_y lv_m lv_d INTO rv_date.
  ENDMETHOD.

  METHOD parse_timestamp.
    CONSTANTS lc_utc             TYPE c LENGTH 6 VALUE 'UTC'.
    CONSTANTS lc_regex_ts_utc    TYPE string     VALUE `^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(\.\d+)?Z?$`.
    CONSTANTS lc_regex_ts_offset TYPE string
                                 VALUE `^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(\.\d+)?([+-]\d{2}:\d{2})$`.

    DATA lv_y            TYPE c LENGTH 4.
    DATA lv_m            TYPE c LENGTH 2.
    DATA lv_d            TYPE c LENGTH 2.
    DATA lv_h            TYPE c LENGTH 2.
    DATA lv_min          TYPE c LENGTH 2.
    DATA lv_s            TYPE c LENGTH 2.
    DATA lv_frac         TYPE string.
    DATA lv_offset       TYPE string.
    DATA lv_date         TYPE d.
    DATA lv_time         TYPE t.
    DATA lv_timestamp    TYPE timestamp.
    DATA lv_sign         TYPE string.
    DATA lv_off_h        TYPE string.
    DATA lv_off_m        TYPE string.
    DATA lv_seconds_conv TYPE i.
    DATA lv_h_i          TYPE i.
    DATA lv_m_i          TYPE i.

    IF iv_value IS INITIAL.
      CLEAR rv_timestamp.
      RETURN.
    ENDIF.

    FIND FIRST OCCURRENCE OF REGEX lc_regex_ts_utc IN iv_value
         SUBMATCHES lv_y lv_m lv_d lv_h lv_min lv_s lv_frac.
    IF sy-subrc = 0.
      CONCATENATE lv_y lv_m lv_d INTO lv_date.
      CONCATENATE lv_h lv_min lv_s INTO lv_time.
      CONVERT DATE lv_date TIME lv_time INTO TIME STAMP lv_timestamp TIME ZONE lc_utc.
      IF lv_frac IS NOT INITIAL.
        lv_frac = |0{ lv_frac }|.
        lv_timestamp = lv_timestamp + lv_frac.
      ENDIF.
      rv_timestamp = lv_timestamp.
      RETURN.
    ENDIF.

    FIND FIRST OCCURRENCE OF REGEX lc_regex_ts_offset IN iv_value
         SUBMATCHES lv_y lv_m lv_d lv_h lv_min lv_s lv_frac lv_offset.
    IF sy-subrc = 0.
      CONCATENATE lv_y lv_m lv_d INTO lv_date.
      CONCATENATE lv_h lv_min lv_s INTO lv_time.
      CONVERT DATE lv_date TIME lv_time INTO TIME STAMP lv_timestamp TIME ZONE lc_utc.
      IF lv_frac IS NOT INITIAL.
        lv_frac = |0{ lv_frac }|.
        lv_timestamp = lv_timestamp + lv_frac.
      ENDIF.

      lv_sign = substring( val = lv_offset
                           off = 0
                           len = 1 ).
      lv_off_h = substring( val = lv_offset
                            off = 1
                            len = 2 ).
      lv_off_m = substring( val = lv_offset
                            off = 4
                            len = 2 ).
      lv_h_i = lv_off_h.
      lv_m_i = lv_off_m.
      lv_seconds_conv = ( lv_h_i * 3600 ) + ( lv_m_i * 60 ).
      TRY.
          CASE lv_sign.
            WHEN '-'.
              lv_timestamp = cl_abap_tstmp=>add( tstmp = lv_timestamp
                                                 secs  = lv_seconds_conv ).
            WHEN '+'.
              lv_timestamp = cl_abap_tstmp=>subtractsecs( tstmp = lv_timestamp
                                                          secs  = lv_seconds_conv ).
          ENDCASE.
        CATCH cx_parameter_invalid_range
              cx_parameter_invalid_type.
          RAISE EXCEPTION TYPE zcx_ayaml_error
            EXPORTING iv_msg = `Unexpected timestamp format`.
      ENDTRY.
      rv_timestamp = lv_timestamp.
      RETURN.
    ENDIF.

    RAISE EXCEPTION TYPE zcx_ayaml_error
      EXPORTING iv_msg = `Unexpected timestamp format`.
  ENDMETHOD.

  METHOD detect_yaml_scalar.
    DATA lv_tmp   TYPE string.
    DATA lv_lower TYPE string.
    DATA lv_first TYPE string.
    DATA lv_last  TYPE string.
    DATA lv_len   TYPE i.
    DATA lv_off   TYPE i.

    lv_tmp = iv_raw.
    lv_lower = to_lower( iv_raw ).
    IF strlen( lv_tmp ) >= 2.
      lv_first = substring( val = lv_tmp
                            off = 0
                            len = 1 ).
      lv_len = strlen( lv_tmp ).
      lv_off = lv_len - 1.
      lv_last = substring( val = lv_tmp
                           off = lv_off
                           len = 1 ).
      IF lv_first = `"` AND lv_last = `"`.
        ev_type = zif_ayaml_types=>cs_type-string.
        ev_value = strip_quotes( lv_tmp ).
        ev_value = unescape_text( ev_value ).
        RETURN.
      ENDIF.
      IF lv_first = `'` AND lv_last = `'`.
        ev_type = zif_ayaml_types=>cs_type-string.
        ev_value = strip_quotes( lv_tmp ).
        RETURN.
      ENDIF.
    ENDIF.

    IF lv_lower = `null` OR lv_lower = `~`.
      ev_type = zif_ayaml_types=>cs_type-null.
      ev_value = `null`.
      RETURN.
    ENDIF.

    IF lv_lower = `true` OR lv_lower = `false`.
      ev_type = zif_ayaml_types=>cs_type-boolean.
      ev_value = lv_lower.
      RETURN.
    ENDIF.

    FIND FIRST OCCURRENCE OF REGEX '^\d{4}-\d{2}-\d{2}$' IN lv_tmp.
    IF sy-subrc = 0.
      ev_type = zif_ayaml_types=>cs_type-date.
      ev_value = lv_tmp.
      RETURN.
    ENDIF.

    FIND FIRST OCCURRENCE OF REGEX '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z?$' IN lv_tmp.
    IF sy-subrc = 0.
      ev_type = zif_ayaml_types=>cs_type-string.
      ev_value = lv_tmp.
      RETURN.
    ENDIF.

    IF lv_tmp CO `0123456789.-+eE`.
      ev_type = zif_ayaml_types=>cs_type-number.
      ev_value = lv_tmp.
      RETURN.
    ENDIF.

    ev_type = zif_ayaml_types=>cs_type-string.
    ev_value = lv_tmp.
  ENDMETHOD.

  METHOD to_camel_case.
    DATA lt_parts      TYPE string_table.
    DATA lv_first      TYPE abap_bool.
    DATA lv_head       TYPE string.
    DATA lv_tail       TYPE string.
    DATA lv_len        TYPE i.
    DATA lv_first_char TYPE string.
    DATA lv_upper      TYPE string.
    DATA lv_sub        TYPE string.
    FIELD-SYMBOLS <fs_part> TYPE string.

    IF iv_name CS `_`.
      SPLIT iv_name AT `_` INTO TABLE lt_parts.
      lv_first = abap_true.
      LOOP AT lt_parts ASSIGNING <fs_part>.
        IF <fs_part> IS INITIAL.
          CONTINUE.
        ENDIF.
        IF lv_first = abap_true.
          rv_name = to_lower( <fs_part> ).
          lv_first = abap_false.
        ELSE.
          lv_sub = substring( val = <fs_part>
                              off = 0
                              len = 1 ).
          lv_head = to_upper( lv_sub ).
          lv_tail = to_lower( substring( val = <fs_part>
                                         off = 1 ) ).
          rv_name = |{ rv_name }{ lv_head }{ lv_tail }|.
        ENDIF.
      ENDLOOP.
    ELSE.
      lv_len = strlen( iv_name ).
      IF lv_len > 0.
        lv_upper = to_upper( iv_name ).
        IF iv_name = lv_upper.
          rv_name = to_lower( iv_name ).
        ELSE.
          lv_sub = substring( val = iv_name
                              off = 0
                              len = 1 ).
          lv_first_char = to_lower( lv_sub ).
          lv_tail = substring( val = iv_name
                               off = 1 ).
          rv_name = |{ lv_first_char }{ lv_tail }|.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD to_snake_case.
    DATA lv_len   TYPE i.
    DATA lv_idx   TYPE i.
    DATA lv_char  TYPE string.
    DATA lv_upper TYPE string.

    IF iv_name CS `_`.
      rv_name = to_lower( iv_name ).
      RETURN.
    ENDIF.

    lv_len = strlen( iv_name ).
    IF lv_len = 0.
      RETURN.
    ENDIF.

    lv_upper = to_upper( iv_name ).
    IF iv_name = lv_upper.
      rv_name = to_lower( iv_name ).
      RETURN.
    ENDIF.

    DO lv_len TIMES.
      lv_idx = sy-index - 1.
      lv_char = substring( val = iv_name
                           off = lv_idx
                           len = 1 ).
      IF lv_char >= `A` AND lv_char <= `Z`.
        IF lv_idx > 0.
          rv_name = |{ rv_name }_{ to_lower( lv_char ) }|.
        ELSE.
          rv_name = to_lower( lv_char ).
        ENDIF.
      ELSE.
        rv_name = |{ rv_name }{ lv_char }|.
      ENDIF.
    ENDDO.
  ENDMETHOD.

  METHOD format_field_name.
    CASE iv_format.
      WHEN zif_ayaml_types=>cs_format-camel_case.
        rv_name = to_camel_case( iv_name ).
      WHEN zif_ayaml_types=>cs_format-snake_case.
        rv_name = to_snake_case( iv_name ).
      WHEN zif_ayaml_types=>cs_format-upper_case.
        rv_name = to_upper( iv_name ).
      WHEN zif_ayaml_types=>cs_format-lower_case OR zif_ayaml_types=>cs_format-default.
        rv_name = to_lower( iv_name ).
      WHEN OTHERS.
        rv_name = to_lower( iv_name ).
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
