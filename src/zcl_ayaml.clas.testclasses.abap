CLASS ltcl_ayaml_master_suite DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    DATA mo_cut TYPE REF TO zif_ayaml.

    METHODS setup.
    METHODS test_empty_and_exists       FOR TESTING RAISING cx_static_check.
    METHODS test_ajson_readers          FOR TESTING RAISING cx_static_check.
    METHODS test_date_handling          FOR TESTING RAISING cx_static_check.
    METHODS test_null_handling          FOR TESTING RAISING cx_static_check.
    METHODS test_auto_path_creation     FOR TESTING RAISING cx_static_check.
    METHODS test_ignore_empty_logic     FOR TESTING RAISING cx_static_check.
    METHODS test_escaping               FOR TESTING RAISING cx_static_check.
    METHODS test_explicit_type_override FOR TESTING RAISING cx_static_check.
    METHODS test_new_features           FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltcl_ayaml_master_suite IMPLEMENTATION.
  METHOD setup.
    mo_cut = zcl_ayaml=>create_empty( ).
  ENDMETHOD.

  METHOD test_empty_and_exists.
    cl_abap_unit_assert=>assert_true( mo_cut->is_empty( ) ).

    mo_cut->set( iv_path = '/status'
                 iv_val  = 'ok' ).
    cl_abap_unit_assert=>assert_false( mo_cut->is_empty( ) ).
    cl_abap_unit_assert=>assert_true( mo_cut->exists( '/status' ) ).
    cl_abap_unit_assert=>assert_false( mo_cut->exists( '/missing' ) ).
  ENDMETHOD.

  METHOD test_ajson_readers.
    DATA lv_yaml TYPE string.

    lv_yaml =
      |success: 1\n| &&
      |payload:\n| &&
      |  bool: true\n| &&
      |  false: false|.

    DATA(li_r) = zcl_ayaml=>parse( lv_yaml ).

    cl_abap_unit_assert=>assert_equals( exp = '1'
                                        act = li_r->get( '/success' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = li_r->get_integer( '/success' ) ).
    cl_abap_unit_assert=>assert_true( li_r->get_boolean( '/success' ) ).

    cl_abap_unit_assert=>assert_equals( exp = 'true'
                                        act = li_r->get( '/payload/bool' ) ).
    cl_abap_unit_assert=>assert_true( li_r->get_boolean( '/payload/bool' ) ).

    cl_abap_unit_assert=>assert_equals( exp = 'false'
                                        act = li_r->get( '/payload/false' ) ).
    cl_abap_unit_assert=>assert_false( li_r->get_boolean( '/payload/false' ) ).
  ENDMETHOD.

  METHOD test_date_handling.
    DATA lv_yaml     TYPE string.
    DATA lv_exp_date TYPE d VALUE '20200728'.

    lv_yaml =
      |payload:\n| &&
      |  date: 2020-07-28|.

    DATA(li_r) = zcl_ayaml=>parse( lv_yaml ).

    cl_abap_unit_assert=>assert_equals( exp = '2020-07-28'
                                        act = li_r->get( '/payload/date' ) ).
    cl_abap_unit_assert=>assert_equals( exp = lv_exp_date
                                        act = li_r->get_date( '/payload/date' ) ).
  ENDMETHOD.

  METHOD test_null_handling.
    DATA lv_yaml TYPE string.

    lv_yaml =
      |payload:\n| &&
      |  null_val: null|.

    DATA(li_r) = zcl_ayaml=>parse( lv_yaml ).

    cl_abap_unit_assert=>assert_equals( exp = 'null'
                                        act = li_r->get( '/payload/null_val' ) ).
    cl_abap_unit_assert=>assert_equals( exp = ''
                                        act = li_r->get_string( '/payload/null_val' ) ).
  ENDMETHOD.

  METHOD test_auto_path_creation.
    mo_cut->set( iv_path = '/a/b/num'
                 iv_val  = 123 ).
    mo_cut->set( iv_path = '/a/b/str'
                 iv_val  = 'hello' ).
    mo_cut->set( iv_path = '/a/b/bool'
                 iv_val  = abap_true ).

    cl_abap_unit_assert=>assert_true( mo_cut->exists( '/a' ) ).
    cl_abap_unit_assert=>assert_true( mo_cut->exists( '/a/b' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 123
                                        act = mo_cut->get_integer( '/a/b/num' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'hello'
                                        act = mo_cut->get( '/a/b/str' ) ).
    cl_abap_unit_assert=>assert_true( mo_cut->get_boolean( '/a/b/bool' ) ).
  ENDMETHOD.

  METHOD test_ignore_empty_logic.
    mo_cut->set( iv_path = '/empty_bool'
                 iv_val  = abap_false ).
    mo_cut->set( iv_path = '/empty_num'
                 iv_val  = 0 ).
    cl_abap_unit_assert=>assert_false( mo_cut->exists( '/empty_bool' ) ).
    cl_abap_unit_assert=>assert_false( mo_cut->exists( '/empty_num' ) ).

    mo_cut->set( iv_ignore_empty = abap_false
                 iv_path         = '/keep_bool'
                 iv_val          = abap_false ).
    mo_cut->set( iv_ignore_empty = abap_false
                 iv_path         = '/keep_num'
                 iv_val          = 0 ).

    cl_abap_unit_assert=>assert_true( mo_cut->exists( '/keep_bool' ) ).
    cl_abap_unit_assert=>assert_false( mo_cut->get_boolean( '/keep_bool' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = mo_cut->get_integer( '/keep_num' ) ).
  ENDMETHOD.

  METHOD test_escaping.
    DATA lv_yaml  TYPE string.
    DATA lv_input TYPE string.

    lv_input = |escaping"\\|.
    mo_cut->set( iv_path = '/payload/str'
                 iv_val  = lv_input ).
    lv_yaml = mo_cut->stringify( ).

    cl_abap_unit_assert=>assert_char_cp( exp = '*escaping\"\\*'
                                         act = lv_yaml ).
  ENDMETHOD.

  METHOD test_explicit_type_override.
    DATA ls_node TYPE zif_ayaml_types=>ty_s_node.

    mo_cut->set( iv_path      = '/val'
                 iv_val       = '0'
                 iv_node_type = zif_ayaml_types=>cs_type-number ).

    ls_node = mo_cut->get_node( '/val' ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ayaml_types=>cs_type-number
                                        act = ls_node-type ).
    cl_abap_unit_assert=>assert_equals( exp = '0'
                                        act = ls_node-value ).
  ENDMETHOD.

  METHOD test_new_features.
    DATA lv_yaml  TYPE string.
    DATA li_clone TYPE REF TO zif_ayaml.
    DATA lv_num   TYPE f.
    DATA lv_f     TYPE f VALUE '3.14'.

    mo_cut->set( iv_path = '/num'
                 iv_val  = lv_f ).

    lv_num = mo_cut->get_number( '/num' ).
    cl_abap_unit_assert=>assert_equals( exp = CONV f( '3.14' )
                                        act = lv_num ).

    cl_abap_unit_assert=>assert_equals( exp = zif_ayaml_types=>cs_type-number
                                        act = mo_cut->get_node_type( '/num' ) ).

    mo_cut->touch_array( '/arr' ).
    mo_cut->push( iv_path = '/arr'
                  iv_val  = 'abc' ).
    mo_cut->push( iv_path = '/arr'
                  iv_val  = 'def' ).

    lv_yaml = mo_cut->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*arr:*'
                                         act = lv_yaml ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*- abc*'
                                         act = lv_yaml ).

    li_clone = mo_cut->clone( ).
    cl_abap_unit_assert=>assert_true( li_clone->exists( '/arr' ) ).

    mo_cut->clear( ).
    cl_abap_unit_assert=>assert_true( mo_cut->is_empty( ) ).

    mo_cut->set_boolean( iv_path = '/b1'
                         iv_val  = abap_true ).
    mo_cut->set_boolean( iv_path = '/b2'
                         iv_val  = abap_false ).
    cl_abap_unit_assert=>assert_true( mo_cut->get_boolean( '/b1' ) ).
    cl_abap_unit_assert=>assert_false( mo_cut->get_boolean( '/b2' ) ).

    mo_cut->set_null( '/n' ).
    cl_abap_unit_assert=>assert_equals( exp = 'null'
                                        act = mo_cut->get( '/n' ) ).
  ENDMETHOD.
ENDCLASS.


CLASS ltcl_ayaml_extended DEFINITION FINAL FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    DATA mo_cut TYPE REF TO zif_ayaml.

    METHODS setup.
    METHODS test_members_and_delete    FOR TESTING RAISING cx_static_check.
    METHODS test_slice_and_clone_indep FOR TESTING RAISING cx_static_check.
    METHODS test_touch_array_struct    FOR TESTING RAISING cx_static_check.
    METHODS test_path_utils            FOR TESTING RAISING cx_static_check.
    METHODS test_string_utils          FOR TESTING RAISING cx_static_check.
    METHODS test_type_utils_date_time  FOR TESTING RAISING cx_static_check.
    METHODS test_parser_inline_seq     FOR TESTING RAISING cx_static_check.
    METHODS test_parser_seq_mapping    FOR TESTING RAISING cx_static_check.
    METHODS test_serializer_indent     FOR TESTING RAISING cx_static_check.
    METHODS test_ty_t_string_empty_key FOR TESTING RAISING cx_static_check.
    METHODS test_getters_edge_cases    FOR TESTING RAISING cx_static_check.
    METHODS test_set_recursive         FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltcl_ayaml_extended IMPLEMENTATION.
  METHOD setup.
    mo_cut = zcl_ayaml=>create_empty( ).
  ENDMETHOD.

  METHOD test_members_and_delete.
    DATA lt_members TYPE zif_ayaml_types=>ty_t_string.

    mo_cut->set( iv_path = '/a/x'
                 iv_val  = '1' ).
    mo_cut->set( iv_path = '/a/y'
                 iv_val  = '2' ).
    mo_cut->set( iv_path = '/a/z'
                 iv_val  = '3' ).
    lt_members = mo_cut->members( '/a' ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lines( lt_members ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( lt_members[ table_line = 'x' ] ) ) ).
    mo_cut->delete( '/a/y' ).
    cl_abap_unit_assert=>assert_false( mo_cut->exists( '/a/y' ) ).
    lt_members = mo_cut->members( '/a' ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( lt_members ) ).
    mo_cut->delete( '/a' ).
    cl_abap_unit_assert=>assert_false( mo_cut->exists( '/a/x' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = lines( mo_cut->members( '/' ) ) ).
  ENDMETHOD.

  METHOD test_slice_and_clone_indep.
    DATA li_slice TYPE REF TO zif_ayaml.
    DATA li_clone TYPE REF TO zif_ayaml.

    mo_cut->set( iv_path = '/root/a'
                 iv_val  = 'val_a' ).
    mo_cut->set( iv_path = '/root/b/c'
                 iv_val  = 'val_c' ).
    mo_cut->set( iv_path = '/root/b/d'
                 iv_val  = 123 ).
    li_slice = mo_cut->slice( '/root/b' ).
    cl_abap_unit_assert=>assert_true( li_slice->exists( '/c' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'val_c'
                                        act = li_slice->get( '/c' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 123
                                        act = li_slice->get_integer( '/d' ) ).
    cl_abap_unit_assert=>assert_false( li_slice->exists( '/a' ) ).
    li_clone = mo_cut->clone( ).
    li_clone->set( iv_path = '/root/a'
                   iv_val  = 'changed' ).
    cl_abap_unit_assert=>assert_equals( exp = 'val_a'
                                        act = mo_cut->get( '/root/a' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'changed'
                                        act = li_clone->get( '/root/a' ) ).
  ENDMETHOD.

  METHOD test_touch_array_struct.
    TYPES: BEGIN OF ty_s_test,
             field1 TYPE string,
             field2 TYPE i,
           END OF ty_s_test.
    DATA ls_struct TYPE ty_s_test.
    DATA lv_yaml   TYPE string.

    ls_struct-field1 = 'hello'.
    ls_struct-field2 = 42.
    mo_cut->set( iv_path = '/struct'
                 iv_val  = ls_struct ).
    cl_abap_unit_assert=>assert_equals( exp = 'hello'
                                        act = mo_cut->get( '/struct/field1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 42
                                        act = mo_cut->get_integer( '/struct/field2' ) ).
    mo_cut->touch_array( '/arr2' ).
    mo_cut->push( iv_path = '/arr2'
                  iv_val  = ls_struct ).
    lv_yaml = mo_cut->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*arr2:*'
                                         act = lv_yaml ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*field1:*'
                                         act = lv_yaml ).
    mo_cut->touch_array( iv_path  = '/empty_arr'
                         iv_clear = abap_true ).
    lv_yaml = mo_cut->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*empty_arr:*[]*'
                                         act = lv_yaml ).
  ENDMETHOD.

  METHOD test_path_utils.
    DATA lv_norm      TYPE string.
    DATA lv_parent    TYPE string.
    DATA lv_name      TYPE string.
    DATA lv_built     TYPE string.
    DATA lv_seq_check TYPE abap_bool.

    lv_norm = zcl_ayaml_path_utils=>normalize( 'a/b/' ).
    cl_abap_unit_assert=>assert_equals( exp = '/a/b'
                                        act = lv_norm ).
    lv_norm = zcl_ayaml_path_utils=>normalize( '' ).
    cl_abap_unit_assert=>assert_equals( exp = '/'
                                        act = lv_norm ).
    zcl_ayaml_path_utils=>split( EXPORTING iv_path = '/a/b/c'
                                 IMPORTING ev_path = lv_parent
                                           ev_name = lv_name ).
    cl_abap_unit_assert=>assert_equals( exp = '/a/b/'
                                        act = lv_parent ).
    cl_abap_unit_assert=>assert_equals( exp = 'c'
                                        act = lv_name ).
    zcl_ayaml_path_utils=>split( EXPORTING iv_path = '/'
                                 IMPORTING ev_path = lv_parent
                                           ev_name = lv_name ).
    cl_abap_unit_assert=>assert_equals( exp = '/'
                                        act = lv_parent ).
    lv_built = zcl_ayaml_path_utils=>build_path( iv_parent = '/a'
                                                 iv_name   = 'b' ).
    cl_abap_unit_assert=>assert_equals( exp = '/a/b'
                                        act = lv_built ).
    lv_built = zcl_ayaml_path_utils=>build_path( iv_parent = '/'
                                                 iv_name   = 'root' ).
    cl_abap_unit_assert=>assert_equals( exp = '/root'
                                        act = lv_built ).
    mo_cut->touch_array( '/myseq' ).

    mo_cut->set( iv_path = '/tmp'
                 iv_val  = 'x' ).
    TRY.
        mo_cut->push( iv_path = '/myseq'
                      iv_val  = 'val1' ).
        cl_abap_unit_assert=>assert_true( abap_true ).
      CATCH zcx_ayaml_error.
        cl_abap_unit_assert=>fail( 'push on sequence failed' ).
    ENDTRY.
    lv_seq_check = zcl_ayaml_path_utils=>is_sequence_path( it_nodes = VALUE #( )
                                                           iv_path  = '/' ).
    cl_abap_unit_assert=>assert_false( lv_seq_check ).
  ENDMETHOD.

  METHOD test_string_utils.
    DATA lv_esc      TYPE string.
    DATA lv_unesc    TYPE string.
    DATA lv_stripped TYPE string.

    lv_esc = zcl_ayaml_string_utils=>escape_text( |a"b| ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*\"*'
                                         act = lv_esc ).
    lv_esc = zcl_ayaml_string_utils=>escape_text( 'a\b' ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*\\*'
                                         act = lv_esc ).
    lv_esc = zcl_ayaml_string_utils=>escape_text( 'a"b\c' ).
    lv_unesc = zcl_ayaml_string_utils=>unescape( lv_esc ).
    cl_abap_unit_assert=>assert_equals( exp = 'a"b\c'
                                        act = lv_unesc ).
    lv_stripped = zcl_ayaml_string_utils=>strip_quotes( |"hello"| ).
    cl_abap_unit_assert=>assert_equals( exp = 'hello'
                                        act = lv_stripped ).
    lv_stripped = zcl_ayaml_string_utils=>strip_quotes( |'it''s'| ).
    cl_abap_unit_assert=>assert_equals( exp = |it's|
                                        act = lv_stripped ).
    cl_abap_unit_assert=>assert_true( zcl_ayaml_string_utils=>is_plain( |simple| ) ).
    cl_abap_unit_assert=>assert_false( zcl_ayaml_string_utils=>is_plain( |a:b| ) ).
    cl_abap_unit_assert=>assert_false( zcl_ayaml_string_utils=>is_plain( | true | ) ).
    cl_abap_unit_assert=>assert_false( zcl_ayaml_string_utils=>is_plain( |null| ) ).
  ENDMETHOD.

  METHOD test_type_utils_date_time.
    DATA lv_date    TYPE d VALUE '20240115'.
    DATA lv_str     TYPE string.
    DATA lv_back    TYPE d.
    DATA lv_ts      TYPE timestamp.
    DATA lv_ts_str  TYPE string.
    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA lv_ts_back TYPE timestamp.
    DATA lv_type    TYPE zif_ayaml_types=>ty_node_type.

    lv_str = zcl_ayaml_type_utils=>format_date( lv_date ).
    cl_abap_unit_assert=>assert_equals( exp = '2024-01-15'
                                        act = lv_str ).
    lv_back = zcl_ayaml_type_utils=>parse_date( '2024-01-15' ).
    cl_abap_unit_assert=>assert_equals( exp = lv_date
                                        act = lv_back ).
    lv_back = zcl_ayaml_type_utils=>parse_date( '' ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_back IS INITIAL ) ).
    GET TIME STAMP FIELD lv_ts.
    lv_ts_str = zcl_ayaml_type_utils=>format_timestamp( lv_ts ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*T*:*:*Z*'
                                         act = lv_ts_str ).
    lv_ts_back = zcl_ayaml_type_utils=>parse_timestamp( lv_ts_str ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*202*'
                                         act = lv_ts_str ).

    lv_type = zcl_ayaml_type_utils=>detect_type( 123 ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ayaml_types=>cs_type-number
                                        act = lv_type ).
    lv_type = zcl_ayaml_type_utils=>detect_type( 'abc' ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ayaml_types=>cs_type-string
                                        act = lv_type ).
    lv_type = zcl_ayaml_type_utils=>detect_type( abap_true ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ayaml_types=>cs_type-boolean
                                        act = lv_type ).
  ENDMETHOD.

  METHOD test_parser_inline_seq.
    DATA lv_yaml TYPE string.

    lv_yaml = |seq: [a, b, 123]\nplain: hello|.
    DATA(li_doc) = zcl_ayaml=>parse( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 'a'
                                        act = li_doc->get( '/seq/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'b'
                                        act = li_doc->get( '/seq/2' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 123
                                        act = li_doc->get_integer( '/seq/3' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'hello'
                                        act = li_doc->get( '/plain' ) ).
    lv_yaml = |mylist:\n  - first\n  - second\n  - 3|.
    li_doc = zcl_ayaml=>parse( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 'first'
                                        act = li_doc->get( '/mylist/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'second'
                                        act = li_doc->get( '/mylist/2' ) ).
  ENDMETHOD.

  METHOD test_parser_seq_mapping.
    DATA lv_yaml TYPE string.

    lv_yaml = |items:\n  - name: alice\n  - name: bob|.
    DATA(li_doc) = zcl_ayaml=>parse( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 'alice'
                                        act = li_doc->get( '/items/1/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'bob'
                                        act = li_doc->get( '/items/2/name' ) ).
    lv_yaml = zcl_ayaml=>parse( |a: 1| )->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*a: 1*'
                                         act = lv_yaml ).
  ENDMETHOD.

  METHOD test_serializer_indent.
    DATA lv_yaml TYPE string.

    mo_cut->set( iv_path = '/a/b'
                 iv_val  = 'v' ).
    lv_yaml = mo_cut->stringify( 1 ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*a:*'
                                         act = lv_yaml ).
    mo_cut->clear( ).
    lv_yaml = mo_cut->stringify( ).
    cl_abap_unit_assert=>assert_equals( exp = ''
                                        act = lv_yaml ).
    mo_cut->touch_array( '/arr' ).
    lv_yaml = mo_cut->stringify( ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*arr: []*'
                                         act = lv_yaml ).
  ENDMETHOD.

  METHOD test_ty_t_string_empty_key.
    DATA lt_tab TYPE zif_ayaml_types=>ty_t_string.

    INSERT `a` INTO TABLE lt_tab.
    INSERT `a` INTO TABLE lt_tab.
    INSERT `b` INTO TABLE lt_tab.
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lines( lt_tab ) ).
    CLEAR lt_tab.
    lt_tab = VALUE zif_ayaml_types=>ty_t_string( ( `x` ) ( `y` ) ( `x` ) ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lines( lt_tab ) ).
  ENDMETHOD.

  METHOD test_getters_edge_cases.
    mo_cut->set( iv_path = '/numstr'
                 iv_val  = 'not_a_num' ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = mo_cut->get_integer( '/numstr' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = CONV i( mo_cut->get_number( '/numstr' ) ) ).
    mo_cut->set( iv_path = '/bool1'
                 iv_val  = 'X' ).
    cl_abap_unit_assert=>assert_true( mo_cut->get_boolean( '/bool1' ) ).
    cl_abap_unit_assert=>assert_false( mo_cut->get_boolean( '/nonexist' ) ).
    cl_abap_unit_assert=>assert_equals( exp = ''
                                        act = mo_cut->get( '/nonexist' ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( mo_cut->get_node( '/nonexist' ) IS INITIAL ) ).
    mo_cut->set( iv_path = '/a/b/c'
                 iv_val  = 'val' ).
    cl_abap_unit_assert=>assert_true( mo_cut->exists( '/a/b/c/' ) ).
    cl_abap_unit_assert=>assert_true( mo_cut->exists( 'a/b/c' ) ).
  ENDMETHOD.

  METHOD test_set_recursive.
    TYPES: BEGIN OF ty_s_inner,
             inner TYPE string,
           END OF ty_s_inner.
    TYPES: BEGIN OF ty_s_outer,
             outer TYPE ty_s_inner,
             num   TYPE i,
           END OF ty_s_outer.
    DATA ls_outer TYPE ty_s_outer.
    DATA lt_tab   TYPE zif_ayaml_types=>ty_t_string.

    ls_outer-outer-inner = 'deep'.
    ls_outer-num = 7.
    mo_cut->set( iv_path = '/deep'
                 iv_val  = ls_outer ).
    cl_abap_unit_assert=>assert_equals( exp = 'deep'
                                        act = mo_cut->get( '/deep/outer/inner' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 7
                                        act = mo_cut->get_integer( '/deep/num' ) ).
    lt_tab = VALUE zif_ayaml_types=>ty_t_string( ( `one` ) ( `two` ) ).
    mo_cut->set( iv_path = '/mytab'
                 iv_val  = lt_tab ).
    cl_abap_unit_assert=>assert_equals( exp = 'one'
                                        act = mo_cut->get( '/mytab/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'two'
                                        act = mo_cut->get( '/mytab/2' ) ).
  ENDMETHOD.
ENDCLASS.


CLASS ltcl_ayaml_advanced_parser DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS test_odd_indentation FOR TESTING RAISING cx_static_check.
    METHODS test_multiline_block_scalars FOR TESTING RAISING cx_static_check.
    METHODS test_flow_mapping_and_sequence FOR TESTING RAISING cx_static_check.
    METHODS test_anchors_and_merge FOR TESTING RAISING cx_static_check.
    METHODS test_inline_comments FOR TESTING RAISING cx_static_check.
    METHODS test_strict_syntax_errors FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltcl_ayaml_advanced_parser IMPLEMENTATION.

  METHOD test_odd_indentation.
    DATA lv_yaml TYPE string.
    lv_yaml =
      |root:\n| &&
      |   child1: value1\n| &&
      |   child2:\n| &&
      |      deep: deep_val|.

    DATA(li_yaml) = zcl_ayaml=>parse( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 'value1'
                                        act = li_yaml->get( '/root/child1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'deep_val'
                                        act = li_yaml->get( '/root/child2/deep' ) ).
  ENDMETHOD.

  METHOD test_multiline_block_scalars.
    DATA lv_yaml TYPE string.
    lv_yaml =
      `lit: |` && cl_abap_char_utilities=>newline &&
      `  hello` && cl_abap_char_utilities=>newline &&
      `  world` && cl_abap_char_utilities=>newline &&
      `fold: >` && cl_abap_char_utilities=>newline &&
      `  hello` && cl_abap_char_utilities=>newline &&
      `  world`.

    DATA(li_yaml) = zcl_ayaml=>parse( lv_yaml ).
    DATA(lv_lit) = li_yaml->get( '/lit' ).
    DATA(lv_fold) = li_yaml->get( '/fold' ).

    cl_abap_unit_assert=>assert_true( xsdbool( lv_lit CS 'hello' AND lv_lit CS 'world' ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_fold CS 'hello world' ) ).
  ENDMETHOD.

  METHOD test_flow_mapping_and_sequence.
    DATA lv_yaml TYPE string.
    lv_yaml =
      `server: { host: localhost, port: 8080 }` && cl_abap_char_utilities=>newline &&
      `items: [ alpha, beta, gamma ]`.

    DATA(li_yaml) = zcl_ayaml=>parse( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 'localhost'
                                        act = li_yaml->get( '/server/host' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 8080
                                        act = li_yaml->get_integer( '/server/port' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'alpha'
                                        act = li_yaml->get( '/items/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'gamma'
                                        act = li_yaml->get( '/items/3' ) ).
  ENDMETHOD.

  METHOD test_anchors_and_merge.
    DATA lv_yaml TYPE string.
    lv_yaml =
      |default: &base\n| &&
      |  host: db.local\n| &&
      |  port: 5432\n| &&
      |dev:\n| &&
      |  <<: *base\n| &&
      |  database: my_dev_db|.

    DATA(li_yaml) = zcl_ayaml=>parse( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 'db.local'
                                        act = li_yaml->get( '/dev/host' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 5432
                                        act = li_yaml->get_integer( '/dev/port' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'my_dev_db'
                                        act = li_yaml->get( '/dev/database' ) ).
  ENDMETHOD.

  METHOD test_inline_comments.
    DATA lv_yaml TYPE string.
    lv_yaml =
      |# Top level comment\n| &&
      |key1: val1 # inline comment\n| &&
      |key2: val2|.

    DATA(li_yaml) = zcl_ayaml=>parse( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 'val1'
                                        act = li_yaml->get( '/key1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'val2'
                                        act = li_yaml->get( '/key2' ) ).
  ENDMETHOD.

  METHOD test_strict_syntax_errors.
    TRY.
        zcl_ayaml=>parse( `'unclosed string` ).
        cl_abap_unit_assert=>fail( 'Expected syntax error for unclosed single quote' ).
      CATCH zcx_ayaml_error.
        " expected
    ENDTRY.

    TRY.
        zcl_ayaml=>parse( `key: *undefined_alias` ).
        cl_abap_unit_assert=>fail( 'Expected error for undefined alias' ).
      CATCH zcx_ayaml_error.
        " expected
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
