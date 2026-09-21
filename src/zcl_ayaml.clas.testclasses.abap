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

    mo_cut->set( iv_path  = '/status'
                 iv_value = 'ok' ).
    cl_abap_unit_assert=>assert_false( mo_cut->is_empty( ) ).
    cl_abap_unit_assert=>assert_true( mo_cut->exists( '/status' ) ).
    cl_abap_unit_assert=>assert_false( mo_cut->exists( '/missing' ) ).
  ENDMETHOD.

  METHOD test_ajson_readers.
    DATA lv_yaml TYPE string.
    DATA lo_r    TYPE REF TO zif_ayaml.

    lv_yaml =
      |success: 1\n| &&
      |payload:\n| &&
      |  bool: true\n| &&
      |  false: false|.

    lo_r = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_equals( exp = '1'
                                        act = lo_r->get( '/success' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lo_r->get_integer( '/success' ) ).
    cl_abap_unit_assert=>assert_true( lo_r->get_boolean( '/success' ) ).

    cl_abap_unit_assert=>assert_equals( exp = 'true'
                                        act = lo_r->get( '/payload/bool' ) ).
    cl_abap_unit_assert=>assert_true( lo_r->get_boolean( '/payload/bool' ) ).

    cl_abap_unit_assert=>assert_equals( exp = 'false'
                                        act = lo_r->get( '/payload/false' ) ).
    cl_abap_unit_assert=>assert_false( lo_r->get_boolean( '/payload/false' ) ).
  ENDMETHOD.

  METHOD test_date_handling.
    DATA lv_exp_date TYPE d VALUE '20200728'.

    DATA lv_yaml     TYPE string.
    DATA lo_r        TYPE REF TO zif_ayaml.

    lv_yaml =
      |payload:\n| &&
      |  date: 2020-07-28|.

    lo_r = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_equals( exp = '2020-07-28'
                                        act = lo_r->get( '/payload/date' ) ).
    cl_abap_unit_assert=>assert_equals( exp = lv_exp_date
                                        act = lo_r->get_date( '/payload/date' ) ).
  ENDMETHOD.

  METHOD test_null_handling.
    DATA lv_yaml TYPE string.
    DATA lo_r    TYPE REF TO zif_ayaml.

    lv_yaml =
      |payload:\n| &&
      |  null_val: null|.

    lo_r = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_equals( exp = 'null'
                                        act = lo_r->get( '/payload/null_val' ) ).
    cl_abap_unit_assert=>assert_equals( exp = ''
                                        act = lo_r->get_string( '/payload/null_val' ) ).
  ENDMETHOD.

  METHOD test_auto_path_creation.
    mo_cut->set( iv_path  = '/a/b/num'
                 iv_value = 123 ).
    mo_cut->set( iv_path  = '/a/b/str'
                 iv_value = 'hello' ).
    mo_cut->set( iv_path  = '/a/b/bool'
                 iv_value = abap_true ).

    cl_abap_unit_assert=>assert_true( mo_cut->exists( '/a' ) ).
    cl_abap_unit_assert=>assert_true( mo_cut->exists( '/a/b' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 123
                                        act = mo_cut->get_integer( '/a/b/num' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'hello'
                                        act = mo_cut->get( '/a/b/str' ) ).
    cl_abap_unit_assert=>assert_true( mo_cut->get_boolean( '/a/b/bool' ) ).
  ENDMETHOD.

  METHOD test_ignore_empty_logic.
    mo_cut->set( iv_path  = '/empty_bool'
                 iv_value = abap_false ).
    mo_cut->set( iv_path  = '/empty_num'
                 iv_value = 0 ).
    cl_abap_unit_assert=>assert_true( mo_cut->exists( '/empty_bool' ) ).
    cl_abap_unit_assert=>assert_true( mo_cut->exists( '/empty_num' ) ).
    cl_abap_unit_assert=>assert_false( mo_cut->get_boolean( '/empty_bool' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = mo_cut->get_integer( '/empty_num' ) ).
  ENDMETHOD.

  METHOD test_escaping.
    DATA lv_input  TYPE string.
    DATA lv_yaml   TYPE string.
    DATA lo_parsed TYPE REF TO zif_ayaml.
    DATA lv_output TYPE string.

    lv_input = |escaping"\\|.
    mo_cut->set( iv_path  = '/esc'
                 iv_value = lv_input ).

    lv_yaml = mo_cut->to_yaml( ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*escaping\"\\*'
                                         act = lv_yaml ).

    lo_parsed = zcl_ayaml=>create_from_yaml( lv_yaml ).

    lv_output = lo_parsed->get( '/esc' ).
    cl_abap_unit_assert=>assert_equals( exp = lv_input
                                        act = lv_output ).
  ENDMETHOD.

  METHOD test_explicit_type_override.
    mo_cut->set( iv_node_type = zif_ayaml_types=>cs_type-string
                 iv_path      = '/str_num'
                 iv_value     = '123' ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ayaml_types=>cs_type-string
                                        act = mo_cut->get_node_type( '/str_num' ) ).
  ENDMETHOD.

  METHOD test_new_features.
    DATA lv_date   TYPE d VALUE '20240101'.
    DATA lv_yaml   TYPE string.
    DATA lo_parsed TYPE REF TO zif_ayaml.

    mo_cut->set_boolean( iv_path  = '/b'
                         iv_value = abap_true ).
    mo_cut->set_string( iv_path  = '/s'
                        iv_value = 'hello' ).
    mo_cut->set_integer( iv_path  = '/i'
                         iv_value = 42 ).
    mo_cut->set_number( iv_path  = '/f'
                        iv_value = '3.14' ).
    mo_cut->set_date( iv_path  = '/d'
                      iv_value = lv_date ).
    mo_cut->set_null( '/n' ).

    cl_abap_unit_assert=>assert_true( mo_cut->get_boolean( '/b' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'hello'
                                        act = mo_cut->get_string( '/s' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 42
                                        act = mo_cut->get_integer( '/i' ) ).
    cl_abap_unit_assert=>assert_equals( exp = '20240101'
                                        act = mo_cut->get_date( '/d' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ayaml_types=>cs_type-null
                                        act = mo_cut->get_node_type( '/n' ) ).

    mo_cut->init_array( '/arr' ).
    mo_cut->push( iv_path  = '/arr'
                  iv_value = 'abc' ).
    mo_cut->push( iv_path  = '/arr'
                  iv_value = 123 ).

    lv_yaml = mo_cut->to_yaml( ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*arr:*'
                                         act = lv_yaml ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*- abc*'
                                         act = lv_yaml ).

    lo_parsed = zcl_ayaml=>create_from_yaml( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 'abc'
                                        act = lo_parsed->get( '/arr/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 123
                                        act = lo_parsed->get_integer( '/arr/2' ) ).

    mo_cut->clear( ).
    cl_abap_unit_assert=>assert_true( mo_cut->is_empty( ) ).

    lv_yaml = |n: null\n|.
    mo_cut = zcl_ayaml=>create_from_yaml( lv_yaml ).
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

    mo_cut->set( iv_path  = '/a/x'
                 iv_value = '1' ).
    mo_cut->set( iv_path  = '/a/y'
                 iv_value = '2' ).
    mo_cut->set( iv_path  = '/a/z'
                 iv_value = '3' ).

    lt_members = mo_cut->get_keys( '/a' ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lines( lt_members ) ).

    READ TABLE lt_members WITH KEY table_line = 'x' TRANSPORTING NO FIELDS.
    cl_abap_unit_assert=>assert_true( boolc( sy-subrc = 0 ) ).
    mo_cut->delete( '/a/y' ).
    cl_abap_unit_assert=>assert_false( mo_cut->exists( '/a/y' ) ).
    lt_members = mo_cut->get_keys( '/a' ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( lt_members ) ).
    mo_cut->delete( '/a' ).
    cl_abap_unit_assert=>assert_false( mo_cut->exists( '/a/x' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = lines( mo_cut->get_keys( '/' ) ) ).
  ENDMETHOD.

  METHOD test_slice_and_clone_indep.
    DATA lo_slice TYPE REF TO zif_ayaml.
    DATA lo_clone TYPE REF TO zif_ayaml.

    mo_cut->set( iv_path  = '/root/a'
                 iv_value = 'val_a' ).
    mo_cut->set( iv_path  = '/root/b/c'
                 iv_value = 'val_c' ).
    mo_cut->set( iv_path  = '/root/b/d'
                 iv_value = 123 ).

    lo_slice = mo_cut->slice( '/root/b' ).
    cl_abap_unit_assert=>assert_true( lo_slice->exists( '/c' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'val_c'
                                        act = lo_slice->get( '/c' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 123
                                        act = lo_slice->get_integer( '/d' ) ).
    cl_abap_unit_assert=>assert_false( lo_slice->exists( '/a' ) ).

    lo_clone = mo_cut->clone( ).
    lo_clone->set( iv_path  = '/root/a'
                   iv_value = 'changed' ).
    cl_abap_unit_assert=>assert_equals( exp = 'val_a'
                                        act = mo_cut->get( '/root/a' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'changed'
                                        act = lo_clone->get( '/root/a' ) ).
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
    mo_cut->set( iv_path  = '/struct'
                 iv_value = ls_struct ).
    cl_abap_unit_assert=>assert_equals( exp = 'hello'
                                        act = mo_cut->get( '/struct/field1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 42
                                        act = mo_cut->get_integer( '/struct/field2' ) ).
    mo_cut->init_array( '/arr2' ).
    mo_cut->push( iv_path  = '/arr2'
                  iv_value = ls_struct ).

    lv_yaml = mo_cut->to_yaml( ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*arr2:*'
                                         act = lv_yaml ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*field1:*'
                                         act = lv_yaml ).
    mo_cut->init_array( iv_path  = '/empty_arr'
                        iv_clear = abap_true ).
    lv_yaml = mo_cut->to_yaml( ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*empty_arr:*[]*'
                                         act = lv_yaml ).
  ENDMETHOD.

  METHOD test_path_utils.
    DATA lv_parent TYPE string.
    DATA lv_name   TYPE string.

    DATA lv_norm   TYPE string.
    DATA lv_built  TYPE string.

    lv_norm = zcl_ayaml_utils=>normalize_path( 'a/b/' ).
    cl_abap_unit_assert=>assert_equals( exp = '/a/b'
                                        act = lv_norm ).
    lv_norm = zcl_ayaml_utils=>normalize_path( '' ).
    cl_abap_unit_assert=>assert_equals( exp = '/'
                                        act = lv_norm ).
    zcl_ayaml_utils=>split_path( EXPORTING iv_path = '/a/b/c'
                                 IMPORTING ev_path = lv_parent
                                           ev_name = lv_name ).
    cl_abap_unit_assert=>assert_equals( exp = '/a/b/'
                                        act = lv_parent ).
    cl_abap_unit_assert=>assert_equals( exp = 'c'
                                        act = lv_name ).
    zcl_ayaml_utils=>split_path( EXPORTING iv_path = '/'
                                 IMPORTING ev_path = lv_parent
                                           ev_name = lv_name ).
    cl_abap_unit_assert=>assert_equals( exp = '/'
                                        act = lv_parent ).

    lv_built = zcl_ayaml_utils=>build_path( iv_parent = '/a'
                                            iv_name   = 'b' ).
    cl_abap_unit_assert=>assert_equals( exp = '/a/b'
                                        act = lv_built ).
    lv_built = zcl_ayaml_utils=>build_path( iv_parent = '/'
                                            iv_name   = 'root' ).
    cl_abap_unit_assert=>assert_equals( exp = '/root'
                                        act = lv_built ).
    mo_cut->init_array( '/myseq' ).

    mo_cut->set( iv_path  = '/tmp'
                 iv_value = 'x' ).
    TRY.
        mo_cut->push( iv_path  = '/myseq'
                      iv_value = 'val1' ).
        cl_abap_unit_assert=>assert_true( abap_true ).
      CATCH zcx_ayaml_error.
        cl_abap_unit_assert=>fail( 'push on sequence failed' ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_string_utils.
    DATA lv_esc      TYPE string.
    DATA lv_unesc    TYPE string.
    DATA lv_stripped TYPE string.

    lv_esc = zcl_ayaml_utils=>escape_text( |a"b| ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*\"*'
                                         act = lv_esc ).
    lv_esc = zcl_ayaml_utils=>escape_text( 'a\b' ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*\\*'
                                         act = lv_esc ).
    lv_esc = zcl_ayaml_utils=>escape_text( 'a"b\c' ).

    lv_unesc = zcl_ayaml_utils=>unescape_text( lv_esc ).
    cl_abap_unit_assert=>assert_equals( exp = 'a"b\c'
                                        act = lv_unesc ).

    lv_stripped = zcl_ayaml_utils=>strip_quotes( |"hello"| ).
    cl_abap_unit_assert=>assert_equals( exp = 'hello'
                                        act = lv_stripped ).
    lv_stripped = zcl_ayaml_utils=>strip_quotes( |'it''s'| ).
    cl_abap_unit_assert=>assert_equals( exp = |it's|
                                        act = lv_stripped ).
    cl_abap_unit_assert=>assert_true( zcl_ayaml_utils=>is_plain_scalar( |simple| ) ).
    cl_abap_unit_assert=>assert_false( zcl_ayaml_utils=>is_plain_scalar( |a:b| ) ).
    cl_abap_unit_assert=>assert_false( zcl_ayaml_utils=>is_plain_scalar( | true | ) ).
    cl_abap_unit_assert=>assert_false( zcl_ayaml_utils=>is_plain_scalar( |null| ) ).
  ENDMETHOD.

  METHOD test_type_utils_date_time.
    DATA lv_date    TYPE d VALUE '20240115'.
    DATA lv_ts      TYPE timestamp.
    DATA lv_ts_str  TYPE string.
    DATA lv_ts_back TYPE timestamp.
    DATA lv_str     TYPE string.
    DATA lv_back    TYPE d.
    DATA lv_type    TYPE zif_ayaml_types=>ty_node_type.

    lv_str = zcl_ayaml_utils=>format_date( lv_date ).
    cl_abap_unit_assert=>assert_equals( exp = '2024-01-15'
                                        act = lv_str ).

    lv_back = zcl_ayaml_utils=>parse_date( '2024-01-15' ).
    cl_abap_unit_assert=>assert_equals( exp = lv_date
                                        act = lv_back ).
    lv_back = zcl_ayaml_utils=>parse_date( '' ).
    cl_abap_unit_assert=>assert_true( boolc( lv_back IS INITIAL ) ).
    GET TIME STAMP FIELD lv_ts.
    lv_ts_str = zcl_ayaml_utils=>format_timestamp( lv_ts ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*T*:*:*Z*'
                                         act = lv_ts_str ).
    lv_ts_back = zcl_ayaml_utils=>parse_timestamp( lv_ts_str ).
    cl_abap_unit_assert=>assert_true( boolc( lv_ts_back IS NOT INITIAL ) ).
    lv_type = zcl_ayaml_utils=>detect_type( 123 ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ayaml_types=>cs_type-number
                                        act = lv_type ).
    lv_type = zcl_ayaml_utils=>detect_type( 'abc' ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ayaml_types=>cs_type-string
                                        act = lv_type ).
    lv_type = zcl_ayaml_utils=>detect_type( abap_true ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ayaml_types=>cs_type-boolean
                                        act = lv_type ).
  ENDMETHOD.

  METHOD test_parser_inline_seq.
    DATA lv_yaml TYPE string.
    DATA lo_doc  TYPE REF TO zif_ayaml.

    lv_yaml = |seq: [a, b, 123]\nplain: hello|.

    lo_doc = zcl_ayaml=>create_from_yaml( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 'a'
                                        act = lo_doc->get( '/seq/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'b'
                                        act = lo_doc->get( '/seq/2' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 123
                                        act = lo_doc->get_integer( '/seq/3' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'hello'
                                        act = lo_doc->get( '/plain' ) ).
  ENDMETHOD.

  METHOD test_parser_seq_mapping.
    DATA lv_yaml TYPE string.
    DATA lo_doc  TYPE REF TO zif_ayaml.

    lv_yaml =
      |items:\n| &&
      |  - id: 1\n| &&
      |    name: one\n| &&
      |  - id: 2\n| &&
      |    name: two\n|.

    lo_doc = zcl_ayaml=>create_from_yaml( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lo_doc->get_integer( '/items/1/id' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'one'
                                        act = lo_doc->get( '/items/1/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_doc->get_integer( '/items/2/id' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'two'
                                        act = lo_doc->get( '/items/2/name' ) ).
  ENDMETHOD.

  METHOD test_serializer_indent.
    DATA lv_yaml TYPE string.

    mo_cut->set( iv_path  = '/a'
                 iv_value = '1' ).

    lv_yaml = mo_cut->to_yaml( 1 ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*a: 1*'
                                         act = lv_yaml ).
    lv_yaml = mo_cut->to_yaml( -1 ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*a: 1*'
                                         act = lv_yaml ).
    mo_cut->clear( ).
    mo_cut->set( iv_path  = '/a/b'
                 iv_value = 'x' ).
    lv_yaml = mo_cut->to_yaml( ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*a:*'
                                         act = lv_yaml ).
    mo_cut->clear( ).
    mo_cut->init_array( '/arr' ).
    mo_cut->init_array( '/arr/1' ).
    mo_cut->push( iv_path  = '/arr/1'
                  iv_value = 'nested' ).
    lv_yaml = mo_cut->to_yaml( ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*arr:*'
                                         act = lv_yaml ).
    mo_cut->clear( ).
    mo_cut->init_array( '/arr' ).
    lv_yaml = mo_cut->to_yaml( ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*arr: []*'
                                         act = lv_yaml ).
  ENDMETHOD.

  METHOD test_ty_t_string_empty_key.
    DATA lt_tbl TYPE zif_ayaml_types=>ty_t_string.

    INSERT `item1` INTO TABLE lt_tbl.
    INSERT `item2` INTO TABLE lt_tbl.
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( lt_tbl ) ).
  ENDMETHOD.

  METHOD test_getters_edge_cases.
    mo_cut->set( iv_node_type = zif_ayaml_types=>cs_type-number
                 iv_path      = '/bad_int'
                 iv_value     = 'not_a_number' ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = mo_cut->get_integer( '/bad_int' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = mo_cut->get_integer( '/non_existent' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = mo_cut->get_number( '/bad_int' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = mo_cut->get_number( '/non_existent' ) ).
    cl_abap_unit_assert=>assert_false( mo_cut->get_boolean( '/non_existent' ) ).
    cl_abap_unit_assert=>assert_equals( exp = ''
                                        act = mo_cut->get_string( '/non_existent' ) ).

    cl_abap_unit_assert=>assert_true( boolc( mo_cut->get_date( '/non_existent' ) IS INITIAL ) ).
    cl_abap_unit_assert=>assert_true( boolc( mo_cut->get_timestamp( '/non_existent' ) IS INITIAL ) ).

    mo_cut->set_null( '/my_null' ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = mo_cut->get_integer( '/my_null' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = mo_cut->get_number( '/my_null' ) ).
    cl_abap_unit_assert=>assert_false( mo_cut->get_boolean( '/my_null' ) ).

    cl_abap_unit_assert=>assert_true( boolc( mo_cut->get_date( '/my_null' ) IS INITIAL ) ).
    cl_abap_unit_assert=>assert_true( boolc( mo_cut->get_timestamp( '/my_null' ) IS INITIAL ) ).
    cl_abap_unit_assert=>assert_equals( exp = ''
                                        act = mo_cut->get_string( '/my_null' ) ).
  ENDMETHOD.

  METHOD test_set_recursive.
    TYPES: BEGIN OF ty_s_inner,
             field_a TYPE string,
             field_b TYPE i,
           END OF ty_s_inner.
    TYPES: BEGIN OF ty_s_outer,
             inner   TYPE ty_s_inner,
             numbers TYPE STANDARD TABLE OF i WITH DEFAULT KEY,
           END OF ty_s_outer.
    DATA ls_data TYPE ty_s_outer.

    ls_data-inner-field_a = 'nested_val'.
    ls_data-inner-field_b = 99.
    INSERT 10 INTO TABLE ls_data-numbers.
    INSERT 20 INTO TABLE ls_data-numbers.
    mo_cut->set( iv_path  = '/config'
                 iv_value = ls_data ).
    cl_abap_unit_assert=>assert_equals( exp = 'nested_val'
                                        act = mo_cut->get( '/config/inner/field_a' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 99
                                        act = mo_cut->get_integer( '/config/inner/field_b' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 10
                                        act = mo_cut->get_integer( '/config/numbers/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 20
                                        act = mo_cut->get_integer( '/config/numbers/2' ) ).
  ENDMETHOD.
ENDCLASS.


CLASS ltcl_ayaml_advanced_parser DEFINITION FINAL FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    METHODS test_odd_indentation           FOR TESTING RAISING cx_static_check.
    METHODS test_multiline_block_scalars   FOR TESTING RAISING cx_static_check.
    METHODS test_flow_mapping_and_sequence FOR TESTING RAISING cx_static_check.
    METHODS test_anchors_and_merge         FOR TESTING RAISING cx_static_check.
    METHODS test_inline_comments           FOR TESTING RAISING cx_static_check.
    METHODS test_strict_syntax_errors      FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltcl_ayaml_advanced_parser IMPLEMENTATION.
  METHOD test_odd_indentation.
    DATA lv_yaml TYPE string.
    DATA lo_yaml TYPE REF TO zif_ayaml.

    lv_yaml =
      |root:\n| &&
      |   child1: value1\n| &&
      |   child2:\n| &&
      |      deep: deep_val|.

    lo_yaml = zcl_ayaml=>create_from_yaml( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 'value1'
                                        act = lo_yaml->get( '/root/child1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'deep_val'
                                        act = lo_yaml->get( '/root/child2/deep' ) ).
  ENDMETHOD.

  METHOD test_multiline_block_scalars.
    DATA lv_yaml TYPE string.
    DATA lo_yaml TYPE REF TO zif_ayaml.
    DATA lv_lit  TYPE string.
    DATA lv_fold TYPE string.

    lv_yaml =
      |lit: \|{ cl_abap_char_utilities=>newline }| &&
      |  hello{ cl_abap_char_utilities=>newline }| &&
      |  world{ cl_abap_char_utilities=>newline }| &&
      |fold: >{ cl_abap_char_utilities=>newline }| &&
      |  hello{ cl_abap_char_utilities=>newline }| &&
      |  world|.

    lo_yaml = zcl_ayaml=>create_from_yaml( lv_yaml ).

    lv_lit = lo_yaml->get( '/lit' ).

    lv_fold = lo_yaml->get( '/fold' ).

    cl_abap_unit_assert=>assert_true( boolc( lv_lit CS 'hello' AND lv_lit CS 'world' ) ).
    cl_abap_unit_assert=>assert_true( boolc( lv_fold CS 'hello world' ) ).
  ENDMETHOD.

  METHOD test_flow_mapping_and_sequence.
    DATA lv_yaml TYPE string.
    DATA lo_yaml TYPE REF TO zif_ayaml.

    lv_yaml =
      |server: \{ host: localhost, port: 8080 \}{ cl_abap_char_utilities=>newline }| &&
      |items: [ alpha, beta, gamma ]|.

    lo_yaml = zcl_ayaml=>create_from_yaml( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 'localhost'
                                        act = lo_yaml->get( '/server/host' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 8080
                                        act = lo_yaml->get_integer( '/server/port' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'alpha'
                                        act = lo_yaml->get( '/items/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'gamma'
                                        act = lo_yaml->get( '/items/3' ) ).
  ENDMETHOD.

  METHOD test_anchors_and_merge.
    DATA lv_yaml TYPE string.
    DATA lo_yaml TYPE REF TO zif_ayaml.

    lv_yaml =
      |default: &base\n| &&
      |  host: db.local\n| &&
      |  port: 5432\n| &&
      |dev:\n| &&
      |  <<: *base\n| &&
      |  database: my_dev_db|.

    lo_yaml = zcl_ayaml=>create_from_yaml( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 'db.local'
                                        act = lo_yaml->get( '/dev/host' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 5432
                                        act = lo_yaml->get_integer( '/dev/port' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'my_dev_db'
                                        act = lo_yaml->get( '/dev/database' ) ).
  ENDMETHOD.

  METHOD test_inline_comments.
    DATA lv_yaml TYPE string.
    DATA lo_yaml TYPE REF TO zif_ayaml.

    lv_yaml =
      |# Top level comment\n| &&
      |key1: val1 # inline comment\n| &&
      |key2: val2|.

    lo_yaml = zcl_ayaml=>create_from_yaml( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 'val1'
                                        act = lo_yaml->get( '/key1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'val2'
                                        act = lo_yaml->get( '/key2' ) ).
  ENDMETHOD.

  METHOD test_strict_syntax_errors.
    TRY.
        zcl_ayaml=>create_from_yaml( `'unclosed string` ).
        cl_abap_unit_assert=>fail( 'Expected syntax error for unclosed single quote' ).
      CATCH zcx_ayaml_error.
    ENDTRY.

    TRY.
        zcl_ayaml=>create_from_yaml( `key: *undefined_alias` ).
        cl_abap_unit_assert=>fail( 'Expected error for undefined alias' ).
      CATCH zcx_ayaml_error.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.


CLASS ltcl_ayaml_new_architecture DEFINITION FINAL FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    METHODS test_reader_interface        FOR TESTING RAISING cx_static_check.
    METHODS test_writer_interface        FOR TESTING RAISING cx_static_check.
    METHODS test_to_abap_deserializer    FOR TESTING RAISING cx_static_check.
    METHODS test_default_values          FOR TESTING RAISING cx_static_check.
    METHODS test_sequence_helpers        FOR TESTING RAISING cx_static_check.
    METHODS test_from_abap_camel_case    FOR TESTING RAISING cx_static_check.
    METHODS test_from_abap_snake_case    FOR TESTING RAISING cx_static_check.
    METHODS test_from_abap_tables        FOR TESTING RAISING cx_static_check.
    METHODS test_to_abap_flexible_casing FOR TESTING RAISING cx_static_check.
    METHODS test_bidirectional_roundtrip FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltcl_ayaml_new_architecture IMPLEMENTATION.
  METHOD test_reader_interface.
    DATA lo_yaml   TYPE REF TO zif_ayaml.
    DATA lo_reader LIKE lo_yaml.

    lo_yaml = zcl_ayaml=>create_from_yaml( |title: Book\npages: 350\nactive: true| ).

    lo_reader = lo_yaml.

    cl_abap_unit_assert=>assert_false( lo_reader->is_empty( ) ).
    cl_abap_unit_assert=>assert_true( lo_reader->exists( '/title' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'Book'
                                        act = lo_reader->get_string( '/title' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 350
                                        act = lo_reader->get_integer( '/pages' ) ).
    cl_abap_unit_assert=>assert_true( lo_reader->get_boolean( '/active' ) ).
  ENDMETHOD.

  METHOD test_writer_interface.
    DATA lo_yaml   TYPE REF TO zif_ayaml.
    DATA lo_writer LIKE lo_yaml.

    lo_yaml = zcl_ayaml=>create_empty( ).

    lo_writer = lo_yaml.

    lo_writer->set_string( iv_path  = '/user/name'
                           iv_value = 'Alice' ).
    lo_writer->init_array( '/user/roles' ).
    lo_writer->push( iv_path  = '/user/roles'
                     iv_value = 'admin' ).
    lo_writer->push( iv_path  = '/user/roles'
                     iv_value = 'editor' ).

    cl_abap_unit_assert=>assert_equals( exp = 'Alice'
                                        act = lo_yaml->get_string( '/user/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_yaml->get_array_length( '/user/roles' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'admin'
                                        act = lo_yaml->get_string( '/user/roles/1' ) ).
  ENDMETHOD.

  METHOD test_to_abap_deserializer.
    TYPES: BEGIN OF ty_s_user,
             name  TYPE string,
             age   TYPE i,
             admin TYPE abap_bool,
           END OF ty_s_user.
    TYPES: BEGIN OF ty_s_config,
             host TYPE string,
             port TYPE i,
             user TYPE ty_s_user,
           END OF ty_s_config.
    TYPES ty_t_users TYPE STANDARD TABLE OF ty_s_user WITH DEFAULT KEY.

    DATA ls_config TYPE ty_s_config.
    DATA lt_users  TYPE ty_t_users.

    DATA lv_yaml   TYPE string.
    DATA lo_yaml   TYPE REF TO zif_ayaml.
    FIELD-SYMBOLS <fs_user> TYPE ty_s_user.

    lv_yaml =
      |host: localhost\n| &&
      |port: 8080\n| &&
      |user:\n| &&
      |  name: Bob\n| &&
      |  age: 29\n| &&
      |  admin: true|.

    lo_yaml = zcl_ayaml=>create_from_yaml( lv_yaml ).
    lo_yaml->to_abap( IMPORTING ev_data = ls_config ).

    cl_abap_unit_assert=>assert_equals( exp = 'localhost'
                                        act = ls_config-host ).
    cl_abap_unit_assert=>assert_equals( exp = 8080
                                        act = ls_config-port ).
    cl_abap_unit_assert=>assert_equals( exp = 'Bob'
                                        act = ls_config-user-name ).
    cl_abap_unit_assert=>assert_equals( exp = 29
                                        act = ls_config-user-age ).
    cl_abap_unit_assert=>assert_true( ls_config-user-admin ).

    lv_yaml =
      |- name: UserOne\n| &&
      |  age: 20\n| &&
      |  admin: false\n| &&
      |- name: UserTwo\n| &&
      |  age: 30\n| &&
      |  admin: true|.

    lo_yaml = zcl_ayaml=>create_from_yaml( lv_yaml ).
    lo_yaml->to_abap( IMPORTING ev_data = lt_users ).

    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( lt_users ) ).

    READ TABLE lt_users INDEX 1 ASSIGNING <fs_user>.
    ASSERT sy-subrc = 0.
    cl_abap_unit_assert=>assert_equals( exp = 'UserOne'
                                        act = <fs_user>-name ).
    cl_abap_unit_assert=>assert_equals( exp = 20
                                        act = <fs_user>-age ).
    READ TABLE lt_users INDEX 2 ASSIGNING <fs_user>.
    ASSERT sy-subrc = 0.
    cl_abap_unit_assert=>assert_equals( exp = 'UserTwo'
                                        act = <fs_user>-name ).
    cl_abap_unit_assert=>assert_true( <fs_user>-admin ).
  ENDMETHOD.

  METHOD test_default_values.
    DATA lo_yaml TYPE REF TO zif_ayaml.

    lo_yaml = zcl_ayaml=>create_empty( ).

    cl_abap_unit_assert=>assert_equals( exp = 'fallback'
                                        act = lo_yaml->get_string( iv_path    = '/missing'
                                                                   iv_default = 'fallback' ) ).

    cl_abap_unit_assert=>assert_equals( exp = 999
                                        act = lo_yaml->get_integer( iv_path    = '/missing'
                                                                    iv_default = 999 ) ).

    cl_abap_unit_assert=>assert_true( lo_yaml->get_boolean( iv_path    = '/missing'
                                                            iv_default = abap_true ) ).

    lo_yaml->set_null( '/null_field' ).
    cl_abap_unit_assert=>assert_equals( exp = 'default_for_null'
                                        act = lo_yaml->get_string( iv_path    = '/null_field'
                                                                   iv_default = 'default_for_null' ) ).
  ENDMETHOD.

  METHOD test_sequence_helpers.
    DATA lt_fruits TYPE zif_ayaml_types=>ty_t_string.
    DATA lo_yaml   TYPE REF TO zif_ayaml.
    DATA lv_yaml   TYPE string.
    FIELD-SYMBOLS <fs_fruit> LIKE LINE OF lt_fruits.

    lo_yaml = zcl_ayaml=>create_empty( ).
    lo_yaml->init_array( '/fruits' ).
    lo_yaml->push( iv_path  = '/fruits'
                   iv_value = 'apple' ).
    lo_yaml->push( iv_path  = '/fruits'
                   iv_value = 'banana' ).
    lo_yaml->push( iv_path  = '/fruits'
                   iv_value = 'orange' ).

    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lo_yaml->get_array_length( '/fruits' ) ).

    lt_fruits = lo_yaml->get_string_table( '/fruits' ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lines( lt_fruits ) ).
    READ TABLE lt_fruits INDEX 1 ASSIGNING <fs_fruit>.
    ASSERT sy-subrc = 0.
    cl_abap_unit_assert=>assert_equals( exp = 'apple'
                                        act = <fs_fruit> ).

    READ TABLE lt_fruits INDEX 2 ASSIGNING <fs_fruit>.
    ASSERT sy-subrc = 0.
    cl_abap_unit_assert=>assert_equals( exp = 'banana'
                                        act = <fs_fruit> ).

    READ TABLE lt_fruits INDEX 3 ASSIGNING <fs_fruit>.
    ASSERT sy-subrc = 0.
    cl_abap_unit_assert=>assert_equals( exp = 'orange'
                                        act = <fs_fruit> ).

    lv_yaml = lo_yaml->to_yaml( ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*fruits:*'
                                         act = lv_yaml ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*- apple*'
                                         act = lv_yaml ).
  ENDMETHOD.

  METHOD test_from_abap_camel_case.
    TYPES: BEGIN OF ty_s_user_profile,
             first_name   TYPE string,
             phone_number TYPE string,
             is_active    TYPE abap_bool,
           END OF ty_s_user_profile.
    DATA ls_user TYPE ty_s_user_profile.
    DATA lv_yaml TYPE string.

    ls_user-first_name   = 'John'.
    ls_user-phone_number = '555-1234'.
    ls_user-is_active    = abap_true.

    lv_yaml = zcl_ayaml=>create_from_abap( iv_data   = ls_user
                                           iv_format = zif_ayaml_types=>cs_format-camel_case )->to_yaml( ).

    cl_abap_unit_assert=>assert_char_cp( exp = '*firstName: John*'
                                         act = lv_yaml ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*phoneNumber: 555-1234*'
                                         act = lv_yaml ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*isActive: true*'
                                         act = lv_yaml ).
  ENDMETHOD.

  METHOD test_from_abap_snake_case.
    TYPES: BEGIN OF ty_s_settings,
             max_connections TYPE i,
             api_token       TYPE string,
           END OF ty_s_settings.
    DATA ls_settings TYPE ty_s_settings.
    DATA lv_yaml     TYPE string.

    ls_settings-max_connections = 100.
    ls_settings-api_token       = 'secret'.

    lv_yaml = zcl_ayaml=>create_from_abap( iv_data   = ls_settings
                                           iv_format = zif_ayaml_types=>cs_format-snake_case )->to_yaml( ).

    cl_abap_unit_assert=>assert_char_cp( exp = '*max_connections: 100*'
                                         act = lv_yaml ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*api_token: secret*'
                                         act = lv_yaml ).
  ENDMETHOD.

  METHOD test_from_abap_tables.
    TYPES: BEGIN OF ty_s_item,
             item_id   TYPE i,
             item_name TYPE string,
           END OF ty_s_item.
    TYPES ty_t_item TYPE STANDARD TABLE OF ty_s_item WITH DEFAULT KEY.
    DATA lt_items TYPE ty_t_item.
    DATA ls_items LIKE LINE OF lt_items.
    DATA lv_yaml  TYPE string.

    CLEAR ls_items.
    ls_items-item_id   = 1.
    ls_items-item_name = 'Alpha'.
    INSERT ls_items INTO TABLE lt_items.

    CLEAR ls_items.
    ls_items-item_id   = 2.
    ls_items-item_name = 'Beta'.
    INSERT ls_items INTO TABLE lt_items.

    lv_yaml = zcl_ayaml=>create_from_abap( iv_data   = lt_items
                                           iv_format = zif_ayaml_types=>cs_format-camel_case )->to_yaml( ).

    cl_abap_unit_assert=>assert_char_cp( exp = '*- itemId: 1*'
                                         act = lv_yaml ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*itemName: Alpha*'
                                         act = lv_yaml ).
  ENDMETHOD.

  METHOD test_to_abap_flexible_casing.
    TYPES: BEGIN OF ty_s_payload,
             first_name TYPE string,
             last_name  TYPE string,
             user_age   TYPE i,
           END OF ty_s_payload.
    DATA ls_payload TYPE ty_s_payload.

    DATA lv_yaml    TYPE string.
    DATA lo_yaml    TYPE REF TO zif_ayaml.

    lv_yaml =
      |firstName: Alice\n| &&
      |last_name: Smith\n| &&
      |USER_AGE: 28\n|.

    lo_yaml = zcl_ayaml=>create_from_yaml( lv_yaml ).
    lo_yaml->to_abap( IMPORTING ev_data = ls_payload ).

    cl_abap_unit_assert=>assert_equals( exp = 'Alice'
                                        act = ls_payload-first_name ).
    cl_abap_unit_assert=>assert_equals( exp = 'Smith'
                                        act = ls_payload-last_name ).
    cl_abap_unit_assert=>assert_equals( exp = 28
                                        act = ls_payload-user_age ).
  ENDMETHOD.

  METHOD test_bidirectional_roundtrip.
    TYPES: BEGIN OF ty_s_rec,
             server_host TYPE string,
             server_port TYPE i,
             is_secured  TYPE abap_bool,
           END OF ty_s_rec.
    DATA ls_in   TYPE ty_s_rec.
    DATA ls_out  TYPE ty_s_rec.
    DATA lv_yaml TYPE string.
    DATA lo_yaml TYPE REF TO zif_ayaml.

    ls_in-server_host = 'api.internal'.
    ls_in-server_port = 443.
    ls_in-is_secured  = abap_true.

    lv_yaml = zcl_ayaml=>create_from_abap( iv_data   = ls_in
                                           iv_format = zif_ayaml_types=>cs_format-camel_case )->to_yaml( ).

    lo_yaml = zcl_ayaml=>create_from_yaml( lv_yaml ).
    lo_yaml->to_abap( IMPORTING ev_data = ls_out ).

    cl_abap_unit_assert=>assert_equals( exp = ls_in-server_host
                                        act = ls_out-server_host ).
    cl_abap_unit_assert=>assert_equals( exp = ls_in-server_port
                                        act = ls_out-server_port ).
    cl_abap_unit_assert=>assert_equals( exp = ls_in-is_secured
                                        act = ls_out-is_secured ).
  ENDMETHOD.
ENDCLASS.
