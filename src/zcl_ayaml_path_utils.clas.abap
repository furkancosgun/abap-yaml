CLASS zcl_ayaml_path_utils DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS normalize
      IMPORTING iv_path        TYPE string
      RETURNING VALUE(rv_norm) TYPE string.

    CLASS-METHODS split
      IMPORTING iv_path TYPE string
      EXPORTING ev_path TYPE string
                ev_name TYPE string.

    CLASS-METHODS get_parent
      IMPORTING iv_path          TYPE string
      RETURNING VALUE(rv_parent) TYPE string.

    CLASS-METHODS build_path
      IMPORTING iv_parent      TYPE string
                iv_name        TYPE string
      RETURNING VALUE(rv_path) TYPE string.

    CLASS-METHODS append
      IMPORTING iv_base        TYPE string
                iv_name        TYPE string
      RETURNING VALUE(rv_path) TYPE string.

    CLASS-METHODS is_sequence_path
      IMPORTING it_nodes      TYPE zif_ayaml_types=>ty_t_nodes
                iv_path       TYPE string
      RETURNING VALUE(rv_yes) TYPE abap_bool.

ENDCLASS.


CLASS zcl_ayaml_path_utils IMPLEMENTATION.
  METHOD normalize.
    DATA lv_len  TYPE i.
    DATA lv_last TYPE c LENGTH 1.
    DATA lv_off  TYPE i.

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
      lv_len -= 1.
      rv_norm = substring( val = rv_norm
                           len = lv_len ).
    ENDWHILE.
  ENDMETHOD.

  METHOD split.
    DATA lv_norm   TYPE string.
    DATA lv_len    TYPE i.
    DATA lv_last   TYPE i.
    DATA lv_offset TYPE i.
    DATA lv_found  TYPE abap_bool.

    lv_norm = normalize( iv_path ).
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

  METHOD get_parent.
    DATA lv_parent TYPE string.
    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA lv_name   TYPE string.

    split( EXPORTING iv_path = iv_path
           IMPORTING ev_path = lv_parent
                     ev_name = lv_name ).
    rv_parent = lv_parent.
  ENDMETHOD.

  METHOD build_path.
    DATA lv_parent_norm TYPE string.

    lv_parent_norm = normalize( iv_parent ).
    IF lv_parent_norm = `/`.
      rv_path = |/{ iv_name }|.
    ELSE.
      rv_path = |{ lv_parent_norm }/{ iv_name }|.
    ENDIF.
  ENDMETHOD.

  METHOD append.
    DATA lv_base_norm TYPE string.

    lv_base_norm = normalize( iv_base ).
    IF lv_base_norm = `/`.
      rv_path = |/{ iv_name }/|.
    ELSE.
      rv_path = |{ lv_base_norm }/{ iv_name }/|.
    ENDIF.
  ENDMETHOD.

  METHOD is_sequence_path.
    DATA lv_trim   TYPE string.
    DATA lv_parent TYPE string.
    DATA lv_name   TYPE string.
    DATA ls_node   TYPE zif_ayaml_types=>ty_s_node.

    IF iv_path = `/`.
      rv_yes = abap_false.
      RETURN.
    ENDIF.
    lv_trim = iv_path.
    DATA(lv_len) = strlen( lv_trim ).
    IF lv_len > 1 AND substring( val = lv_trim
                                 off = lv_len - 1
                                 len = 1 ) = `/`.
      lv_trim = substring( val = lv_trim
                           len = lv_len - 1 ).
    ENDIF.
    split( EXPORTING iv_path = lv_trim
           IMPORTING ev_path = lv_parent
                     ev_name = lv_name ).
    READ TABLE it_nodes WITH KEY path = lv_parent
                                 name = lv_name INTO ls_node.
    rv_yes = xsdbool( sy-subrc = 0 AND ls_node-type = zif_ayaml_types=>cs_type-sequence ).
  ENDMETHOD.
ENDCLASS.
