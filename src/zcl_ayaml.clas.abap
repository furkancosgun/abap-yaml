CLASS zcl_ayaml DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ayaml.

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
      RETURNING VALUE(ri_self) TYPE REF TO zif_ayaml
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
    DATA lt_nodes TYPE zif_ayaml_types=>ty_t_nodes.

    lt_nodes = zcl_ayaml_parser=>parse( iv_yaml ).
    ri_ayaml = NEW zcl_ayaml( it_nodes = lt_nodes ).
  ENDMETHOD.

  METHOD set_typed.
    zif_ayaml~set( iv_path         = iv_path
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

    lv_clean = zcl_ayaml_path_utils=>normalize( iv_full_path ).
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
      IF NOT line_exists( mt_nodes[ path = lv_cum_parent
                                    name = lv_part ] ).
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
    DATA lo_descr  TYPE REF TO cl_abap_typedescr.
    DATA lo_struct TYPE REF TO cl_abap_structdescr.
    DATA lt_comps  TYPE abap_component_tab.
    FIELD-SYMBOLS <ls_comp>  TYPE abap_componentdescr.
    FIELD-SYMBOLS <lv_field> TYPE any.
    FIELD-SYMBOLS <lt_table> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <lv_line>  TYPE any.
    DATA lv_comp_path TYPE string.

    lo_descr = cl_abap_typedescr=>describe_by_data( iv_val ).
    CASE lo_descr->kind.
      WHEN cl_abap_typedescr=>kind_struct.
        lo_struct ?= lo_descr.
        lt_comps = lo_struct->get_components( ).
        LOOP AT lt_comps ASSIGNING <ls_comp>.
          ASSIGN COMPONENT <ls_comp>-name OF STRUCTURE iv_val TO <lv_field>.
          IF sy-subrc = 0.
            lv_comp_path = |{ iv_path }/{ to_lower( <ls_comp>-name ) }|.
            set_recursive( iv_path = lv_comp_path
                           iv_val  = <lv_field> ).
          ENDIF.
        ENDLOOP.
      WHEN cl_abap_typedescr=>kind_table.
        ASSIGN iv_val TO <lt_table>.
        IF sy-subrc = 0.
          zif_ayaml~touch_array( iv_path  = iv_path
                                 iv_clear = abap_true ).
          LOOP AT <lt_table> ASSIGNING <lv_line>.
            zif_ayaml~push( iv_path = iv_path
                            iv_val  = <lv_line> ).
          ENDLOOP.
        ENDIF.
      WHEN OTHERS.
        zif_ayaml~set( iv_path = iv_path
                       iv_val  = iv_val ).
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

    zcl_ayaml_path_utils=>split( EXPORTING iv_path = iv_path
                                 IMPORTING ev_path = lv_parent
                                           ev_name = lv_name ).
    READ TABLE mt_nodes WITH KEY path = lv_parent
                                 name = lv_name INTO rs_node.
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

  METHOD zif_ayaml~is_empty.
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

  METHOD zif_ayaml~exists.
    DATA lv_norm TYPE string.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.

    lv_norm = zcl_ayaml_path_utils=>normalize( iv_path ).
    IF lv_norm = `/`.
      rv_yes = abap_true.
      RETURN.
    ENDIF.
    ls_node = get_node_internal( lv_norm ).
    rv_yes = xsdbool( NOT ( ls_node-path IS INITIAL AND ls_node-name IS INITIAL ) ).
  ENDMETHOD.

  METHOD zif_ayaml~get.
    rv_value = get_value_internal( iv_path ).
  ENDMETHOD.

  METHOD zif_ayaml~get_string.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.

    ls_node = get_node_internal( iv_path ).
    IF ls_node-path IS INITIAL AND ls_node-name IS INITIAL.
      rv_value = ``.
      RETURN.
    ENDIF.
    IF ls_node-type = zif_ayaml_types=>cs_type-null.
      rv_value = ``.
      RETURN.
    ENDIF.
    rv_value = ls_node-value.
  ENDMETHOD.

  METHOD zif_ayaml~get_integer.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.

    ls_node = get_node_internal( iv_path ).
    IF ls_node-path IS INITIAL AND ls_node-name IS INITIAL.
      rv_value = 0.
      RETURN.
    ENDIF.
    IF ls_node-type <> zif_ayaml_types=>cs_type-number.
      rv_value = 0.
      RETURN.
    ENDIF.
    rv_value = convert_to_integer( ls_node-value ).
  ENDMETHOD.

  METHOD zif_ayaml~get_number.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.

    ls_node = get_node_internal( iv_path ).
    IF ls_node-path IS INITIAL AND ls_node-name IS INITIAL.
      rv_value = 0.
      RETURN.
    ENDIF.
    IF ls_node-type <> zif_ayaml_types=>cs_type-number.
      rv_value = 0.
      RETURN.
    ENDIF.
    rv_value = convert_to_number( ls_node-value ).
  ENDMETHOD.

  METHOD zif_ayaml~get_boolean.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.

    ls_node = get_node_internal( iv_path ).
    IF ls_node-path IS INITIAL AND ls_node-name IS INITIAL.
      rv_value = abap_false.
      RETURN.
    ENDIF.
    IF ls_node-type = zif_ayaml_types=>cs_type-null.
      rv_value = abap_false.
      RETURN.
    ENDIF.
    IF ls_node-type = zif_ayaml_types=>cs_type-boolean.
      rv_value = xsdbool( ls_node-value = 'true' ).
      RETURN.
    ENDIF.
    IF ls_node-value IS NOT INITIAL.
      rv_value = abap_true.
      RETURN.
    ENDIF.
    rv_value = abap_false.
  ENDMETHOD.

  METHOD zif_ayaml~get_date.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.
    DATA lv_y    TYPE c LENGTH 4.
    DATA lv_m    TYPE c LENGTH 2.
    DATA lv_d    TYPE c LENGTH 2.

    ls_node = get_node_internal( iv_path ).
    IF ls_node-path IS INITIAL AND ls_node-name IS INITIAL.
      CLEAR rv_date.
      RETURN.
    ENDIF.
    IF     ls_node-type <> zif_ayaml_types=>cs_type-string
       AND ls_node-type <> zif_ayaml_types=>cs_type-date.
      CLEAR rv_date.
      RETURN.
    ENDIF.
    FIND FIRST OCCURRENCE OF PCRE '^(\d{4})-(\d{2})-(\d{2})(T|$)' IN ls_node-value
         SUBMATCHES lv_y lv_m lv_d.
    IF sy-subrc <> 0.
      CLEAR rv_date.
      RETURN.
    ENDIF.
    CONCATENATE lv_y lv_m lv_d INTO rv_date.
  ENDMETHOD.

  METHOD zif_ayaml~get_timestamp.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.

    ls_node = get_node_internal( iv_path ).
    IF ls_node-path IS INITIAL AND ls_node-name IS INITIAL.
      CLEAR rv_timestamp.
      RETURN.
    ENDIF.
    TRY.
        rv_timestamp = zcl_ayaml_type_utils=>parse_timestamp( ls_node-value ).
      CATCH zcx_ayaml_error.
        CLEAR rv_timestamp.
    ENDTRY.
    IF rv_timestamp IS INITIAL.
      CLEAR rv_timestamp.
    ENDIF.
  ENDMETHOD.

  METHOD zif_ayaml~get_node.
    rs_node = get_node_internal( iv_path ).
  ENDMETHOD.

  METHOD zif_ayaml~get_node_type.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.

    ls_node = zif_ayaml~get_node( iv_path ).
    rv_node_type = ls_node-type.
  ENDMETHOD.

  METHOD zif_ayaml~members.
    DATA lv_norm TYPE string.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.

    lv_norm = zcl_ayaml_path_utils=>normalize( iv_path ).
    IF lv_norm <> `/`.
      lv_norm = |{ lv_norm }/|.
    ENDIF.
    LOOP AT mt_nodes INTO ls_node USING KEY path_key WHERE path = lv_norm.
      INSERT ls_node-name INTO TABLE rt_members.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_ayaml~slice.
    DATA lv_norm   TYPE string.
    DATA lv_parent TYPE string.
    DATA lv_name   TYPE string.
    DATA lv_prefix TYPE string.
    DATA ls_node   TYPE zif_ayaml_types=>ty_s_node.
    DATA lt_new    TYPE zif_ayaml_types=>ty_t_nodes.
    DATA ls_new    TYPE zif_ayaml_types=>ty_s_node.
    DATA lv_len    TYPE i.

    lv_norm = zcl_ayaml_path_utils=>normalize( iv_path ).
    IF lv_norm = `/`.
      ri_fragment = NEW zcl_ayaml( it_nodes = mt_nodes ).
      RETURN.
    ENDIF.
    zcl_ayaml_path_utils=>split( EXPORTING iv_path = lv_norm
                                 IMPORTING ev_path = lv_parent
                                           ev_name = lv_name ).
    IF NOT line_exists( mt_nodes[ path = lv_parent
                                  name = lv_name ] ).
      RAISE EXCEPTION NEW zcx_ayaml_error( iv_msg = `Path not found` ).
    ENDIF.
    lv_prefix = |{ lv_parent }{ lv_name }/|.
    lv_len = strlen( lv_prefix ).
    LOOP AT mt_nodes INTO ls_node USING KEY path_key WHERE path CP |{ lv_prefix }*|.
      IF ls_node-path = lv_prefix.
        ls_new-path = `/`.
      ELSE.
        ls_new-path = |/{ substring( val = ls_node-path
                                     off = lv_len ) }|.
      ENDIF.
      ls_new-name  = ls_node-name.
      ls_new-type  = ls_node-type.
      ls_new-value = ls_node-value.
      ls_new-index = ls_node-index.
      ls_new-order = ls_node-order.
      INSERT ls_new INTO TABLE lt_new.
    ENDLOOP.
    ri_fragment = NEW zcl_ayaml( it_nodes = lt_new ).
  ENDMETHOD.

  METHOD zif_ayaml~clone.
    ri_ayaml = NEW zcl_ayaml( it_nodes = mt_nodes ).
  ENDMETHOD.

  METHOD zif_ayaml~clear.
    CLEAR mt_nodes.
    ri_self = me.
  ENDMETHOD.

  METHOD zif_ayaml~set.
    DATA lv_parent TYPE string.
    DATA lv_name   TYPE string.
    DATA lv_type   TYPE zif_ayaml_types=>ty_node_type.
    DATA lv_value  TYPE string.
    DATA ls_node   TYPE zif_ayaml_types=>ty_s_node.
    DATA lv_order  TYPE i.
    DATA lv_norm   TYPE string.
    DATA lo_descr  TYPE REF TO cl_abap_typedescr.

    IF     iv_node_type IS NOT INITIAL
       AND iv_node_type <> zif_ayaml_types=>cs_type-boolean
       AND iv_node_type <> zif_ayaml_types=>cs_type-null
       AND iv_node_type <> zif_ayaml_types=>cs_type-number
       AND iv_node_type <> zif_ayaml_types=>cs_type-string
       AND iv_node_type <> zif_ayaml_types=>cs_type-date.
      RAISE EXCEPTION NEW zcx_ayaml_error( iv_msg = |Unexpected type { iv_node_type }| ).
    ENDIF.

    IF iv_ignore_empty = abap_true AND iv_val IS INITIAL AND iv_node_type IS INITIAL.
      ri_self = me.
      RETURN.
    ENDIF.
    TRY.
        lo_descr = cl_abap_typedescr=>describe_by_data( iv_val ).
        IF lo_descr->kind = cl_abap_typedescr=>kind_struct OR lo_descr->kind = cl_abap_typedescr=>kind_table.
          set_recursive( iv_path = iv_path
                         iv_val  = iv_val ).
          ri_self = me.
          RETURN.
        ENDIF.
      CATCH cx_root.
    ENDTRY.
    IF iv_node_type IS NOT INITIAL.
      lv_type = iv_node_type.
    ELSE.
      lv_type = zcl_ayaml_type_utils=>detect_type( iv_val ).
    ENDIF.
    lv_value = zcl_ayaml_type_utils=>to_string( iv_val  = iv_val
                                                iv_type = lv_type ).
    lv_norm = zcl_ayaml_path_utils=>normalize( iv_path ).
    zcl_ayaml_path_utils=>split( EXPORTING iv_path = lv_norm
                                 IMPORTING ev_path = lv_parent
                                           ev_name = lv_name ).
    IF lv_name IS INITIAL.
      RAISE EXCEPTION NEW zcx_ayaml_error( iv_msg = `Invalid path` ).
    ENDIF.
    ensure_path_exists( lv_norm ).
    READ TABLE mt_nodes WITH KEY path = lv_parent
                                 name = lv_name INTO ls_node.
    IF sy-subrc = 0.
      ls_node-type  = lv_type.
      ls_node-value = lv_value.
      MODIFY TABLE mt_nodes FROM ls_node.
    ELSE.
      lv_order = lines( mt_nodes ) + 1.
      CLEAR ls_node.
      ls_node-path  = lv_parent.
      ls_node-name  = lv_name.
      ls_node-type  = lv_type.
      ls_node-value = lv_value.
      ls_node-index = 0.
      ls_node-order = lv_order.
      INSERT ls_node INTO TABLE mt_nodes.
    ENDIF.
    ri_self = me.
  ENDMETHOD.

  METHOD zif_ayaml~set_boolean.
    DATA lv_val TYPE string.

    IF iv_val IS INITIAL.
      lv_val = `false`.
    ELSE.
      lv_val = `true`.
    ENDIF.
    set_typed( iv_path = iv_path
               iv_val  = lv_val
               iv_type = zif_ayaml_types=>cs_type-boolean ).
    ri_self = me.
  ENDMETHOD.

  METHOD zif_ayaml~set_string.
    set_typed( iv_path = iv_path
               iv_val  = iv_val
               iv_type = zif_ayaml_types=>cs_type-string ).
    ri_self = me.
  ENDMETHOD.

  METHOD zif_ayaml~set_integer.
    set_typed( iv_path = iv_path
               iv_val  = iv_val
               iv_type = zif_ayaml_types=>cs_type-number ).
    ri_self = me.
  ENDMETHOD.

  METHOD zif_ayaml~set_number.
    set_typed( iv_path = iv_path
               iv_val  = iv_val
               iv_type = zif_ayaml_types=>cs_type-number ).
    ri_self = me.
  ENDMETHOD.

  METHOD zif_ayaml~set_date.
    DATA lv_str TYPE string.

    lv_str = zcl_ayaml_type_utils=>format_date( iv_val ).
    set_typed( iv_path = iv_path
               iv_val  = lv_str
               iv_type = zif_ayaml_types=>cs_type-date ).
    ri_self = me.
  ENDMETHOD.

  METHOD zif_ayaml~set_timestamp.
    DATA lv_str TYPE string.

    lv_str = zcl_ayaml_type_utils=>format_timestamp( iv_val ).
    set_typed( iv_path = iv_path
               iv_val  = lv_str
               iv_type = zif_ayaml_types=>cs_type-string ).
    ri_self = me.
  ENDMETHOD.

  METHOD zif_ayaml~set_null.
    set_typed( iv_path = iv_path
               iv_val  = `null`
               iv_type = zif_ayaml_types=>cs_type-null ).
    ri_self = me.
  ENDMETHOD.

  METHOD zif_ayaml~delete.
    DATA lv_norm   TYPE string.
    DATA lv_parent TYPE string.
    DATA lv_name   TYPE string.
    DATA lv_prefix TYPE string.
    DATA lt_keep   TYPE zif_ayaml_types=>ty_t_nodes.
    DATA ls_node   TYPE zif_ayaml_types=>ty_s_node.

    lv_norm = zcl_ayaml_path_utils=>normalize( iv_path ).
    zcl_ayaml_path_utils=>split( EXPORTING iv_path = lv_norm
                                 IMPORTING ev_path = lv_parent
                                           ev_name = lv_name ).
    lv_prefix = |{ lv_parent }{ lv_name }/|.
    LOOP AT mt_nodes INTO ls_node.
      IF ls_node-path = lv_parent AND ls_node-name = lv_name.
        CONTINUE.
      ENDIF.
      IF ls_node-path CP |{ lv_prefix }*|.
        CONTINUE.
      ENDIF.
      INSERT ls_node INTO TABLE lt_keep.
    ENDLOOP.
    mt_nodes = lt_keep.
    ri_self = me.
  ENDMETHOD.

  METHOD zif_ayaml~touch_array.
    DATA lv_parent TYPE string.
    DATA lv_name   TYPE string.
    DATA ls_node   TYPE zif_ayaml_types=>ty_s_node.
    DATA lv_norm   TYPE string.
    DATA lt_keep   TYPE zif_ayaml_types=>ty_t_nodes.

    lv_norm = zcl_ayaml_path_utils=>normalize( iv_path ).
    zcl_ayaml_path_utils=>split( EXPORTING iv_path = lv_norm
                                 IMPORTING ev_path = lv_parent
                                           ev_name = lv_name ).
    READ TABLE mt_nodes WITH KEY path = lv_parent
                                 name = lv_name INTO ls_node.
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

  METHOD zif_ayaml~push.
    DATA lv_parent TYPE string.
    DATA lv_name   TYPE string.
    DATA ls_seq    TYPE zif_ayaml_types=>ty_s_node.
    DATA ls_item   TYPE zif_ayaml_types=>ty_s_node.
    DATA lv_type   TYPE zif_ayaml_types=>ty_node_type.
    DATA lv_value  TYPE string.
    DATA lv_index  TYPE i.
    DATA lv_norm   TYPE string.

    lv_norm = zcl_ayaml_path_utils=>normalize( iv_path ).
    zcl_ayaml_path_utils=>split( EXPORTING iv_path = lv_norm
                                 IMPORTING ev_path = lv_parent
                                           ev_name = lv_name ).
    READ TABLE mt_nodes WITH KEY path = lv_parent
                                 name = lv_name INTO ls_seq.
    IF sy-subrc <> 0 OR ls_seq-type <> zif_ayaml_types=>cs_type-sequence.
      RAISE EXCEPTION NEW zcx_ayaml_error( iv_msg = `Path is not an array` ).
    ENDIF.
    lv_type = zcl_ayaml_type_utils=>detect_type( iv_val ).
    lv_value = zcl_ayaml_type_utils=>to_string( iv_val  = iv_val
                                                iv_type = lv_type ).
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
        DATA(lo_descr) = cl_abap_typedescr=>describe_by_data( iv_val ).
        IF lo_descr->kind = cl_abap_typedescr=>kind_struct OR lo_descr->kind = cl_abap_typedescr=>kind_table.
          DATA(lv_item_path) = |{ lv_norm }/{ lv_index }|.
          DELETE TABLE mt_nodes FROM ls_item.
          set_recursive( iv_path = lv_item_path
                         iv_val  = iv_val ).
          READ TABLE mt_nodes WITH KEY path = |{ lv_norm }/|
                                       name = |{ lv_index }| INTO ls_item.
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

  METHOD zif_ayaml~stringify.
    IF mt_nodes IS INITIAL.
      rv_yaml = ``.
      RETURN.
    ENDIF.
    rv_yaml = zcl_ayaml_serializer=>stringify( it_nodes  = mt_nodes
                                               iv_indent = iv_indent ).
  ENDMETHOD.
ENDCLASS.
