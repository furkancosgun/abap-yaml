CLASS zcl_ayaml_string_utils DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS escape_text
      IMPORTING iv_value          TYPE string
      RETURNING VALUE(rv_escaped) TYPE string.

    CLASS-METHODS unescape
      IMPORTING iv_value        TYPE string
      RETURNING VALUE(rv_value) TYPE string.

    CLASS-METHODS strip_quotes
      IMPORTING iv_value        TYPE string
      RETURNING VALUE(rv_value) TYPE string.

    CLASS-METHODS is_plain
      IMPORTING iv_value        TYPE string
      RETURNING VALUE(rv_plain) TYPE abap_bool.

ENDCLASS.


CLASS zcl_ayaml_string_utils IMPLEMENTATION.
  METHOD escape_text.
    rv_escaped = iv_value.
    REPLACE ALL OCCURRENCES OF `\` IN rv_escaped WITH `\\`.
    REPLACE ALL OCCURRENCES OF `"` IN rv_escaped WITH `\"`.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN rv_escaped WITH `\t`.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN rv_escaped WITH `\n`.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN rv_escaped WITH `\r`.
  ENDMETHOD.

  METHOD unescape.
    rv_value = iv_value.
    REPLACE ALL OCCURRENCES OF `\"` IN rv_value WITH `"`.
    REPLACE ALL OCCURRENCES OF `\\` IN rv_value WITH `\`.
    REPLACE ALL OCCURRENCES OF `\n` IN rv_value WITH cl_abap_char_utilities=>newline.
    REPLACE ALL OCCURRENCES OF `\t` IN rv_value WITH cl_abap_char_utilities=>horizontal_tab.
    REPLACE ALL OCCURRENCES OF `\r` IN rv_value WITH cl_abap_char_utilities=>cr_lf.
  ENDMETHOD.

  METHOD strip_quotes.
    DATA lv_len   TYPE i.
    DATA lv_off   TYPE i.
    DATA lv_first TYPE c LENGTH 1.
    DATA lv_last  TYPE c LENGTH 1.

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

  METHOD is_plain.
    DATA lv_len   TYPE i.
    DATA lv_first TYPE c LENGTH 1.
    DATA lv_last  TYPE c LENGTH 1.
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
      IF lv_first = ' ' OR lv_last = ' '.
        rv_plain = abap_false.
        RETURN.
      ENDIF.
    ENDIF.

    lv_lower = iv_value.
    lv_lower = to_lower( lv_lower ).
    IF lv_lower = `true` OR lv_lower = `false` OR lv_lower = `null` OR lv_lower = `~`.
      rv_plain = abap_false.
      RETURN.
    ENDIF.
    rv_plain = abap_true.
  ENDMETHOD.
ENDCLASS.
