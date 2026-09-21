CLASS zcl_ayaml DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ayaml_reader.
    INTERFACES zif_ayaml_writer.
    INTERFACES zif_ayaml.

    ALIASES is_empty FOR zif_ayaml_reader~is_empty.
    ALIASES exists FOR zif_ayaml_reader~exists.
    ALIASES get FOR zif_ayaml_reader~get.
    ALIASES get_string FOR zif_ayaml_reader~get_string.
    ALIASES get_integer FOR zif_ayaml_reader~get_integer.
    ALIASES get_number FOR zif_ayaml_reader~get_number.
    ALIASES get_boolean FOR zif_ayaml_reader~get_boolean.
    ALIASES get_date FOR zif_ayaml_reader~get_date.
    ALIASES get_timestamp FOR zif_ayaml_reader~get_timestamp.
    ALIASES get_node FOR zif_ayaml_reader~get_node.
    ALIASES get_node_type FOR zif_ayaml_reader~get_node_type.
    ALIASES get_keys FOR zif_ayaml_reader~get_keys.
    ALIASES members FOR zif_ayaml_reader~get_keys.
    ALIASES array_length FOR zif_ayaml_reader~array_length.
    ALIASES get_string_table FOR zif_ayaml_reader~get_string_table.
    ALIASES to_abap FOR zif_ayaml_reader~to_abap.
    ALIASES to_yaml FOR zif_ayaml_reader~to_yaml.
    ALIASES stringify FOR zif_ayaml_reader~to_yaml.
    ALIASES slice FOR zif_ayaml_reader~slice.

    ALIASES set FOR zif_ayaml_writer~set.
    ALIASES set_boolean FOR zif_ayaml_writer~set_boolean.
    ALIASES set_string FOR zif_ayaml_writer~set_string.
    ALIASES set_integer FOR zif_ayaml_writer~set_integer.
    ALIASES set_number FOR zif_ayaml_writer~set_number.
    ALIASES set_date FOR zif_ayaml_writer~set_date.
    ALIASES set_timestamp FOR zif_ayaml_writer~set_timestamp.
    ALIASES set_null FOR zif_ayaml_writer~set_null.
    ALIASES delete FOR zif_ayaml_writer~delete.
    ALIASES clear FOR zif_ayaml_writer~clear.
    ALIASES ensure_sequence FOR zif_ayaml_writer~ensure_sequence.
    ALIASES touch_array FOR zif_ayaml_writer~ensure_sequence.
    ALIASES append_to_sequence FOR zif_ayaml_writer~append_to_sequence.
    ALIASES push FOR zif_ayaml_writer~append_to_sequence.

    CLASS-METHODS create_empty
      RETURNING VALUE(ri_ayaml) TYPE REF TO zif_ayaml.

    CLASS-METHODS parse
      IMPORTING iv_yaml         TYPE string
      RETURNING VALUE(ri_ayaml) TYPE REF TO zif_ayaml
      RAISING   zcx_ayaml_error.

    METHODS constructor
      IMPORTING it_nodes TYPE zif_ayaml_types=>ty_t_nodes OPTIONAL.

  PRIVATE SECTION.
    DATA mt_nodes TYPE zif_ayaml_types=>ty_t_nodes.

    METHODS ensure_path_exists
      IMPORTING iv_full_path TYPE string.

    METHODS set_recursive
      IMPORTING iv_path TYPE string
                iv_val  TYPE any
      RAISING   zcx_ayaml_error.

    METHODS get_next_index
      IMPORTING iv_path         TYPE string
      RETURNING VALUE(rv_index) TYPE i.

    METHODS set_typed
      IMPORTING iv_path        TYPE string
                iv_val         TYPE any
                iv_type        TYPE zif_ayaml_types=>ty_node_type
      RETURNING VALUE(ri_self) TYPE REF TO zif_ayaml_writer
      RAISING   zcx_ayaml_error.

    METHODS get_node_internal
      IMPORTING iv_path        TYPE string
      RETURNING VALUE(rs_node) TYPE zif_ayaml_types=>ty_s_node.

    METHODS get_value_internal
      IMPORTING iv_path         TYPE string
      RETURNING VALUE(rv_value) TYPE string.

    METHODS convert_to_integer
      IMPORTING iv_value      TYPE string
      RETURNING VALUE(rv_int) TYPE i.

    METHODS convert_to_number
      IMPORTING iv_value      TYPE string
      RETURNING VALUE(rv_num) TYPE f.

ENDCLASS.


CLASS zcl_ayaml IMPLEMENTATION.

  METHOD constructor.
    mt_nodes = it_nodes.
  ENDMETHOD.

  METHOD create_empty.
    ri_ayaml = NEW zcl_ayaml( ).
  ENDMETHOD.

  METHOD parse.
    DATA lo_scanner TYPE REF TO lcl_scanner.
    DATA lt_tokens  TYPE zif_ayaml_types=>ty_t_tokens.
    DATA lo_parser  TYPE REF TO lcl_ast_parser.
    DATA lo_ast     TYPE REF TO lcl_ast_node.
    DATA lt_nodes   TYPE zif_ayaml_types=>ty_t_nodes.

    IF iv_yaml IS NOT INITIAL.
      lo_scanner = NEW #( iv_yaml ).
      lt_tokens  = lo_scanner->scan( ).
      lo_parser  = NEW #( lt_tokens ).
      lo_ast     = lo_parser->parse( ).
      lt_nodes   = lcl_ast_to_nodes=>convert( lo_ast ).
    ENDIF.

    ri_ayaml = NEW zcl_ayaml( it_nodes = lt_nodes ).
  ENDMETHOD.

  METHOD set_typed.
    zif_ayaml_writer~set(
      iv_path         = iv_path
      iv_val          = iv_val
      iv_node_type    = iv_type
      iv_ignore_empty = abap_false ).
    ri_self = me.
  ENDMETHOD.

  METHOD ensure_path_exists.
    DATA lt_parts      TYPE zif_ayaml_types=>ty_t_string.
    DATA lv_part       TYPE string.
    DATA lv_cum_parent TYPE string.
    DATA ls_node       TYPE zif_ayaml_types=>ty_s_node.
    DATA lv_order      TYPE i.
    DATA lv_clean      TYPE string.
    DATA lv_index      TYPE i.

    lv_clean = zcl_ayaml_utils=>normalize_path( iv_full_path ).
    SPLIT lv_clean AT `/` INTO TABLE lt_parts.
    lv_cum_parent = `/`.
    lv_order = lines( mt_nodes ) + 1.
    lv_index = 0.
    LOOP AT lt_parts INTO lv_part.
      lv_index += 1.
      IF lv_part IS INITIAL.
        CONTINUE.
      ENDIF.
      IF lv_index = lines( lt_parts ).
        EXIT.
      ENDIF.
      IF NOT line_exists( mt_nodes[ path = lv_cum_parent name = lv_part ] ).
        CLEAR ls_node.
        ls_node-path  = lv_cum_parent.
        ls_node-name  = lv_part.
        ls_node-type  = zif_ayaml_types=>cs_type-mapping.
        ls_node-value = ``.
        ls_node-index = 0.
        ls_node-order = lv_order.
        INSERT ls_node INTO TABLE mt_nodes.
        lv_order += 1.
      ENDIF.
      lv_cum_parent = |{ lv_cum_parent }{ lv_part }/|.
    ENDLOOP.
  ENDMETHOD.

  METHOD set_recursive.
    DATA lo_descr    TYPE REF TO cl_abap_typedescr.
    DATA lo_struct   TYPE REF TO cl_abap_structdescr.
    DATA lt_comps    TYPE abap_component_tab.
    DATA lv_comp_path TYPE string.
    FIELD-SYMBOLS <ls_comp>  TYPE abap_componentdescr.
    FIELD-SYMBOLS <lv_field> TYPE any.
    FIELD-SYMBOLS <lt_table> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <lv_line>  TYPE any.

    lo_descr = cl_abap_typedescr=>describe_by_data( iv_val ).
    CASE lo_descr->kind.
      WHEN cl_abap_typedescr=>kind_struct.
        lo_struct ?= lo_descr.
        lt_comps = lo_struct->get_components( ).
        LOOP AT lt_comps ASSIGNING <ls_comp>.
          ASSIGN COMPONENT <ls_comp>-name OF STRUCTURE iv_val TO <lv_field>.
          IF sy-subrc = 0.
            lv_comp_path = |{ iv_path }/{ to_lower( <ls_comp>-name ) }|.
            set_recursive( iv_path = lv_comp_path iv_val = <lv_field> ).
          ENDIF.
        ENDLOOP.
      WHEN cl_abap_typedescr=>kind_table.
        ASSIGN iv_val TO <lt_table>.
        IF sy-subrc = 0.
          zif_ayaml_writer~ensure_sequence( iv_path = iv_path iv_clear = abap_true ).
          LOOP AT <lt_table> ASSIGNING <lv_line>.
            zif_ayaml_writer~append_to_sequence( iv_path = iv_path iv_val = <lv_line> ).
          ENDLOOP.
        ENDIF.
      WHEN OTHERS.
        zif_ayaml_writer~set( iv_path = iv_path iv_val = iv_val ).
    ENDCASE.
  ENDMETHOD.

  METHOD get_next_index.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.
    DATA lv_max  TYPE i.

    lv_max = 0.
    LOOP AT mt_nodes INTO ls_node USING KEY path_key WHERE path = iv_path.
      IF ls_node-index > lv_max.
        lv_max = ls_node-index.
      ENDIF.
    ENDLOOP.
    rv_index = lv_max + 1.
  ENDMETHOD.

  METHOD get_node_internal.
    DATA lv_parent TYPE string.
    DATA lv_name   TYPE string.

    zcl_ayaml_utils=>split_path( EXPORTING iv_path = iv_path
                                 IMPORTING ev_path = lv_parent
                                           ev_name = lv_name ).
    READ TABLE mt_nodes WITH KEY path = lv_parent name = lv_name INTO rs_node.
    IF sy-subrc <> 0.
      CLEAR rs_node.
    ENDIF.
  ENDMETHOD.

  METHOD get_value_internal.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.

    ls_node = get_node_internal( iv_path ).
    IF ls_node-name IS INITIAL AND ls_node-path IS INITIAL.
      rv_value = ``.
      RETURN.
    ENDIF.
    IF ls_node-type = zif_ayaml_types=>cs_type-mapping OR ls_node-type = zif_ayaml_types=>cs_type-sequence.
      rv_value = ``.
    ELSE.
      rv_value = ls_node-value.
    ENDIF.
  ENDMETHOD.

  METHOD convert_to_integer.
    IF iv_value IS INITIAL.
      rv_int = 0.
      RETURN.
    ENDIF.
    TRY.
        rv_int = CONV i( iv_value ).
      CATCH cx_root.
        rv_int = 0.
    ENDTRY.
  ENDMETHOD.

  METHOD convert_to_number.
    IF iv_value IS INITIAL.
      rv_num = 0.
      RETURN.
    ENDIF.
    TRY.
        rv_num = CONV f( iv_value ).
      CATCH cx_root.
        rv_num = 0.
    ENDTRY.
  ENDMETHOD.

  METHOD zif_ayaml_reader~is_empty.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.

    IF mt_nodes IS INITIAL.
      rv_yes = abap_true.
      RETURN.
    ENDIF.
    IF lines( mt_nodes ) = 1.
      READ TABLE mt_nodes INDEX 1 INTO ls_node.
      IF sy-subrc = 0 AND ls_node-path = `/` AND ls_node-name IS INITIAL.
        rv_yes = abap_true.
        RETURN.
      ENDIF.
    ENDIF.
    rv_yes = abap_false.
  ENDMETHOD.

  METHOD zif_ayaml_reader~exists.
    DATA lv_norm TYPE string.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.

    lv_norm = zcl_ayaml_utils=>normalize_path( iv_path ).
    IF lv_norm = `/`.
      rv_yes = abap_true.
      RETURN.
    ENDIF.
    ls_node = get_node_internal( lv_norm ).
    rv_yes = xsdbool( NOT ( ls_node-path IS INITIAL AND ls_node-name IS INITIAL ) ).
  ENDMETHOD.

  METHOD zif_ayaml_reader~get.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.
    ls_node = get_node_internal( iv_path ).
    IF ls_node-path IS INITIAL AND ls_node-name IS INITIAL.
      IF iv_default IS SUPPLIED.
        rv_value = iv_default.
      ELSE.
        rv_value = ``.
      ENDIF.
      RETURN.
    ENDIF.
    IF ls_node-type = zif_ayaml_types=>cs_type-null AND iv_default IS SUPPLIED.
      rv_value = iv_default.
      RETURN.
    ENDIF.
    rv_value = get_value_internal( iv_path ).
  ENDMETHOD.

  METHOD zif_ayaml_reader~get_string.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.

    ls_node = get_node_internal( iv_path ).
    IF ls_node-path IS INITIAL AND ls_node-name IS INITIAL.
      IF iv_default IS SUPPLIED.
        rv_value = iv_default.
      ELSE.
        rv_value = ``.
      ENDIF.
      RETURN.
    ENDIF.
    IF ls_node-type = zif_ayaml_types=>cs_type-null.
      IF iv_default IS SUPPLIED.
        rv_value = iv_default.
      ELSE.
        rv_value = ``.
      ENDIF.
      RETURN.
    ENDIF.
    rv_value = ls_node-value.
  ENDMETHOD.

  METHOD zif_ayaml_reader~get_integer.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.

    ls_node = get_node_internal( iv_path ).
    IF ls_node-path IS INITIAL AND ls_node-name IS INITIAL.
      IF iv_default IS SUPPLIED.
        rv_value = iv_default.
      ELSE.
        rv_value = 0.
      ENDIF.
      RETURN.
    ENDIF.
    IF ls_node-type = zif_ayaml_types=>cs_type-null.
      IF iv_default IS SUPPLIED.
        rv_value = iv_default.
      ELSE.
        rv_value = 0.
      ENDIF.
      RETURN.
    ENDIF.
    rv_value = convert_to_integer( ls_node-value ).
  ENDMETHOD.

  METHOD zif_ayaml_reader~get_number.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.

    ls_node = get_node_internal( iv_path ).
    IF ls_node-path IS INITIAL AND ls_node-name IS INITIAL.
      IF iv_default IS SUPPLIED.
        rv_value = iv_default.
      ELSE.
        rv_value = 0.
      ENDIF.
      RETURN.
    ENDIF.
    IF ls_node-type = zif_ayaml_types=>cs_type-null.
      IF iv_default IS SUPPLIED.
        rv_value = iv_default.
      ELSE.
        rv_value = 0.
      ENDIF.
      RETURN.
    ENDIF.
    rv_value = convert_to_number( ls_node-value ).
  ENDMETHOD.

  METHOD zif_ayaml_reader~get_boolean.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.

    ls_node = get_node_internal( iv_path ).
    IF ls_node-path IS INITIAL AND ls_node-name IS INITIAL.
      IF iv_default IS SUPPLIED.
        rv_value = iv_default.
      ELSE.
        rv_value = abap_false.
      ENDIF.
      RETURN.
    ENDIF.
    IF ls_node-type = zif_ayaml_types=>cs_type-null.
      IF iv_default IS SUPPLIED.
        rv_value = iv_default.
      ELSE.
        rv_value = abap_false.
      ENDIF.
      RETURN.
    ENDIF.
    rv_value = xsdbool( ls_node-value = `true` OR ls_node-value = `X` OR ls_node-value = `1` ).
  ENDMETHOD.

  METHOD zif_ayaml_reader~get_date.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.

    ls_node = get_node_internal( iv_path ).
    IF ls_node-path IS INITIAL AND ls_node-name IS INITIAL.
      IF iv_default IS SUPPLIED.
        rv_date = iv_default.
      ENDIF.
      RETURN.
    ENDIF.
    IF ls_node-type = zif_ayaml_types=>cs_type-null.
      IF iv_default IS SUPPLIED.
        rv_date = iv_default.
      ENDIF.
      RETURN.
    ENDIF.
    TRY.
        rv_date = zcl_ayaml_utils=>parse_date( ls_node-value ).
      CATCH cx_root.
        IF iv_default IS SUPPLIED.
          rv_date = iv_default.
        ELSE.
          CLEAR rv_date.
        ENDIF.
    ENDTRY.
  ENDMETHOD.

  METHOD zif_ayaml_reader~get_timestamp.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.

    ls_node = get_node_internal( iv_path ).
    IF ls_node-path IS INITIAL AND ls_node-name IS INITIAL.
      IF iv_default IS SUPPLIED.
        rv_timestamp = iv_default.
      ENDIF.
      RETURN.
    ENDIF.
    IF ls_node-type = zif_ayaml_types=>cs_type-null.
      IF iv_default IS SUPPLIED.
        rv_timestamp = iv_default.
      ENDIF.
      RETURN.
    ENDIF.
    TRY.
        rv_timestamp = zcl_ayaml_utils=>parse_timestamp( ls_node-value ).
      CATCH cx_root.
        IF iv_default IS SUPPLIED.
          rv_timestamp = iv_default.
        ELSE.
          CLEAR rv_timestamp.
        ENDIF.
    ENDTRY.
  ENDMETHOD.

  METHOD zif_ayaml_reader~get_node.
    rs_node = get_node_internal( iv_path ).
  ENDMETHOD.

  METHOD zif_ayaml_reader~get_node_type.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.
    ls_node = get_node_internal( iv_path ).
    rv_node_type = ls_node-type.
  ENDMETHOD.

  METHOD zif_ayaml_reader~get_keys.
    DATA lv_norm TYPE string.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.

    lv_norm = zcl_ayaml_utils=>normalize_path( iv_path ).
    IF lv_norm <> `/`.
      lv_norm = |{ lv_norm }/|.
    ENDIF.
    LOOP AT mt_nodes INTO ls_node USING KEY path_key WHERE path = lv_norm.
      INSERT ls_node-name INTO TABLE rt_keys.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_ayaml_reader~array_length.
    DATA lv_norm TYPE string.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.

    lv_norm = zcl_ayaml_utils=>normalize_path( iv_path ).
    IF lv_norm <> `/`.
      lv_norm = |{ lv_norm }/|.
    ENDIF.
    LOOP AT mt_nodes INTO ls_node USING KEY path_key WHERE path = lv_norm.
      rv_length += 1.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_ayaml_reader~get_string_table.
    DATA lv_norm     TYPE string.
    DATA lt_children TYPE STANDARD TABLE OF zif_ayaml_types=>ty_s_node WITH EMPTY KEY.
    DATA ls_node     TYPE zif_ayaml_types=>ty_s_node.

    lv_norm = zcl_ayaml_utils=>normalize_path( iv_path ).
    IF lv_norm <> `/`.
      lv_norm = |{ lv_norm }/|.
    ENDIF.
    LOOP AT mt_nodes INTO ls_node USING KEY path_key WHERE path = lv_norm.
      INSERT ls_node INTO TABLE lt_children.
    ENDLOOP.
    SORT lt_children BY order.
    LOOP AT lt_children INTO ls_node.
      INSERT ls_node-value INTO TABLE rt_values.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_ayaml_reader~to_abap.
    lcl_deserializer=>deserialize(
      EXPORTING it_nodes = mt_nodes
      IMPORTING ev_data  = ev_data ).
  ENDMETHOD.

  METHOD zif_ayaml_reader~to_yaml.
    IF mt_nodes IS INITIAL.
      rv_yaml = ``.
      RETURN.
    ENDIF.
    rv_yaml = lcl_serializer=>stringify(
      it_nodes  = mt_nodes
      iv_indent = iv_indent ).
  ENDMETHOD.

  METHOD zif_ayaml_reader~slice.
    DATA lv_prefix   TYPE string.
    DATA lv_norm     TYPE string.
    DATA lt_sliced   TYPE zif_ayaml_types=>ty_t_nodes.
    DATA ls_node     TYPE zif_ayaml_types=>ty_s_node.
    DATA ls_new      TYPE zif_ayaml_types=>ty_s_node.
    DATA lv_pref_len TYPE i.
    DATA lv_sub_path TYPE string.

    lv_norm = zcl_ayaml_utils=>normalize_path( iv_path ).
    IF lv_norm = `/`.
      ri_fragment = me->zif_ayaml~clone( ).
      RETURN.
    ENDIF.
    lv_prefix = |{ lv_norm }/|.
    lv_pref_len = strlen( lv_prefix ).

    LOOP AT mt_nodes INTO ls_node.
      IF ls_node-path = lv_prefix.
        CLEAR ls_new.
        ls_new-path  = `/`.
        ls_new-name  = ls_node-name.
        ls_new-type  = ls_node-type.
        ls_new-value = ls_node-value.
        ls_new-index = ls_node-index.
        ls_new-order = ls_node-order.
        INSERT ls_new INTO TABLE lt_sliced.
      ELSEIF ls_node-path CP |{ lv_prefix }*|.
        lv_sub_path = substring( val = ls_node-path off = lv_pref_len - 1 ).
        CLEAR ls_new.
        ls_new-path  = lv_sub_path.
        ls_new-name  = ls_node-name.
        ls_new-type  = ls_node-type.
        ls_new-value = ls_node-value.
        ls_new-index = ls_node-index.
        ls_new-order = ls_node-order.
        INSERT ls_new INTO TABLE lt_sliced.
      ENDIF.
    ENDLOOP.

    ri_fragment = NEW zcl_ayaml( it_nodes = lt_sliced ).
  ENDMETHOD.

  METHOD zif_ayaml~clone.
    DATA lt_copy TYPE zif_ayaml_types=>ty_t_nodes.
    lt_copy = mt_nodes.
    ri_ayaml = NEW zcl_ayaml( it_nodes = lt_copy ).
  ENDMETHOD.

  METHOD zif_ayaml_writer~clear.
    CLEAR mt_nodes.
    ri_self = me.
  ENDMETHOD.

  METHOD zif_ayaml_writer~set.
    DATA lv_type   TYPE zif_ayaml_types=>ty_node_type.
    DATA lv_parent TYPE string.
    DATA lv_name   TYPE string.
    DATA ls_node   TYPE zif_ayaml_types=>ty_s_node.
    DATA lv_val_s  TYPE string.
    DATA lv_norm   TYPE string.
    DATA lo_descr  TYPE REF TO cl_abap_typedescr.

    IF iv_ignore_empty = abap_true AND iv_val IS INITIAL.
      ri_self = me.
      RETURN.
    ENDIF.

    lo_descr = cl_abap_typedescr=>describe_by_data( iv_val ).
    IF lo_descr->kind = cl_abap_typedescr=>kind_struct OR lo_descr->kind = cl_abap_typedescr=>kind_table.
      set_recursive( iv_path = iv_path iv_val = iv_val ).
      ri_self = me.
      RETURN.
    ENDIF.

    IF iv_node_type IS NOT INITIAL.
      lv_type = iv_node_type.
    ELSE.
      lv_type = zcl_ayaml_utils=>detect_type( iv_val ).
    ENDIF.

    lv_val_s = zcl_ayaml_utils=>to_string( iv_val = iv_val iv_type = lv_type ).
    lv_norm = zcl_ayaml_utils=>normalize_path( iv_path ).
    ensure_path_exists( lv_norm ).
    zcl_ayaml_utils=>split_path( EXPORTING iv_path = lv_norm
                                 IMPORTING ev_path = lv_parent
                                           ev_name = lv_name ).

    READ TABLE mt_nodes WITH KEY path = lv_parent name = lv_name INTO ls_node.
    IF sy-subrc = 0.
      ls_node-type  = lv_type.
      ls_node-value = lv_val_s.
      MODIFY TABLE mt_nodes FROM ls_node.
    ELSE.
      CLEAR ls_node.
      ls_node-path  = lv_parent.
      ls_node-name  = lv_name.
      ls_node-type  = lv_type.
      ls_node-value = lv_val_s.
      ls_node-order = lines( mt_nodes ) + 1.
      INSERT ls_node INTO TABLE mt_nodes.
    ENDIF.
    ri_self = me.
  ENDMETHOD.

  METHOD zif_ayaml_writer~set_boolean.
    ri_self = set_typed( iv_path = iv_path iv_val = iv_val iv_type = zif_ayaml_types=>cs_type-boolean ).
  ENDMETHOD.

  METHOD zif_ayaml_writer~set_string.
    ri_self = set_typed( iv_path = iv_path iv_val = iv_val iv_type = zif_ayaml_types=>cs_type-string ).
  ENDMETHOD.

  METHOD zif_ayaml_writer~set_integer.
    ri_self = set_typed( iv_path = iv_path iv_val = iv_val iv_type = zif_ayaml_types=>cs_type-number ).
  ENDMETHOD.

  METHOD zif_ayaml_writer~set_number.
    ri_self = set_typed( iv_path = iv_path iv_val = iv_val iv_type = zif_ayaml_types=>cs_type-number ).
  ENDMETHOD.

  METHOD zif_ayaml_writer~set_date.
    ri_self = set_typed( iv_path = iv_path iv_val = iv_val iv_type = zif_ayaml_types=>cs_type-date ).
  ENDMETHOD.

  METHOD zif_ayaml_writer~set_timestamp.
    DATA lv_ts_s TYPE string.
    lv_ts_s = zcl_ayaml_utils=>format_timestamp( iv_val ).
    ri_self = set_typed( iv_path = iv_path iv_val = lv_ts_s iv_type = zif_ayaml_types=>cs_type-string ).
  ENDMETHOD.

  METHOD zif_ayaml_writer~set_null.
    DATA lv_parent TYPE string.
    DATA lv_name   TYPE string.
    DATA ls_node   TYPE zif_ayaml_types=>ty_s_node.
    DATA lv_norm   TYPE string.

    lv_norm = zcl_ayaml_utils=>normalize_path( iv_path ).
    ensure_path_exists( lv_norm ).
    zcl_ayaml_utils=>split_path( EXPORTING iv_path = lv_norm
                                 IMPORTING ev_path = lv_parent
                                           ev_name = lv_name ).

    READ TABLE mt_nodes WITH KEY path = lv_parent name = lv_name INTO ls_node.
    IF sy-subrc = 0.
      ls_node-type  = zif_ayaml_types=>cs_type-null.
      ls_node-value = `null`.
      MODIFY TABLE mt_nodes FROM ls_node.
    ELSE.
      CLEAR ls_node.
      ls_node-path  = lv_parent.
      ls_node-name  = lv_name.
      ls_node-type  = zif_ayaml_types=>cs_type-null.
      ls_node-value = `null`.
      ls_node-order = lines( mt_nodes ) + 1.
      INSERT ls_node INTO TABLE mt_nodes.
    ENDIF.
    ri_self = me.
  ENDMETHOD.

  METHOD zif_ayaml_writer~delete.
    DATA lv_parent TYPE string.
    DATA lv_name   TYPE string.
    DATA lv_norm   TYPE string.
    DATA lv_prefix TYPE string.
    DATA ls_node   TYPE zif_ayaml_types=>ty_s_node.
    DATA lt_keep   TYPE zif_ayaml_types=>ty_t_nodes.

    lv_norm = zcl_ayaml_utils=>normalize_path( iv_path ).
    zcl_ayaml_utils=>split_path( EXPORTING iv_path = lv_norm
                                 IMPORTING ev_path = lv_parent
                                           ev_name = lv_name ).
    READ TABLE mt_nodes WITH KEY path = lv_parent name = lv_name INTO ls_node.
    IF sy-subrc = 0.
      DELETE TABLE mt_nodes FROM ls_node.
    ENDIF.

    lv_prefix = |{ lv_norm }/|.
    LOOP AT mt_nodes INTO ls_node.
      IF ls_node-path CP |{ lv_prefix }*|.
        CONTINUE.
      ENDIF.
      INSERT ls_node INTO TABLE lt_keep.
    ENDLOOP.
    mt_nodes = lt_keep.
    ri_self = me.
  ENDMETHOD.

  METHOD zif_ayaml_writer~ensure_sequence.
    DATA lv_parent TYPE string.
    DATA lv_name   TYPE string.
    DATA ls_node   TYPE zif_ayaml_types=>ty_s_node.
    DATA lv_norm   TYPE string.
    DATA lt_keep   TYPE zif_ayaml_types=>ty_t_nodes.

    lv_norm = zcl_ayaml_utils=>normalize_path( iv_path ).
    zcl_ayaml_utils=>split_path( EXPORTING iv_path = lv_norm
                                 IMPORTING ev_path = lv_parent
                                           ev_name = lv_name ).
    READ TABLE mt_nodes WITH KEY path = lv_parent name = lv_name INTO ls_node.
    IF sy-subrc = 0.
      IF ls_node-type <> zif_ayaml_types=>cs_type-sequence.
        ls_node-type  = zif_ayaml_types=>cs_type-sequence.
        ls_node-value = ``.
        MODIFY TABLE mt_nodes FROM ls_node.
      ENDIF.
      IF iv_clear = abap_true.
        DATA(lv_prefix) = |{ lv_parent }{ lv_name }/|.
        CLEAR lt_keep.
        LOOP AT mt_nodes INTO ls_node.
          IF ls_node-path CP |{ lv_prefix }*|.
            CONTINUE.
          ENDIF.
          INSERT ls_node INTO TABLE lt_keep.
        ENDLOOP.
        mt_nodes = lt_keep.
      ENDIF.
    ELSE.
      ensure_path_exists( lv_norm ).
      CLEAR ls_node.
      ls_node-path  = lv_parent.
      ls_node-name  = lv_name.
      ls_node-type  = zif_ayaml_types=>cs_type-sequence.
      ls_node-value = ``.
      ls_node-order = lines( mt_nodes ) + 1.
      INSERT ls_node INTO TABLE mt_nodes.
    ENDIF.
    ri_self = me.
  ENDMETHOD.

  METHOD zif_ayaml_writer~append_to_sequence.
    DATA lv_parent TYPE string.
    DATA lv_name   TYPE string.
    DATA ls_seq    TYPE zif_ayaml_types=>ty_s_node.
    DATA ls_item   TYPE zif_ayaml_types=>ty_s_node.
    DATA lv_type   TYPE zif_ayaml_types=>ty_node_type.
    DATA lv_value  TYPE string.
    DATA lv_index  TYPE i.
    DATA lv_norm   TYPE string.
    DATA lo_descr  TYPE REF TO cl_abap_typedescr.
    DATA lv_item_path TYPE string.

    lv_norm = zcl_ayaml_utils=>normalize_path( iv_path ).
    zcl_ayaml_utils=>split_path( EXPORTING iv_path = lv_norm
                                 IMPORTING ev_path = lv_parent
                                           ev_name = lv_name ).
    READ TABLE mt_nodes WITH KEY path = lv_parent name = lv_name INTO ls_seq.
    IF sy-subrc <> 0 OR ls_seq-type <> zif_ayaml_types=>cs_type-sequence.
      RAISE EXCEPTION NEW zcx_ayaml_error( iv_msg = `Path is not a sequence` ).
    ENDIF.

    lv_type  = zcl_ayaml_utils=>detect_type( iv_val ).
    lv_value = zcl_ayaml_utils=>to_string( iv_val = iv_val iv_type = lv_type ).
    lv_index = get_next_index( |{ lv_norm }/| ).

    CLEAR ls_item.
    ls_item-path  = |{ lv_norm }/|.
    ls_item-name  = |{ lv_index }|.
    ls_item-type  = lv_type.
    ls_item-value = lv_value.
    ls_item-index = lv_index.
    ls_item-order = lines( mt_nodes ) + 1.
    INSERT ls_item INTO TABLE mt_nodes.

    TRY.
        lo_descr = cl_abap_typedescr=>describe_by_data( iv_val ).
        IF lo_descr->kind = cl_abap_typedescr=>kind_struct OR lo_descr->kind = cl_abap_typedescr=>kind_table.
          lv_item_path = |{ lv_norm }/{ lv_index }|.
          DELETE TABLE mt_nodes FROM ls_item.
          set_recursive( iv_path = lv_item_path iv_val = iv_val ).
          READ TABLE mt_nodes WITH KEY path = |{ lv_norm }/| name = |{ lv_index }| INTO ls_item.
          IF sy-subrc <> 0.
            CLEAR ls_item.
            ls_item-path  = |{ lv_norm }/|.
            ls_item-name  = |{ lv_index }|.
            ls_item-type  = zif_ayaml_types=>cs_type-mapping.
            ls_item-index = lv_index.
            ls_item-order = lines( mt_nodes ) + 1.
            INSERT ls_item INTO TABLE mt_nodes.
          ENDIF.
        ENDIF.
      CATCH cx_root.
    ENDTRY.
    ri_self = me.
  ENDMETHOD.

ENDCLASS.
