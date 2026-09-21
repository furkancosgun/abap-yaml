CLASS zcl_ayaml DEFINITION PUBLIC FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES zif_ayaml.

    CLASS-METHODS create_empty
      RETURNING VALUE(ro_instance) TYPE REF TO zif_ayaml.

    CLASS-METHODS parse
      IMPORTING iv_yaml            TYPE string
      RETURNING VALUE(ro_instance) TYPE REF TO zif_ayaml
      RAISING   zcx_ayaml_error.

    CLASS-METHODS from_abap
      IMPORTING iv_data         TYPE any
                iv_format       TYPE zif_ayaml_types=>ty_format OPTIONAL
                iv_indent       TYPE i                          DEFAULT 0
                iv_ignore_empty TYPE abap_bool                  DEFAULT abap_false
      RETURNING VALUE(rv_yaml)  TYPE string
      RAISING   zcx_ayaml_error.

  PRIVATE SECTION.
    DATA mt_nodes TYPE zif_ayaml_types=>ty_t_nodes.

    METHODS constructor
      IMPORTING it_nodes TYPE zif_ayaml_types=>ty_t_nodes OPTIONAL.

    METHODS ensure_path_exists
      IMPORTING iv_full_path TYPE string.

    METHODS set_recursive
      IMPORTING iv_path   TYPE string
                iv_value  TYPE any
                iv_format TYPE zif_ayaml_types=>ty_format OPTIONAL
      RAISING   zcx_ayaml_error.

    METHODS get_next_index
      IMPORTING iv_path         TYPE string
      RETURNING VALUE(rv_index) TYPE i.

    METHODS set_typed
      IMPORTING iv_path            TYPE string
                iv_value           TYPE any
                iv_type            TYPE zif_ayaml_types=>ty_node_type
      RETURNING VALUE(ro_instance) TYPE REF TO zif_ayaml
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
    CREATE OBJECT ro_instance TYPE zcl_ayaml.
  ENDMETHOD.

  METHOD parse.
    DATA lo_scanner TYPE REF TO lcl_scanner.
    DATA lt_tokens  TYPE zif_ayaml_types=>ty_t_tokens.
    DATA lo_parser  TYPE REF TO lcl_ast_parser.
    DATA lo_ast     TYPE REF TO lcl_ast_node.
    DATA lt_nodes   TYPE zif_ayaml_types=>ty_t_nodes.

    IF iv_yaml IS NOT INITIAL.
      CREATE OBJECT lo_scanner
        EXPORTING iv_yaml = iv_yaml.
      lt_tokens = lo_scanner->scan( ).
      CREATE OBJECT lo_parser
        EXPORTING it_tokens = lt_tokens.
      lo_ast = lo_parser->parse( ).
      lt_nodes = lcl_ast_to_nodes=>convert( lo_ast ).
    ENDIF.

    CREATE OBJECT ro_instance TYPE zcl_ayaml
      EXPORTING it_nodes = lt_nodes.
  ENDMETHOD.

  METHOD from_abap.
    DATA lo_descr TYPE REF TO cl_abap_typedescr.
    DATA lo_ayaml TYPE REF TO zcl_ayaml.

    CREATE OBJECT lo_ayaml TYPE zcl_ayaml.
    lo_descr = cl_abap_typedescr=>describe_by_data( iv_data ).

    IF lo_descr->kind = cl_abap_typedescr=>kind_struct OR lo_descr->kind = cl_abap_typedescr=>kind_table.
      lo_ayaml->set_recursive( iv_path   = ``
                               iv_value  = iv_data
                               iv_format = iv_format ).
    ELSE.
      lo_ayaml->zif_ayaml~set( iv_path         = `/value`
                               iv_value        = iv_data
                               iv_ignore_empty = iv_ignore_empty ).
    ENDIF.

    rv_yaml = lo_ayaml->zif_ayaml~to_yaml( iv_indent ).
  ENDMETHOD.

  METHOD set_typed.
    zif_ayaml~set( iv_path         = iv_path
                   iv_value        = iv_value
                   iv_node_type    = iv_type
                   iv_ignore_empty = abap_false ).
    ro_instance = me.
  ENDMETHOD.

  METHOD ensure_path_exists.
    DATA lt_parts      TYPE zif_ayaml_types=>ty_t_string.
    DATA ls_node       TYPE zif_ayaml_types=>ty_s_node.
    DATA lv_clean      TYPE string.
    DATA lv_cum_parent TYPE string.
    DATA lv_order      TYPE i.
    DATA lv_index      TYPE i.
    DATA lv_count      TYPE i.
    FIELD-SYMBOLS <fs_part> TYPE string.

    lv_clean = zcl_ayaml_utils=>normalize_path( iv_full_path ).
    SPLIT lv_clean AT `/` INTO TABLE lt_parts.
    lv_cum_parent = `/`.
    lv_order = lines( mt_nodes ) + 1.
    lv_index = 0.
    lv_count = lines( lt_parts ).

    LOOP AT lt_parts ASSIGNING <fs_part>.
      lv_index = lv_index + 1.
      IF <fs_part> IS INITIAL.
        CONTINUE.
      ENDIF.
      IF lv_index = lv_count.
        EXIT.
      ENDIF.
      READ TABLE mt_nodes WITH KEY path = lv_cum_parent
                                   name = <fs_part> TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        CLEAR ls_node.
        ls_node-path  = lv_cum_parent.
        ls_node-name  = <fs_part>.
        ls_node-type  = zif_ayaml_types=>cs_type-mapping.
        ls_node-value = ``.
        ls_node-order = lv_order.
        INSERT ls_node INTO TABLE mt_nodes.
        lv_order = lv_order + 1.
      ENDIF.
      lv_cum_parent = |{ lv_cum_parent }{ <fs_part> }/|.
    ENDLOOP.
  ENDMETHOD.

  METHOD set_recursive.
    DATA lo_descr         TYPE REF TO cl_abap_typedescr.
    DATA lo_struct        TYPE REF TO cl_abap_structdescr.
    DATA lt_comps         TYPE abap_component_tab.
    DATA lv_comp_name     TYPE string.
    DATA lv_f_name        TYPE string.
    DATA lv_comp_path     TYPE string.
    DATA lv_idx           TYPE i.
    DATA lo_line_descr    TYPE REF TO cl_abap_typedescr.
    DATA lv_item_path     TYPE string.
    DATA lv_target_parent TYPE string.
    DATA lv_idx_str       TYPE string.
    FIELD-SYMBOLS <fs_comp>      TYPE abap_componentdescr.
    FIELD-SYMBOLS <fs_field>     TYPE any.
    FIELD-SYMBOLS <fs_table>     TYPE STANDARD TABLE.
    FIELD-SYMBOLS <fs_line>      TYPE any.
    FIELD-SYMBOLS <fs_item_node> TYPE zif_ayaml_types=>ty_s_node.

    lo_descr = cl_abap_typedescr=>describe_by_data( iv_value ).
    CASE lo_descr->kind.
      WHEN cl_abap_typedescr=>kind_struct.
        lo_struct ?= lo_descr.
        lt_comps = lo_struct->get_components( ).
        LOOP AT lt_comps ASSIGNING <fs_comp>.
          ASSIGN COMPONENT <fs_comp>-name OF STRUCTURE iv_value TO <fs_field>.
          IF sy-subrc <> 0.
            CONTINUE.
          ENDIF.

          lv_comp_name = <fs_comp>-name.
          lv_f_name = zcl_ayaml_utils=>format_field_name( iv_name   = lv_comp_name
                                                          iv_format = iv_format ).
          IF iv_path IS INITIAL.
            lv_comp_path = |/{ lv_f_name }|.
          ELSE.
            lv_comp_path = |{ iv_path }/{ lv_f_name }|.
          ENDIF.
          set_recursive( iv_path   = lv_comp_path
                         iv_value  = <fs_field>
                         iv_format = iv_format ).
        ENDLOOP.
      WHEN cl_abap_typedescr=>kind_table.
        ASSIGN iv_value TO <fs_table>.
        IF sy-subrc = 0.
          IF iv_path IS NOT INITIAL.
            zif_ayaml~touch_array( iv_path  = iv_path
                                   iv_clear = abap_true ).
          ENDIF.
          lv_idx = 0.
          LOOP AT <fs_table> ASSIGNING <fs_line>.
            lv_idx = lv_idx + 1.
            lo_line_descr = cl_abap_typedescr=>describe_by_data( <fs_line> ).
            IF    lo_line_descr->kind = cl_abap_typedescr=>kind_struct
               OR lo_line_descr->kind = cl_abap_typedescr=>kind_table.
              IF iv_path IS INITIAL.
                lv_item_path = |/{ lv_idx }|.
              ELSE.
                lv_item_path = |{ iv_path }/{ lv_idx }|.
              ENDIF.
              set_recursive( iv_path   = lv_item_path
                             iv_value  = <fs_line>
                             iv_format = iv_format ).
              IF iv_path IS INITIAL.
                lv_target_parent = `/`.
              ELSE.
                lv_target_parent = |{ iv_path }/|.
              ENDIF.
              lv_idx_str = |{ lv_idx }|.
              READ TABLE mt_nodes WITH KEY path = lv_target_parent
                                           name = lv_idx_str ASSIGNING <fs_item_node>.
              IF sy-subrc = 0.
                <fs_item_node>-index = lv_idx.
              ENDIF.
            ELSEIF iv_path IS INITIAL.
              zif_ayaml~touch_array( `/` ).
              zif_ayaml~push( iv_path  = `/`
                              iv_value = <fs_line> ).
            ELSE.
              zif_ayaml~push( iv_path  = iv_path
                              iv_value = <fs_line> ).
            ENDIF.
          ENDLOOP.
        ENDIF.
      WHEN OTHERS.
        zif_ayaml~set( iv_path  = iv_path
                       iv_value = iv_value ).
    ENDCASE.
  ENDMETHOD.

  METHOD get_next_index.
    DATA lv_max TYPE i.
    FIELD-SYMBOLS <fs_node> TYPE zif_ayaml_types=>ty_s_node.

    lv_max = 0.
    LOOP AT mt_nodes ASSIGNING <fs_node> USING KEY path_key WHERE path = iv_path.
      IF <fs_node>-index > lv_max.
        lv_max = <fs_node>-index.
      ENDIF.
    ENDLOOP.
    rv_index = lv_max + 1.
  ENDMETHOD.

  METHOD get_node_internal.
    DATA lv_parent TYPE string.
    DATA lv_name   TYPE string.
    FIELD-SYMBOLS <fs_node> TYPE zif_ayaml_types=>ty_s_node.

    zcl_ayaml_utils=>split_path( EXPORTING iv_path = iv_path
                                 IMPORTING ev_path = lv_parent
                                           ev_name = lv_name ).
    READ TABLE mt_nodes WITH KEY path = lv_parent
                                 name = lv_name ASSIGNING <fs_node>.
    IF sy-subrc = 0.
      rs_node = <fs_node>.
    ELSE.
      CLEAR rs_node.
    ENDIF.
  ENDMETHOD.

  METHOD get_value_internal.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.

    ls_node = get_node_internal( iv_path ).
    rv_value = ls_node-value.
  ENDMETHOD.

  METHOD convert_to_integer.
    TRY.
        rv_int = iv_value.
      CATCH cx_root.
        rv_int = 0.
    ENDTRY.
  ENDMETHOD.

  METHOD convert_to_number.
    TRY.
        rv_num = iv_value.
      CATCH cx_root.
        rv_num = 0.
    ENDTRY.
  ENDMETHOD.

  METHOD zif_ayaml~is_empty.
    rv_yes = boolc( lines( mt_nodes ) = 0 ).
  ENDMETHOD.

  METHOD zif_ayaml~exists.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.

    ls_node = get_node_internal( iv_path ).
    rv_yes = boolc( ls_node-path IS NOT INITIAL OR ls_node-name IS NOT INITIAL ).
  ENDMETHOD.

  METHOD zif_ayaml~get.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.
    DATA lv_norm TYPE string.
    FIELD-SYMBOLS <fs_first> TYPE zif_ayaml_types=>ty_s_node.

    lv_norm = zcl_ayaml_utils=>normalize_path( iv_path ).
    IF lv_norm = `/` AND lines( mt_nodes ) = 1.
      READ TABLE mt_nodes INDEX 1 ASSIGNING <fs_first>.
      IF sy-subrc = 0 AND <fs_first>-path = `/` AND <fs_first>-name = `value`.
        rv_result = <fs_first>-value.
        RETURN.
      ENDIF.
    ENDIF.

    ls_node = get_node_internal( iv_path ).
    IF ls_node-path IS INITIAL AND ls_node-name IS INITIAL.
      IF iv_default IS SUPPLIED.
        rv_result = iv_default.
      ELSE.
        rv_result = ``.
      ENDIF.
      RETURN.
    ENDIF.
    IF ls_node-type = zif_ayaml_types=>cs_type-null AND iv_default IS SUPPLIED.
      rv_result = iv_default.
      RETURN.
    ENDIF.
    rv_result = get_value_internal( iv_path ).
  ENDMETHOD.

  METHOD zif_ayaml~get_string.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.

    ls_node = get_node_internal( iv_path ).
    IF ls_node-path IS INITIAL AND ls_node-name IS INITIAL.
      IF iv_default IS SUPPLIED.
        rv_result = iv_default.
      ELSE.
        rv_result = ``.
      ENDIF.
      RETURN.
    ENDIF.
    IF ls_node-type = zif_ayaml_types=>cs_type-null.
      IF iv_default IS SUPPLIED.
        rv_result = iv_default.
      ELSE.
        rv_result = ``.
      ENDIF.
      RETURN.
    ENDIF.
    rv_result = ls_node-value.
  ENDMETHOD.

  METHOD zif_ayaml~get_integer.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.

    ls_node = get_node_internal( iv_path ).
    IF ls_node-path IS INITIAL AND ls_node-name IS INITIAL.
      IF iv_default IS SUPPLIED.
        rv_result = iv_default.
      ELSE.
        rv_result = 0.
      ENDIF.
      RETURN.
    ENDIF.
    IF ls_node-type = zif_ayaml_types=>cs_type-null.
      IF iv_default IS SUPPLIED.
        rv_result = iv_default.
      ELSE.
        rv_result = 0.
      ENDIF.
      RETURN.
    ENDIF.
    rv_result = convert_to_integer( ls_node-value ).
  ENDMETHOD.

  METHOD zif_ayaml~get_number.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.

    ls_node = get_node_internal( iv_path ).
    IF ls_node-path IS INITIAL AND ls_node-name IS INITIAL.
      IF iv_default IS SUPPLIED.
        rv_result = iv_default.
      ELSE.
        rv_result = 0.
      ENDIF.
      RETURN.
    ENDIF.
    IF ls_node-type = zif_ayaml_types=>cs_type-null.
      IF iv_default IS SUPPLIED.
        rv_result = iv_default.
      ELSE.
        rv_result = 0.
      ENDIF.
      RETURN.
    ENDIF.
    rv_result = convert_to_number( ls_node-value ).
  ENDMETHOD.

  METHOD zif_ayaml~get_boolean.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.

    ls_node = get_node_internal( iv_path ).
    IF ls_node-path IS INITIAL AND ls_node-name IS INITIAL.
      IF iv_default IS SUPPLIED.
        rv_result = iv_default.
      ELSE.
        rv_result = abap_false.
      ENDIF.
      RETURN.
    ENDIF.
    IF ls_node-type = zif_ayaml_types=>cs_type-null.
      IF iv_default IS SUPPLIED.
        rv_result = iv_default.
      ELSE.
        rv_result = abap_false.
      ENDIF.
      RETURN.
    ENDIF.
    rv_result = boolc( ls_node-value = `true` OR ls_node-value = `X` OR ls_node-value = `1` ).
  ENDMETHOD.

  METHOD zif_ayaml~get_date.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.

    ls_node = get_node_internal( iv_path ).
    IF ls_node-path IS INITIAL AND ls_node-name IS INITIAL.
      IF iv_default IS SUPPLIED.
        rv_result = iv_default.
      ENDIF.
      RETURN.
    ENDIF.
    IF ls_node-type = zif_ayaml_types=>cs_type-null.
      IF iv_default IS SUPPLIED.
        rv_result = iv_default.
      ENDIF.
      RETURN.
    ENDIF.
    TRY.
        rv_result = zcl_ayaml_utils=>parse_date( ls_node-value ).
      CATCH cx_root.
        IF iv_default IS SUPPLIED.
          rv_result = iv_default.
        ELSE.
          CLEAR rv_result.
        ENDIF.
    ENDTRY.
  ENDMETHOD.

  METHOD zif_ayaml~get_timestamp.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.

    ls_node = get_node_internal( iv_path ).
    IF ls_node-path IS INITIAL AND ls_node-name IS INITIAL.
      IF iv_default IS SUPPLIED.
        rv_result = iv_default.
      ENDIF.
      RETURN.
    ENDIF.
    IF ls_node-type = zif_ayaml_types=>cs_type-null.
      IF iv_default IS SUPPLIED.
        rv_result = iv_default.
      ENDIF.
      RETURN.
    ENDIF.
    TRY.
        rv_result = zcl_ayaml_utils=>parse_timestamp( ls_node-value ).
      CATCH cx_root.
        IF iv_default IS SUPPLIED.
          rv_result = iv_default.
        ELSE.
          CLEAR rv_result.
        ENDIF.
    ENDTRY.
  ENDMETHOD.

  METHOD zif_ayaml~get_node.
    rs_node = get_node_internal( iv_path ).
  ENDMETHOD.

  METHOD zif_ayaml~get_node_type.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.

    ls_node = get_node_internal( iv_path ).
    rv_result = ls_node-type.
  ENDMETHOD.

  METHOD zif_ayaml~members.
    DATA lv_norm TYPE string.
    FIELD-SYMBOLS <fs_node> TYPE zif_ayaml_types=>ty_s_node.

    lv_norm = zcl_ayaml_utils=>normalize_path( iv_path ).
    IF lv_norm <> `/`.
      lv_norm = |{ lv_norm }/|.
    ENDIF.

    LOOP AT mt_nodes ASSIGNING <fs_node> USING KEY path_key WHERE path = lv_norm.
      INSERT <fs_node>-name INTO TABLE rt_keys.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_ayaml~array_length.
    DATA lv_norm TYPE string.
    DATA lv_cnt  TYPE i.

    lv_norm = zcl_ayaml_utils=>normalize_path( iv_path ).
    lv_norm = |{ lv_norm }/|.
    lv_cnt = 0.
    LOOP AT mt_nodes TRANSPORTING NO FIELDS USING KEY path_key WHERE path = lv_norm.
      lv_cnt = lv_cnt + 1.
    ENDLOOP.
    rv_length = lv_cnt.
  ENDMETHOD.

  METHOD zif_ayaml~get_string_table.
    DATA lv_norm     TYPE string.
    DATA lt_children TYPE zif_ayaml_types=>ty_t_nodes_flat.
    FIELD-SYMBOLS <fs_node>  TYPE zif_ayaml_types=>ty_s_node.
    FIELD-SYMBOLS <fs_child> TYPE zif_ayaml_types=>ty_s_node.

    lv_norm = zcl_ayaml_utils=>normalize_path( iv_path ).
    lv_norm = |{ lv_norm }/|.
    LOOP AT mt_nodes ASSIGNING <fs_node> USING KEY path_key WHERE path = lv_norm.
      INSERT <fs_node> INTO TABLE lt_children.
    ENDLOOP.
    SORT lt_children BY order.
    LOOP AT lt_children ASSIGNING <fs_child>.
      INSERT <fs_child>-value INTO TABLE rt_values.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_ayaml~to_abap.
    lcl_deserializer=>deserialize( EXPORTING it_nodes = mt_nodes
                                   IMPORTING ev_data  = ev_data ).
  ENDMETHOD.

  METHOD zif_ayaml~to_yaml.
    rv_yaml = lcl_serializer=>stringify( it_nodes  = mt_nodes
                                         iv_indent = iv_indent ).
  ENDMETHOD.

  METHOD zif_ayaml~slice.
    DATA lt_sliced   TYPE zif_ayaml_types=>ty_t_nodes.
    DATA ls_new      TYPE zif_ayaml_types=>ty_s_node.
    DATA lv_norm     TYPE string.
    DATA lv_prefix   TYPE string.
    DATA lv_pref_len TYPE i.
    DATA lv_sub_path TYPE string.
    FIELD-SYMBOLS <fs_node> TYPE zif_ayaml_types=>ty_s_node.

    lv_norm = zcl_ayaml_utils=>normalize_path( iv_path ).
    lv_prefix = |{ lv_norm }/|.
    lv_pref_len = strlen( lv_norm ).

    LOOP AT mt_nodes ASSIGNING <fs_node>.
      IF <fs_node>-path = lv_prefix.
        CLEAR ls_new.
        ls_new-path  = `/`.
        ls_new-name  = <fs_node>-name.
        ls_new-type  = <fs_node>-type.
        ls_new-value = <fs_node>-value.
        ls_new-index = <fs_node>-index.
        ls_new-order = <fs_node>-order.
        INSERT ls_new INTO TABLE lt_sliced.
      ELSEIF <fs_node>-path CP |{ lv_prefix }*|.
        lv_sub_path = substring( val = <fs_node>-path
                                 off = lv_pref_len - 1 ).
        CLEAR ls_new.
        ls_new-path  = lv_sub_path.
        ls_new-name  = <fs_node>-name.
        ls_new-type  = <fs_node>-type.
        ls_new-value = <fs_node>-value.
        ls_new-index = <fs_node>-index.
        ls_new-order = <fs_node>-order.
        INSERT ls_new INTO TABLE lt_sliced.
      ENDIF.
    ENDLOOP.

    CREATE OBJECT ro_instance TYPE zcl_ayaml
      EXPORTING it_nodes = lt_sliced.
  ENDMETHOD.

  METHOD zif_ayaml~clone.
    DATA lt_copy TYPE zif_ayaml_types=>ty_t_nodes.

    lt_copy = mt_nodes.
    CREATE OBJECT ro_instance TYPE zcl_ayaml
      EXPORTING it_nodes = lt_copy.
  ENDMETHOD.

  METHOD zif_ayaml~clear.
    CLEAR mt_nodes.
    ro_instance = me.
  ENDMETHOD.

  METHOD zif_ayaml~set.
    DATA lv_parent TYPE string.
    DATA lv_name   TYPE string.
    DATA lv_type   TYPE zif_ayaml_types=>ty_node_type.
    DATA lv_val_s  TYPE string.
    DATA lv_norm   TYPE string.
    DATA lo_descr  TYPE REF TO cl_abap_typedescr.
    DATA ls_node   TYPE zif_ayaml_types=>ty_s_node.
    FIELD-SYMBOLS <fs_node> TYPE zif_ayaml_types=>ty_s_node.

    IF iv_ignore_empty = abap_true AND iv_value IS INITIAL.
      ro_instance = me.
      RETURN.
    ENDIF.

    lo_descr = cl_abap_typedescr=>describe_by_data( iv_value ).
    IF lo_descr->kind = cl_abap_typedescr=>kind_struct OR lo_descr->kind = cl_abap_typedescr=>kind_table.
      set_recursive( iv_path  = iv_path
                     iv_value = iv_value ).
      ro_instance = me.
      RETURN.
    ENDIF.

    IF iv_node_type IS NOT INITIAL.
      lv_type = iv_node_type.
    ELSE.
      lv_type = zcl_ayaml_utils=>detect_type( iv_value ).
    ENDIF.

    lv_val_s = zcl_ayaml_utils=>to_string( iv_val  = iv_value
                                           iv_type = lv_type ).
    lv_norm = zcl_ayaml_utils=>normalize_path( iv_path ).
    ensure_path_exists( lv_norm ).
    zcl_ayaml_utils=>split_path( EXPORTING iv_path = lv_norm
                                 IMPORTING ev_path = lv_parent
                                           ev_name = lv_name ).

    READ TABLE mt_nodes WITH KEY path = lv_parent
                                 name = lv_name ASSIGNING <fs_node>.
    IF sy-subrc = 0.
      <fs_node>-type  = lv_type.
      <fs_node>-value = lv_val_s.
    ELSE.
      CLEAR ls_node.
      ls_node-path  = lv_parent.
      ls_node-name  = lv_name.
      ls_node-type  = lv_type.
      ls_node-value = lv_val_s.
      ls_node-order = lines( mt_nodes ) + 1.
      INSERT ls_node INTO TABLE mt_nodes.
    ENDIF.
    ro_instance = me.
  ENDMETHOD.

  METHOD zif_ayaml~set_boolean.
    ro_instance = set_typed( iv_path  = iv_path
                             iv_value = iv_value
                             iv_type  = zif_ayaml_types=>cs_type-boolean ).
  ENDMETHOD.

  METHOD zif_ayaml~set_string.
    ro_instance = set_typed( iv_path  = iv_path
                             iv_value = iv_value
                             iv_type  = zif_ayaml_types=>cs_type-string ).
  ENDMETHOD.

  METHOD zif_ayaml~set_integer.
    ro_instance = set_typed( iv_path  = iv_path
                             iv_value = iv_value
                             iv_type  = zif_ayaml_types=>cs_type-number ).
  ENDMETHOD.

  METHOD zif_ayaml~set_number.
    ro_instance = set_typed( iv_path  = iv_path
                             iv_value = iv_value
                             iv_type  = zif_ayaml_types=>cs_type-number ).
  ENDMETHOD.

  METHOD zif_ayaml~set_date.
    ro_instance = set_typed( iv_path  = iv_path
                             iv_value = iv_value
                             iv_type  = zif_ayaml_types=>cs_type-date ).
  ENDMETHOD.

  METHOD zif_ayaml~set_timestamp.
    DATA lv_ts_s TYPE string.

    lv_ts_s = zcl_ayaml_utils=>format_timestamp( iv_value ).
    ro_instance = set_typed( iv_path  = iv_path
                             iv_value = lv_ts_s
                             iv_type  = zif_ayaml_types=>cs_type-string ).
  ENDMETHOD.

  METHOD zif_ayaml~set_null.
    DATA lv_parent TYPE string.
    DATA lv_name   TYPE string.
    DATA lv_norm   TYPE string.
    DATA ls_node   TYPE zif_ayaml_types=>ty_s_node.
    FIELD-SYMBOLS <fs_node> TYPE zif_ayaml_types=>ty_s_node.

    lv_norm = zcl_ayaml_utils=>normalize_path( iv_path ).
    ensure_path_exists( lv_norm ).
    zcl_ayaml_utils=>split_path( EXPORTING iv_path = lv_norm
                                 IMPORTING ev_path = lv_parent
                                           ev_name = lv_name ).

    READ TABLE mt_nodes WITH KEY path = lv_parent
                                 name = lv_name ASSIGNING <fs_node>.
    IF sy-subrc = 0.
      <fs_node>-type  = zif_ayaml_types=>cs_type-null.
      <fs_node>-value = `null`.
    ELSE.
      CLEAR ls_node.
      ls_node-path  = lv_parent.
      ls_node-name  = lv_name.
      ls_node-type  = zif_ayaml_types=>cs_type-null.
      ls_node-value = `null`.
      ls_node-order = lines( mt_nodes ) + 1.
      INSERT ls_node INTO TABLE mt_nodes.
    ENDIF.
    ro_instance = me.
  ENDMETHOD.

  METHOD zif_ayaml~delete.
    DATA lv_parent TYPE string.
    DATA lv_name   TYPE string.
    DATA lt_keep   TYPE zif_ayaml_types=>ty_t_nodes.
    DATA lv_norm   TYPE string.
    DATA lv_prefix TYPE string.
    FIELD-SYMBOLS <fs_node> TYPE zif_ayaml_types=>ty_s_node.

    lv_norm = zcl_ayaml_utils=>normalize_path( iv_path ).
    zcl_ayaml_utils=>split_path( EXPORTING iv_path = lv_norm
                                 IMPORTING ev_path = lv_parent
                                           ev_name = lv_name ).
    READ TABLE mt_nodes WITH KEY path = lv_parent
                                 name = lv_name ASSIGNING <fs_node>.
    IF sy-subrc = 0.
      DELETE TABLE mt_nodes FROM <fs_node>.
    ENDIF.

    lv_prefix = |{ lv_norm }/|.
    LOOP AT mt_nodes ASSIGNING <fs_node>.
      IF <fs_node>-path CP |{ lv_prefix }*|.
        CONTINUE.
      ENDIF.
      INSERT <fs_node> INTO TABLE lt_keep.
    ENDLOOP.
    mt_nodes = lt_keep.
    ro_instance = me.
  ENDMETHOD.

  METHOD zif_ayaml~touch_array.
    DATA lv_parent TYPE string.
    DATA lv_name   TYPE string.
    DATA lt_keep   TYPE zif_ayaml_types=>ty_t_nodes.
    DATA lv_norm   TYPE string.
    DATA lv_prefix TYPE string.
    DATA ls_node   TYPE zif_ayaml_types=>ty_s_node.
    FIELD-SYMBOLS <fs_node> TYPE zif_ayaml_types=>ty_s_node.

    lv_norm = zcl_ayaml_utils=>normalize_path( iv_path ).
    zcl_ayaml_utils=>split_path( EXPORTING iv_path = lv_norm
                                 IMPORTING ev_path = lv_parent
                                           ev_name = lv_name ).
    READ TABLE mt_nodes WITH KEY path = lv_parent
                                 name = lv_name ASSIGNING <fs_node>.
    IF sy-subrc = 0.
      IF <fs_node>-type <> zif_ayaml_types=>cs_type-sequence.
        <fs_node>-type  = zif_ayaml_types=>cs_type-sequence.
        <fs_node>-value = ``.
      ENDIF.
      IF iv_clear = abap_true.
        lv_prefix = |{ lv_parent }{ lv_name }/|.
        CLEAR lt_keep.
        LOOP AT mt_nodes ASSIGNING <fs_node>.
          IF <fs_node>-path CP |{ lv_prefix }*|.
            CONTINUE.
          ENDIF.
          INSERT <fs_node> INTO TABLE lt_keep.
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
    ro_instance = me.
  ENDMETHOD.

  METHOD zif_ayaml~push.
    DATA lv_parent    TYPE string.
    DATA lv_name      TYPE string.
    DATA ls_item      TYPE zif_ayaml_types=>ty_s_node.
    DATA lv_type      TYPE zif_ayaml_types=>ty_node_type.
    DATA lv_value_s   TYPE string.
    DATA lo_descr     TYPE REF TO cl_abap_typedescr.
    DATA lv_norm      TYPE string.
    DATA lv_index     TYPE i.
    DATA lv_item_path TYPE string.
    DATA lv_index_str TYPE string.
    FIELD-SYMBOLS <fs_seq>       TYPE zif_ayaml_types=>ty_s_node.
    " TODO: variable is assigned but never used (ABAP cleaner)
    FIELD-SYMBOLS <fs_item_node> TYPE zif_ayaml_types=>ty_s_node.

    lv_norm = zcl_ayaml_utils=>normalize_path( iv_path ).
    zcl_ayaml_utils=>split_path( EXPORTING iv_path = lv_norm
                                 IMPORTING ev_path = lv_parent
                                           ev_name = lv_name ).
    READ TABLE mt_nodes WITH KEY path = lv_parent
                                 name = lv_name ASSIGNING <fs_seq>.
    IF sy-subrc <> 0 OR <fs_seq>-type <> zif_ayaml_types=>cs_type-sequence.
      RAISE EXCEPTION TYPE zcx_ayaml_error
        EXPORTING iv_msg = `Path is not a sequence`.
    ENDIF.

    lv_type    = zcl_ayaml_utils=>detect_type( iv_value ).
    lv_value_s = zcl_ayaml_utils=>to_string( iv_val  = iv_value
                                             iv_type = lv_type ).
    lv_index = get_next_index( |{ lv_norm }/| ).

    CLEAR ls_item.
    ls_item-path  = |{ lv_norm }/|.
    ls_item-name  = |{ lv_index }|.
    ls_item-type  = lv_type.
    ls_item-value = lv_value_s.
    ls_item-index = lv_index.
    ls_item-order = lines( mt_nodes ) + 1.
    INSERT ls_item INTO TABLE mt_nodes.

    TRY.
        lo_descr = cl_abap_typedescr=>describe_by_data( iv_value ).
        IF lo_descr->kind = cl_abap_typedescr=>kind_struct OR lo_descr->kind = cl_abap_typedescr=>kind_table.
          lv_item_path = |{ lv_norm }/{ lv_index }|.
          DELETE TABLE mt_nodes FROM ls_item.
          set_recursive( iv_path  = lv_item_path
                         iv_value = iv_value ).
          lv_index_str = |{ lv_index }|.
          lv_item_path = |{ lv_norm }/|.
          READ TABLE mt_nodes WITH KEY path = lv_item_path
                                       name = lv_index_str ASSIGNING <fs_item_node>.
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
    ro_instance = me.
  ENDMETHOD.
ENDCLASS.
