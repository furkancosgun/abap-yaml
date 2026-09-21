CLASS zcl_ayaml_serializer DEFINITION PUBLIC FINAL CREATE PUBLIC.

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

    CLASS-METHODS is_sequence_path
      IMPORTING it_nodes      TYPE zif_ayaml_types=>ty_t_nodes
                iv_path       TYPE string
      RETURNING VALUE(rv_yes) TYPE abap_bool.

    CLASS-METHODS format_scalar
      IMPORTING is_node       TYPE zif_ayaml_types=>ty_s_node
      RETURNING VALUE(rv_out) TYPE string.

ENDCLASS.


CLASS zcl_ayaml_serializer IMPLEMENTATION.
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

  METHOD is_sequence_path.
    rv_yes = zcl_ayaml_path_utils=>is_sequence_path( it_nodes = it_nodes
                                                     iv_path  = iv_path ).
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
        IF zcl_ayaml_string_utils=>is_plain( is_node-value ) = abap_true.
          rv_out = is_node-value.
        ELSE.
          rv_out = |"{ zcl_ayaml_string_utils=>escape_text( is_node-value ) }"|.
        ENDIF.
    ENDCASE.
  ENDMETHOD.

  METHOD build_yaml.
    DATA lt_children   TYPE zif_ayaml_types=>ty_t_nodes.
    DATA ls_node       TYPE zif_ayaml_types=>ty_s_node.
    DATA lv_indent     TYPE string.
    DATA lv_line       TYPE string.
    DATA lv_child_yaml TYPE string.
    DATA lv_escaped    TYPE string.
    DATA lv_is_seq     TYPE abap_bool.
    FIELD-SYMBOLS <ls_child> TYPE zif_ayaml_types=>ty_s_node.

    LOOP AT it_nodes INTO ls_node USING KEY path_key WHERE path = iv_path.
      INSERT ls_node INTO TABLE lt_children.
    ENDLOOP.

    SORT lt_children BY order.

    lv_is_seq = is_sequence_path( it_nodes = it_nodes
                                  iv_path  = iv_path ).

    LOOP AT lt_children ASSIGNING <ls_child>.
      CLEAR lv_indent.
      DO iv_indent TIMES.
        lv_indent = |{ lv_indent }  |.
      ENDDO.

      CASE lv_is_seq.
        WHEN abap_true.
          CASE <ls_child>-type.
            WHEN zif_ayaml_types=>cs_type-mapping.
              lv_child_yaml = build_yaml( it_nodes  = it_nodes
                                          iv_path   = |{ iv_path }{ <ls_child>-name }/|
                                          iv_indent = iv_indent + 1 ).
              IF lv_child_yaml IS INITIAL.
                lv_line = |{ lv_indent }- { <ls_child>-name }:|.
                rv_yaml = rv_yaml && lv_line && cl_abap_char_utilities=>newline.
              ELSE.
                DATA(lv_first_line) = substring( val = lv_child_yaml
                                                 off = ( iv_indent + 1 ) * 2
                                                 len = strlen( lv_child_yaml ) - ( iv_indent + 1 ) * 2 ).
                rv_yaml = |{ rv_yaml }{ lv_indent }- { lv_first_line }|.
                DATA(lv_rest) = substring( val = lv_child_yaml
                                           off = ( iv_indent + 1 ) * 2 + strlen( lv_first_line ) ).
                IF lv_rest IS NOT INITIAL.
                  rv_yaml = rv_yaml && lv_rest.
                ENDIF.
              ENDIF.
            WHEN zif_ayaml_types=>cs_type-sequence.
              lv_line = |{ lv_indent }-|.
              lv_child_yaml = build_yaml( it_nodes  = it_nodes
                                          iv_path   = |{ iv_path }{ <ls_child>-name }/|
                                          iv_indent = iv_indent + 1 ).
              rv_yaml = rv_yaml && lv_line && cl_abap_char_utilities=>newline && lv_child_yaml.
            WHEN OTHERS.
              lv_escaped = format_scalar( <ls_child> ).
              lv_line = |{ lv_indent }- { lv_escaped }|.
              rv_yaml = rv_yaml && lv_line && cl_abap_char_utilities=>newline.
          ENDCASE.
        WHEN OTHERS.
          CASE <ls_child>-type.
            WHEN zif_ayaml_types=>cs_type-mapping.
              lv_line = |{ lv_indent }{ <ls_child>-name }:|.
              lv_child_yaml = build_yaml( it_nodes  = it_nodes
                                          iv_path   = |{ iv_path }{ <ls_child>-name }/|
                                          iv_indent = iv_indent + 1 ).
              IF lv_child_yaml IS INITIAL.
                rv_yaml = rv_yaml && lv_line && cl_abap_char_utilities=>newline.
              ELSE.
                rv_yaml = rv_yaml && lv_line && cl_abap_char_utilities=>newline && lv_child_yaml.
              ENDIF.
            WHEN zif_ayaml_types=>cs_type-sequence.
              lv_line = |{ lv_indent }{ <ls_child>-name }:|.
              lv_child_yaml = build_yaml( it_nodes  = it_nodes
                                          iv_path   = |{ iv_path }{ <ls_child>-name }/|
                                          iv_indent = iv_indent + 1 ).
              IF lv_child_yaml IS INITIAL.
                rv_yaml = |{ rv_yaml }{ lv_line } []{ cl_abap_char_utilities=>newline }|.
              ELSE.
                rv_yaml = rv_yaml && lv_line && cl_abap_char_utilities=>newline && lv_child_yaml.
              ENDIF.
            WHEN OTHERS.
              lv_escaped = format_scalar( <ls_child> ).
              lv_line = |{ lv_indent }{ <ls_child>-name }: { lv_escaped }|.
              rv_yaml = rv_yaml && lv_line && cl_abap_char_utilities=>newline.
          ENDCASE.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
