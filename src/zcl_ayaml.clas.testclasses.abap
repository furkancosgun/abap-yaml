CLASS ltcl_ayaml_master_suite DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    DATA mo_cut TYPE REF TO zif_ayaml.

    METHODS setup.
    METHODS test_empty_and_exists       FOR TESTING RAISING cx_static_check.
    METHODS test_scalar_readers         FOR TESTING RAISING cx_static_check.
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

  METHOD test_scalar_readers.
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


CLASS ltcl_ayaml_comprehensive_suite DEFINITION FINAL FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    METHODS test_empty_and_comments       FOR TESTING RAISING cx_static_check.
    METHODS test_special_char_scalars     FOR TESTING RAISING cx_static_check.
    METHODS test_advanced_numbers         FOR TESTING RAISING cx_static_check.
    METHODS test_empty_collections        FOR TESTING RAISING cx_static_check.
    METHODS test_nested_sequences         FOR TESTING RAISING cx_static_check.
    METHODS test_deep_structures          FOR TESTING RAISING cx_static_check.
    METHODS test_table_data_binding_edges FOR TESTING RAISING cx_static_check.
    METHODS test_mutation_edge_cases      FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltcl_ayaml_comprehensive_suite IMPLEMENTATION.
  METHOD test_empty_and_comments.
    DATA lo_cut TYPE REF TO zif_ayaml.

    lo_cut = zcl_ayaml=>create_from_yaml( `` ).
    cl_abap_unit_assert=>assert_true( lo_cut->is_empty( ) ).

    lo_cut = zcl_ayaml=>create_from_yaml( |   \n   \n   | ).
    cl_abap_unit_assert=>assert_true( lo_cut->is_empty( ) ).

    lo_cut = zcl_ayaml=>create_from_yaml( |# Just a full comment line\n# Another comment\n| ).
    cl_abap_unit_assert=>assert_true( lo_cut->is_empty( ) ).

    lo_cut = zcl_ayaml=>create_from_yaml( |---\n...| ).
    cl_abap_unit_assert=>assert_true( lo_cut->is_empty( ) ).
  ENDMETHOD.

  METHOD test_special_char_scalars.
    DATA lv_yaml TYPE string.
    DATA lo_cut  TYPE REF TO zif_ayaml.

    lv_yaml =
      |dash: '-'\n| &&
      |plus: +\n| &&
      |dot: .\n| &&
      |double_dash: --\n| &&
      |dots: ...\n| &&
      |colon_str: 'foo:bar'\n| &&
      |alphanum: 123abc\n|.

    lo_cut = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_equals( exp = '-'
                                        act = lo_cut->get_string( '/dash' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ayaml_types=>cs_type-string
                                        act = lo_cut->get_node_type( '/dash' ) ).

    cl_abap_unit_assert=>assert_equals( exp = '+'
                                        act = lo_cut->get_string( '/plus' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ayaml_types=>cs_type-string
                                        act = lo_cut->get_node_type( '/plus' ) ).

    cl_abap_unit_assert=>assert_equals( exp = '.'
                                        act = lo_cut->get_string( '/dot' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ayaml_types=>cs_type-string
                                        act = lo_cut->get_node_type( '/dot' ) ).

    cl_abap_unit_assert=>assert_equals( exp = '--'
                                        act = lo_cut->get_string( '/double_dash' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ayaml_types=>cs_type-string
                                        act = lo_cut->get_node_type( '/double_dash' ) ).

    cl_abap_unit_assert=>assert_equals( exp = 'foo:bar'
                                        act = lo_cut->get_string( '/colon_str' ) ).
    cl_abap_unit_assert=>assert_equals( exp = '123abc'
                                        act = lo_cut->get_string( '/alphanum' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ayaml_types=>cs_type-string
                                        act = lo_cut->get_node_type( '/alphanum' ) ).
  ENDMETHOD.

  METHOD test_advanced_numbers.
    DATA lv_yaml TYPE string.
    DATA lo_cut  TYPE REF TO zif_ayaml.

    lv_yaml =
      |int_neg: -42\n| &&
      |int_pos: +100\n| &&
      |zero: 0\n| &&
      |float_neg: -3.14\n| &&
      |sci_large: 1e5\n| &&
      |sci_small: -2.5E-2\n|.

    lo_cut = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_equals( exp = -42
                                        act = lo_cut->get_integer( '/int_neg' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 100
                                        act = lo_cut->get_integer( '/int_pos' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = lo_cut->get_integer( '/zero' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ayaml_types=>cs_type-number
                                        act = lo_cut->get_node_type( '/float_neg' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ayaml_types=>cs_type-number
                                        act = lo_cut->get_node_type( '/sci_large' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ayaml_types=>cs_type-number
                                        act = lo_cut->get_node_type( '/sci_small' ) ).
  ENDMETHOD.

  METHOD test_empty_collections.
    DATA lv_yaml TYPE string.
    DATA lo_cut  TYPE REF TO zif_ayaml.
    DATA lt_keys TYPE zif_ayaml_types=>ty_t_string.

    lv_yaml =
      |empty_list: []\n| &&
      |empty_map: \{\}\n|.

    lo_cut = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = lo_cut->get_array_length( '/empty_list' ) ).
    lt_keys = lo_cut->get_keys( '/empty_map' ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = lines( lt_keys ) ).
  ENDMETHOD.

  METHOD test_nested_sequences.
    DATA lv_yaml TYPE string.
    DATA lo_cut  TYPE REF TO zif_ayaml.

    lv_yaml =
      |matrix:\n| &&
      |  - [10, 20]\n| &&
      |  - [30, 40]\n|.

    lo_cut = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_cut->get_array_length( '/matrix' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 10
                                        act = lo_cut->get_integer( '/matrix/1/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 20
                                        act = lo_cut->get_integer( '/matrix/1/2' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 30
                                        act = lo_cut->get_integer( '/matrix/2/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 40
                                        act = lo_cut->get_integer( '/matrix/2/2' ) ).
  ENDMETHOD.

  METHOD test_deep_structures.
    TYPES: BEGIN OF ty_s_address,
             street TYPE string,
             city   TYPE string,
             zip    TYPE i,
           END OF ty_s_address.
    TYPES: BEGIN OF ty_s_company,
             name    TYPE string,
             address TYPE ty_s_address,
           END OF ty_s_company.

    DATA ls_in   TYPE ty_s_company.
    DATA ls_out  TYPE ty_s_company.
    DATA lv_yaml TYPE string.
    DATA lo_cut  TYPE REF TO zif_ayaml.

    ls_in-name = 'Acme Corp'.
    ls_in-address-street = 'Main Street 1'.
    ls_in-address-city   = 'Metropolis'.
    ls_in-address-zip    = 12345.

    lv_yaml = zcl_ayaml=>create_from_abap( iv_data   = ls_in
                                           iv_format = zif_ayaml_types=>cs_format-snake_case )->to_yaml( ).

    lo_cut = zcl_ayaml=>create_from_yaml( lv_yaml ).
    lo_cut->to_abap( IMPORTING ev_data = ls_out ).

    cl_abap_unit_assert=>assert_equals( exp = ls_in-name
                                        act = ls_out-name ).
    cl_abap_unit_assert=>assert_equals( exp = ls_in-address-street
                                        act = ls_out-address-street ).
    cl_abap_unit_assert=>assert_equals( exp = ls_in-address-city
                                        act = ls_out-address-city ).
    cl_abap_unit_assert=>assert_equals( exp = ls_in-address-zip
                                        act = ls_out-address-zip ).
  ENDMETHOD.

  METHOD test_table_data_binding_edges.
    TYPES: BEGIN OF ty_s_item,
             id          TYPE i,
             description TYPE string,
           END OF ty_s_item.
    TYPES ty_t_items TYPE STANDARD TABLE OF ty_s_item WITH DEFAULT KEY.

    DATA lt_empty_in  TYPE ty_t_items.
    DATA lt_empty_out TYPE ty_t_items.
    DATA lv_yaml      TYPE string.
    DATA lo_cut       TYPE REF TO zif_ayaml.
    DATA ls_target    TYPE ty_s_item.

    lv_yaml = zcl_ayaml=>create_from_abap( lt_empty_in )->to_yaml( ).
    lo_cut = zcl_ayaml=>create_from_yaml( lv_yaml ).
    lo_cut->to_abap( IMPORTING ev_data = lt_empty_out ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = lines( lt_empty_out ) ).

    " Incompatible type mapping fallback (string into integer target should safely fallback to 0)
    lv_yaml = |id: not_a_number\ndescription: valid text\n|.
    lo_cut = zcl_ayaml=>create_from_yaml( lv_yaml ).
    lo_cut->to_abap( IMPORTING ev_data = ls_target ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = ls_target-id ).
    cl_abap_unit_assert=>assert_equals( exp = 'valid text'
                                        act = ls_target-description ).
  ENDMETHOD.

  METHOD test_mutation_edge_cases.
    DATA lo_doc   TYPE REF TO zif_ayaml.
    DATA lo_clone TYPE REF TO zif_ayaml.
    DATA lo_slice TYPE REF TO zif_ayaml.

    lo_doc = zcl_ayaml=>create_empty( ).

    " Safe deletion of non-existent path
    lo_doc->delete( '/non/existent' ).

    lo_doc->set_string( iv_path  = '/app/name'
                        iv_value = 'Original' ).
    lo_doc->set_integer( iv_path  = '/app/port'
                         iv_value = 8080 ).

    " Clone independence
    lo_clone = lo_doc->clone( ).
    lo_clone->set_string( iv_path  = '/app/name'
                          iv_value = 'Cloned' ).

    cl_abap_unit_assert=>assert_equals( exp = 'Original'
                                        act = lo_doc->get_string( '/app/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'Cloned'
                                        act = lo_clone->get_string( '/app/name' ) ).

    " Slice non-existent path
    lo_slice = lo_doc->slice( '/non_existent' ).
    cl_abap_unit_assert=>assert_true( lo_slice->is_empty( ) ).

    " Slice subtree
    lo_slice = lo_doc->slice( '/app' ).
    cl_abap_unit_assert=>assert_equals( exp = 'Original'
                                        act = lo_slice->get_string( '/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 8080
                                        act = lo_slice->get_integer( '/port' ) ).

    " Clear document
    lo_doc->clear( ).
    cl_abap_unit_assert=>assert_true( lo_doc->is_empty( ) ).
  ENDMETHOD.
ENDCLASS.


CLASS ltcl_ayaml_stress_tests DEFINITION FINAL FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    METHODS test_kubernetes_manifest       FOR TESTING RAISING cx_static_check.
    METHODS test_url_and_colons_in_scalars FOR TESTING RAISING cx_static_check.
    METHODS test_boolean_variations        FOR TESTING RAISING cx_static_check.
    METHODS test_null_variations           FOR TESTING RAISING cx_static_check.
    METHODS test_chomping_indicators       FOR TESTING RAISING cx_static_check.
    METHODS test_flow_in_block_and_quotes  FOR TESTING RAISING cx_static_check.
    METHODS test_multiline_and_escaping    FOR TESTING RAISING cx_static_check.
    METHODS test_deep_table_binding        FOR TESTING RAISING cx_static_check.
    METHODS test_syntax_error_validations  FOR TESTING RAISING cx_static_check.
    METHODS test_document_reconstruction   FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltcl_ayaml_stress_tests IMPLEMENTATION.
  METHOD test_kubernetes_manifest.
    DATA lv_yaml TYPE string.
    DATA lo_cut  TYPE REF TO zif_ayaml.

    lv_yaml =
      |apiVersion: apps/v1\n| &&
      |kind: Deployment\n| &&
      |metadata:\n| &&
      |  name: web-app\n| &&
      |  labels:\n| &&
      |    app: nginx\n| &&
      |    tier: frontend\n| &&
      |spec:\n| &&
      |  replicas: 3\n| &&
      |  template:\n| &&
      |    spec:\n| &&
      |      containers:\n| &&
      |        - name: nginx-web\n| &&
      |          image: nginx:1.21\n| &&
      |          ports:\n| &&
      |            - containerPort: 80\n| &&
      |            - containerPort: 443\n| &&
      |          env:\n| &&
      |            - name: ENVIRONMENT\n| &&
      |              value: production\n|.

    lo_cut = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_equals( exp = 'apps/v1'
                                        act = lo_cut->get_string( '/apiVersion' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'Deployment'
                                        act = lo_cut->get_string( '/kind' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'web-app'
                                        act = lo_cut->get_string( '/metadata/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'nginx'
                                        act = lo_cut->get_string( '/metadata/labels/app' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lo_cut->get_integer( '/spec/replicas' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'nginx-web'
                                        act = lo_cut->get_string( '/spec/template/spec/containers/1/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'nginx:1.21'
                                        act = lo_cut->get_string( '/spec/template/spec/containers/1/image' ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = 80
        act = lo_cut->get_integer( '/spec/template/spec/containers/1/ports/1/containerPort' ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = 443
        act = lo_cut->get_integer( '/spec/template/spec/containers/1/ports/2/containerPort' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'ENVIRONMENT'
                                        act = lo_cut->get_string( '/spec/template/spec/containers/1/env/1/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'production'
                                        act = lo_cut->get_string( '/spec/template/spec/containers/1/env/1/value' ) ).
  ENDMETHOD.

  METHOD test_url_and_colons_in_scalars.
    DATA lv_yaml TYPE string.
    DATA lo_cut  TYPE REF TO zif_ayaml.

    lv_yaml =
      |endpoint: http://api.service.io:8080/v1/health\n| &&
      |ratio: 16:9\n| &&
      |time_str: 12:30:00\n|.

    lo_cut = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_equals( exp = 'http://api.service.io:8080/v1/health'
                                        act = lo_cut->get_string( '/endpoint' ) ).
    cl_abap_unit_assert=>assert_equals( exp = '16:9'
                                        act = lo_cut->get_string( '/ratio' ) ).
    cl_abap_unit_assert=>assert_equals( exp = '12:30:00'
                                        act = lo_cut->get_string( '/time_str' ) ).
  ENDMETHOD.

  METHOD test_boolean_variations.
    DATA lv_yaml TYPE string.
    DATA lo_cut  TYPE REF TO zif_ayaml.

    lv_yaml =
      |b1: true\n| &&
      |b2: True\n| &&
      |b3: TRUE\n| &&
      |b4: false\n| &&
      |b5: False\n| &&
      |b6: FALSE\n|.

    lo_cut = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_true( lo_cut->get_boolean( '/b1' ) ).
    cl_abap_unit_assert=>assert_true( lo_cut->get_boolean( '/b2' ) ).
    cl_abap_unit_assert=>assert_true( lo_cut->get_boolean( '/b3' ) ).
    cl_abap_unit_assert=>assert_false( lo_cut->get_boolean( '/b4' ) ).
    cl_abap_unit_assert=>assert_false( lo_cut->get_boolean( '/b5' ) ).
    cl_abap_unit_assert=>assert_false( lo_cut->get_boolean( '/b6' ) ).
  ENDMETHOD.

  METHOD test_null_variations.
    DATA lv_yaml TYPE string.
    DATA lo_cut  TYPE REF TO zif_ayaml.

    lv_yaml =
      |n1: null\n| &&
      |n2: Null\n| &&
      |n3: NULL\n| &&
      |n4: ~\n|.

    lo_cut = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_equals( exp = zif_ayaml_types=>cs_type-null
                                        act = lo_cut->get_node_type( '/n1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ayaml_types=>cs_type-null
                                        act = lo_cut->get_node_type( '/n2' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ayaml_types=>cs_type-null
                                        act = lo_cut->get_node_type( '/n3' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ayaml_types=>cs_type-null
                                        act = lo_cut->get_node_type( '/n4' ) ).

    cl_abap_unit_assert=>assert_equals( exp = ''
                                        act = lo_cut->get_string( '/n1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'fallback'
                                        act = lo_cut->get_string( iv_path    = '/n2'
                                                                  iv_default = 'fallback' ) ).
  ENDMETHOD.

  METHOD test_chomping_indicators.
    DATA lv_yaml  TYPE string.
    DATA lo_cut   TYPE REF TO zif_ayaml.
    DATA lv_strip TYPE string.
    DATA lv_keep  TYPE string.

    lv_yaml =
      |strip: \|-\n| &&
      |  line1\n| &&
      |  line2\n| &&
      |keep: \|+\n| &&
      |  lineA\n| &&
      |  lineB\n| &&
      |\n|.

    lo_cut = zcl_ayaml=>create_from_yaml( lv_yaml ).
    lv_strip = lo_cut->get_string( '/strip' ).
    lv_keep = lo_cut->get_string( '/keep' ).

    cl_abap_unit_assert=>assert_true( boolc( lv_strip CS 'line1' AND lv_strip CS 'line2' ) ).
    cl_abap_unit_assert=>assert_true( boolc( lv_keep CS 'lineA' AND lv_keep CS 'lineB' ) ).
  ENDMETHOD.

  METHOD test_flow_in_block_and_quotes.
    DATA lv_yaml TYPE string.
    DATA lo_cut  TYPE REF TO zif_ayaml.

    lv_yaml =
      |endpoints:\n| &&
      |  - \{ "path": "/users", methods: [ "GET", "POST" ], auth: true \}\n| &&
      |  - \{ 'path': '/health', methods: [ "GET" ], auth: false \}\n|.

    lo_cut = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_cut->get_array_length( '/endpoints' ) ).
    cl_abap_unit_assert=>assert_equals( exp = '/users'
                                        act = lo_cut->get_string( '/endpoints/1/path' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'GET'
                                        act = lo_cut->get_string( '/endpoints/1/methods/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'POST'
                                        act = lo_cut->get_string( '/endpoints/1/methods/2' ) ).
    cl_abap_unit_assert=>assert_true( lo_cut->get_boolean( '/endpoints/1/auth' ) ).

    cl_abap_unit_assert=>assert_equals( exp = '/health'
                                        act = lo_cut->get_string( '/endpoints/2/path' ) ).
    cl_abap_unit_assert=>assert_false( lo_cut->get_boolean( '/endpoints/2/auth' ) ).
  ENDMETHOD.

  METHOD test_multiline_and_escaping.
    DATA lv_yaml   TYPE string.
    DATA lo_cut    TYPE REF TO zif_ayaml.
    DATA lv_single TYPE string.
    DATA lv_double TYPE string.

    lv_yaml =
      'msg_single: ''hello ''''world'''' from yaml''' & cl_abap_char_utilities=>newline &
      'msg_double: "tab:\there, newline:\nthere, quote:\"ok\""' & cl_abap_char_utilities=>newline.

    lo_cut = zcl_ayaml=>create_from_yaml( lv_yaml ).

    lv_single = lo_cut->get_string( '/msg_single' ).
    cl_abap_unit_assert=>assert_equals( exp = |hello 'world' from yaml|
                                        act = lv_single ).

    lv_double = lo_cut->get_string( '/msg_double' ).
    cl_abap_unit_assert=>assert_true( boolc( lv_double CS cl_abap_char_utilities=>horizontal_tab ) ).
    cl_abap_unit_assert=>assert_true( boolc( lv_double CS cl_abap_char_utilities=>newline ) ).
    cl_abap_unit_assert=>assert_true( boolc( lv_double CS '"ok"' ) ).
  ENDMETHOD.

  METHOD test_deep_table_binding.
    TYPES: BEGIN OF ty_s_subitem,
             sub_id   TYPE i,
             sub_name TYPE string,
           END OF ty_s_subitem.
    TYPES ty_t_subitems TYPE STANDARD TABLE OF ty_s_subitem WITH DEFAULT KEY.
    TYPES: BEGIN OF ty_s_order,
             order_id TYPE i,
             customer TYPE string,
             subitems TYPE ty_t_subitems,
           END OF ty_s_order.

    DATA ls_in   TYPE ty_s_order.
    DATA ls_out  TYPE ty_s_order.
    DATA ls_sub  TYPE ty_s_subitem.
    DATA lv_yaml TYPE string.
    DATA lo_cut  TYPE REF TO zif_ayaml.
    FIELD-SYMBOLS <fs_sub> TYPE ty_s_subitem.

    ls_in-order_id = 1001.
    ls_in-customer = 'Global Logistics'.

    ls_sub-sub_id   = 1.
    ls_sub-sub_name = 'Widget A'.
    INSERT ls_sub INTO TABLE ls_in-subitems.

    ls_sub-sub_id   = 2.
    ls_sub-sub_name = 'Widget B'.
    INSERT ls_sub INTO TABLE ls_in-subitems.

    lv_yaml = zcl_ayaml=>create_from_abap( iv_data   = ls_in
                                           iv_format = zif_ayaml_types=>cs_format-snake_case )->to_yaml( ).

    lo_cut = zcl_ayaml=>create_from_yaml( lv_yaml ).
    lo_cut->to_abap( IMPORTING ev_data = ls_out ).

    cl_abap_unit_assert=>assert_equals( exp = ls_in-order_id
                                        act = ls_out-order_id ).
    cl_abap_unit_assert=>assert_equals( exp = ls_in-customer
                                        act = ls_out-customer ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( ls_out-subitems ) ).

    READ TABLE ls_out-subitems INDEX 1 ASSIGNING <fs_sub>.
    cl_abap_unit_assert=>assert_subrc( exp = 0 ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = <fs_sub>-sub_id ).
    cl_abap_unit_assert=>assert_equals( exp = 'Widget A'
                                        act = <fs_sub>-sub_name ).
  ENDMETHOD.

  METHOD test_syntax_error_validations.
    DATA lo_doc TYPE REF TO zif_ayaml.
    DATA lv_tab TYPE c LENGTH 1.

    lv_tab = cl_abap_char_utilities=>horizontal_tab.

    " Tab in indentation must be rejected
    TRY.
        zcl_ayaml=>create_from_yaml( |root:\n{ lv_tab }child: val| ).
        cl_abap_unit_assert=>fail( 'Expected syntax error for tab indentation' ).
      CATCH zcx_ayaml_error.
    ENDTRY.

    " Unclosed double quote
    TRY.
        zcl_ayaml=>create_from_yaml( |name: "unclosed string\n| ).
        cl_abap_unit_assert=>fail( 'Expected syntax error for unclosed double quote' ).
      CATCH zcx_ayaml_error.
    ENDTRY.

    " Unclosed flow sequence
    TRY.
        zcl_ayaml=>create_from_yaml( |items: [1, 2, 3\n| ).
        cl_abap_unit_assert=>fail( 'Expected error for unclosed flow sequence' ).
      CATCH zcx_ayaml_error.
    ENDTRY.

    " Push to a non-sequence node
    lo_doc = zcl_ayaml=>create_empty( ).
    lo_doc->set_string( iv_path  = '/name'
                        iv_value = 'Alice' ).
    TRY.
        lo_doc->push( iv_path  = '/name'
                      iv_value = 'invalid' ).
        cl_abap_unit_assert=>fail( 'Expected error pushing to non-sequence' ).
      CATCH zcx_ayaml_error.
    ENDTRY.

    " Parse invalid date
    TRY.
        zcl_ayaml_utils=>parse_date( 'invalid-date' ).
        cl_abap_unit_assert=>fail( 'Expected error for invalid date' ).
      CATCH zcx_ayaml_error.
    ENDTRY.

    " Parse invalid timestamp
    TRY.
        zcl_ayaml_utils=>parse_timestamp( 'invalid-timestamp' ).
        cl_abap_unit_assert=>fail( 'Expected error for invalid timestamp' ).
      CATCH zcx_ayaml_error.
    ENDTRY.
  ENDMETHOD.

  METHOD test_document_reconstruction.
    DATA lo_doc    TYPE REF TO zif_ayaml.
    DATA lv_yaml   TYPE string.
    DATA lo_parsed TYPE REF TO zif_ayaml.

    lo_doc = zcl_ayaml=>create_empty( ).
    lo_doc->set_string( iv_path  = '/service/name'
                        iv_value = 'auth-service' ).
    lo_doc->set_integer( iv_path  = '/service/port'
                         iv_value = 9000 ).
    lo_doc->set_boolean( iv_path  = '/service/ssl'
                         iv_value = abap_true ).
    lo_doc->set_null( '/service/backup' ).
    lo_doc->init_array( '/service/clusters' ).
    lo_doc->push( iv_path  = '/service/clusters'
                  iv_value = 'eu-west' ).
    lo_doc->push( iv_path  = '/service/clusters'
                  iv_value = 'us-east' ).

    lv_yaml = lo_doc->to_yaml( 1 ).

    lo_parsed = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_equals( exp = 'auth-service'
                                        act = lo_parsed->get_string( '/service/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 9000
                                        act = lo_parsed->get_integer( '/service/port' ) ).
    cl_abap_unit_assert=>assert_true( lo_parsed->get_boolean( '/service/ssl' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ayaml_types=>cs_type-null
                                        act = lo_parsed->get_node_type( '/service/backup' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_parsed->get_array_length( '/service/clusters' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'eu-west'
                                        act = lo_parsed->get_string( '/service/clusters/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'us-east'
                                        act = lo_parsed->get_string( '/service/clusters/2' ) ).
  ENDMETHOD.
ENDCLASS.


CLASS ltcl_ayaml_writer_suite DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    DATA mo_cut TYPE REF TO zif_ayaml.

    TYPES: BEGIN OF ty_flat_item,
             id     TYPE i,
             name   TYPE string,
             active TYPE abap_bool,
           END OF ty_flat_item,
           ty_t_flat_items TYPE STANDARD TABLE OF ty_flat_item WITH DEFAULT KEY.
    TYPES: BEGIN OF ty_nested_config,
             title TYPE string,
             item  TYPE ty_flat_item,
           END OF ty_nested_config.

    METHODS setup.
    METHODS test_writer_primitives        FOR TESTING RAISING cx_static_check.
    METHODS test_writer_deep_auto_path    FOR TESTING RAISING cx_static_check.
    METHODS test_writer_seq_primitives    FOR TESTING RAISING cx_static_check.
    METHODS test_writer_seq_of_mappings   FOR TESTING RAISING cx_static_check.
    METHODS test_writer_mapping_of_seqs   FOR TESTING RAISING cx_static_check.
    METHODS test_writer_type_overwrite    FOR TESTING RAISING cx_static_check.
    METHODS test_writer_delete_leaf       FOR TESTING RAISING cx_static_check.
    METHODS test_writer_delete_branch     FOR TESTING RAISING cx_static_check.
    METHODS test_writer_clear_and_rebuild FOR TESTING RAISING cx_static_check.
    METHODS test_writer_clone_indep       FOR TESTING RAISING cx_static_check.
    METHODS test_writer_slice_and_export  FOR TESTING RAISING cx_static_check.
    METHODS test_writer_indent_levels     FOR TESTING RAISING cx_static_check.
    METHODS test_writer_special_chars     FOR TESTING RAISING cx_static_check.
    METHODS test_writer_empty_strings     FOR TESTING RAISING cx_static_check.
    METHODS test_writer_boolean_types     FOR TESTING RAISING cx_static_check.
    METHODS test_writer_numeric_types     FOR TESTING RAISING cx_static_check.
    METHODS test_writer_date_and_time     FOR TESTING RAISING cx_static_check.
    METHODS test_writer_keys_with_dashes  FOR TESTING RAISING cx_static_check.
    METHODS test_writer_reinit_array      FOR TESTING RAISING cx_static_check.
    METHODS test_writer_from_abap_flat    FOR TESTING RAISING cx_static_check.
    METHODS test_writer_from_abap_nested  FOR TESTING RAISING cx_static_check.
    METHODS test_writer_from_abap_table   FOR TESTING RAISING cx_static_check.
    METHODS test_writer_touch_array_empty FOR TESTING RAISING cx_static_check.
    METHODS test_writer_key_ordering      FOR TESTING RAISING cx_static_check.
    METHODS test_writer_multi_level_array FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltcl_ayaml_writer_suite IMPLEMENTATION.
  METHOD setup.
    mo_cut = zcl_ayaml=>create_empty( ).
  ENDMETHOD.

  METHOD test_writer_primitives.
    DATA lv_yaml   TYPE string.
    DATA lo_parsed TYPE REF TO zif_ayaml.

    mo_cut->set_string( iv_path  = '/title'
                        iv_value = 'YAML Writer Test' ).
    mo_cut->set_integer( iv_path  = '/code'
                         iv_value = 200 ).
    mo_cut->set_boolean( iv_path  = '/is_active'
                         iv_value = abap_true ).
    mo_cut->set_null( '/description' ).

    lv_yaml = mo_cut->to_yaml( 1 ).
    lo_parsed = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_equals( exp = 'YAML Writer Test'
                                        act = lo_parsed->get_string( '/title' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 200
                                        act = lo_parsed->get_integer( '/code' ) ).
    cl_abap_unit_assert=>assert_true( lo_parsed->get_boolean( '/is_active' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ayaml_types=>cs_type-null
                                        act = lo_parsed->get_node_type( '/description' ) ).
  ENDMETHOD.

  METHOD test_writer_deep_auto_path.
    DATA lv_yaml   TYPE string.
    DATA lo_parsed TYPE REF TO zif_ayaml.

    mo_cut->set_integer( iv_path  = '/deeply/nested/service/timeout'
                         iv_value = 450 ).

    lv_yaml = mo_cut->to_yaml( ).
    lo_parsed = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_true( lo_parsed->exists( '/deeply' ) ).
    cl_abap_unit_assert=>assert_true( lo_parsed->exists( '/deeply/nested' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 450
                                        act = lo_parsed->get_integer( '/deeply/nested/service/timeout' ) ).
  ENDMETHOD.

  METHOD test_writer_seq_primitives.
    DATA lv_yaml   TYPE string.
    DATA lo_parsed TYPE REF TO zif_ayaml.

    mo_cut->init_array( '/tags' ).
    mo_cut->push( iv_path  = '/tags'
                  iv_value = 'admin' ).
    mo_cut->push( iv_path  = '/tags'
                  iv_value = 'operator' ).
    mo_cut->push( iv_path  = '/tags'
                  iv_value = 'developer' ).

    lv_yaml = mo_cut->to_yaml( 1 ).
    lo_parsed = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lo_parsed->get_array_length( '/tags' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'admin'
                                        act = lo_parsed->get_string( '/tags/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'operator'
                                        act = lo_parsed->get_string( '/tags/2' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'developer'
                                        act = lo_parsed->get_string( '/tags/3' ) ).
  ENDMETHOD.

  METHOD test_writer_seq_of_mappings.
    DATA lv_yaml   TYPE string.
    DATA lo_parsed TYPE REF TO zif_ayaml.

    mo_cut->init_array( '/users' ).
    mo_cut->set_string( iv_path  = '/users/1/name'
                        iv_value = 'Alice' ).
    mo_cut->set_string( iv_path  = '/users/1/role'
                        iv_value = 'Architect' ).
    mo_cut->set_string( iv_path  = '/users/2/name'
                        iv_value = 'Bob' ).
    mo_cut->set_string( iv_path  = '/users/2/role'
                        iv_value = 'Engineer' ).

    lv_yaml = mo_cut->to_yaml( 1 ).
    lo_parsed = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_parsed->get_array_length( '/users' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'Alice'
                                        act = lo_parsed->get_string( '/users/1/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'Architect'
                                        act = lo_parsed->get_string( '/users/1/role' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'Bob'
                                        act = lo_parsed->get_string( '/users/2/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'Engineer'
                                        act = lo_parsed->get_string( '/users/2/role' ) ).
  ENDMETHOD.

  METHOD test_writer_mapping_of_seqs.
    DATA lv_yaml   TYPE string.
    DATA lo_parsed TYPE REF TO zif_ayaml.

    mo_cut->init_array( '/matrix/row1' ).
    mo_cut->push( iv_path  = '/matrix/row1'
                  iv_value = 10 ).
    mo_cut->push( iv_path  = '/matrix/row1'
                  iv_value = 20 ).

    mo_cut->init_array( '/matrix/row2' ).
    mo_cut->push( iv_path  = '/matrix/row2'
                  iv_value = 30 ).
    mo_cut->push( iv_path  = '/matrix/row2'
                  iv_value = 40 ).

    lv_yaml = mo_cut->to_yaml( 1 ).
    lo_parsed = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_parsed->get_array_length( '/matrix/row1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 10
                                        act = lo_parsed->get_integer( '/matrix/row1/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 20
                                        act = lo_parsed->get_integer( '/matrix/row1/2' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 30
                                        act = lo_parsed->get_integer( '/matrix/row2/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 40
                                        act = lo_parsed->get_integer( '/matrix/row2/2' ) ).
  ENDMETHOD.

  METHOD test_writer_type_overwrite.
    DATA lv_yaml   TYPE string.
    DATA lo_parsed TYPE REF TO zif_ayaml.

    mo_cut->set_integer( iv_path  = '/config/mode'
                         iv_value = 99 ).
    mo_cut->set_string( iv_path  = '/config/mode'
                        iv_value = 'cluster' ).

    lv_yaml = mo_cut->to_yaml( 1 ).
    lo_parsed = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_equals( exp = 'cluster'
                                        act = lo_parsed->get_string( '/config/mode' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ayaml_types=>cs_type-string
                                        act = lo_parsed->get_node_type( '/config/mode' ) ).
  ENDMETHOD.

  METHOD test_writer_delete_leaf.
    DATA lv_yaml   TYPE string.
    DATA lo_parsed TYPE REF TO zif_ayaml.

    mo_cut->set_string( iv_path  = '/settings/theme'
                        iv_value = 'dark' ).
    mo_cut->set_string( iv_path  = '/settings/font'
                        iv_value = 'monospace' ).
    mo_cut->delete( '/settings/font' ).

    lv_yaml = mo_cut->to_yaml( 1 ).
    lo_parsed = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_true( lo_parsed->exists( '/settings/theme' ) ).
    cl_abap_unit_assert=>assert_false( lo_parsed->exists( '/settings/font' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'dark'
                                        act = lo_parsed->get_string( '/settings/theme' ) ).
  ENDMETHOD.

  METHOD test_writer_delete_branch.
    DATA lv_yaml   TYPE string.
    DATA lo_parsed TYPE REF TO zif_ayaml.

    mo_cut->set_string( iv_path  = '/infra/aws/region'
                        iv_value = 'us-east-1' ).
    mo_cut->set_string( iv_path  = '/infra/aws/vpc'
                        iv_value = 'vpc-abc' ).
    mo_cut->set_string( iv_path  = '/infra/gcp/project'
                        iv_value = 'gcp-proj' ).

    mo_cut->delete( '/infra/aws' ).

    lv_yaml = mo_cut->to_yaml( 1 ).
    lo_parsed = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_false( lo_parsed->exists( '/infra/aws' ) ).
    cl_abap_unit_assert=>assert_false( lo_parsed->exists( '/infra/aws/region' ) ).
    cl_abap_unit_assert=>assert_true( lo_parsed->exists( '/infra/gcp/project' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'gcp-proj'
                                        act = lo_parsed->get_string( '/infra/gcp/project' ) ).
  ENDMETHOD.

  METHOD test_writer_clear_and_rebuild.
    DATA lv_yaml   TYPE string.
    DATA lo_parsed TYPE REF TO zif_ayaml.

    mo_cut->set_string( iv_path  = '/old_key'
                        iv_value = 'old_val' ).
    mo_cut->clear( ).
    cl_abap_unit_assert=>assert_true( mo_cut->is_empty( ) ).

    mo_cut->set_string( iv_path  = '/new_key'
                        iv_value = 'new_val' ).

    lv_yaml = mo_cut->to_yaml( 1 ).
    lo_parsed = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_false( lo_parsed->exists( '/old_key' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'new_val'
                                        act = lo_parsed->get_string( '/new_key' ) ).
  ENDMETHOD.

  METHOD test_writer_clone_indep.
    DATA lo_clone TYPE REF TO zif_ayaml.
    DATA lv_yaml1 TYPE string.
    DATA lv_yaml2 TYPE string.
    DATA lo_p1    TYPE REF TO zif_ayaml.
    DATA lo_p2    TYPE REF TO zif_ayaml.

    mo_cut->set_string( iv_path  = '/app/version'
                        iv_value = '1.0.0' ).
    lo_clone = mo_cut->clone( ).

    lo_clone->set_string( iv_path  = '/app/version'
                          iv_value = '2.0.0' ).
    lo_clone->set_boolean( iv_path  = '/app/beta'
                           iv_value = abap_true ).

    lv_yaml1 = mo_cut->to_yaml( 1 ).
    lv_yaml2 = lo_clone->to_yaml( 1 ).

    lo_p1 = zcl_ayaml=>create_from_yaml( lv_yaml1 ).
    lo_p2 = zcl_ayaml=>create_from_yaml( lv_yaml2 ).

    cl_abap_unit_assert=>assert_equals( exp = '1.0.0'
                                        act = lo_p1->get_string( '/app/version' ) ).
    cl_abap_unit_assert=>assert_false( lo_p1->exists( '/app/beta' ) ).

    cl_abap_unit_assert=>assert_equals( exp = '2.0.0'
                                        act = lo_p2->get_string( '/app/version' ) ).
    cl_abap_unit_assert=>assert_true( lo_p2->get_boolean( '/app/beta' ) ).
  ENDMETHOD.

  METHOD test_writer_slice_and_export.
    DATA lo_slice  TYPE REF TO zif_ayaml.
    DATA lv_yaml   TYPE string.
    DATA lo_parsed TYPE REF TO zif_ayaml.

    mo_cut->set_string( iv_path  = '/corp/dept/dev/lead'
                        iv_value = 'Grace' ).
    mo_cut->set_integer( iv_path  = '/corp/dept/dev/members'
                         iv_value = 12 ).

    lo_slice = mo_cut->slice( '/corp/dept/dev' ).
    lv_yaml = lo_slice->to_yaml( 1 ).
    lo_parsed = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_equals( exp = 'Grace'
                                        act = lo_parsed->get_string( '/lead' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 12
                                        act = lo_parsed->get_integer( '/members' ) ).
  ENDMETHOD.

  METHOD test_writer_indent_levels.
    DATA lv_yaml0 TYPE string.
    DATA lv_yaml2 TYPE string.
    DATA lo_p0    TYPE REF TO zif_ayaml.
    DATA lo_p2    TYPE REF TO zif_ayaml.

    mo_cut->set_string( iv_path  = '/server/host'
                        iv_value = '127.0.0.1' ).
    mo_cut->set_integer( iv_path  = '/server/port'
                         iv_value = 8080 ).

    lv_yaml0 = mo_cut->to_yaml( 0 ).
    lv_yaml2 = mo_cut->to_yaml( 2 ).

    lo_p0 = zcl_ayaml=>create_from_yaml( lv_yaml0 ).
    lo_p2 = zcl_ayaml=>create_from_yaml( lv_yaml2 ).

    cl_abap_unit_assert=>assert_equals( exp = '127.0.0.1'
                                        act = lo_p0->get_string( '/server/host' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 8080
                                        act = lo_p2->get_integer( '/server/port' ) ).
  ENDMETHOD.

  METHOD test_writer_special_chars.
    DATA lv_yaml   TYPE string.
    DATA lo_parsed TYPE REF TO zif_ayaml.

    mo_cut->set_string( iv_path  = '/url'
                        iv_value = 'http://example.com:8080/path' ).
    mo_cut->set_string( iv_path  = '/color'
                        iv_value = '#ff00aa' ).
    mo_cut->set_string( iv_path  = '/brackets'
                        iv_value = '[test]' ).

    lv_yaml = mo_cut->to_yaml( 1 ).
    lo_parsed = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_equals( exp = 'http://example.com:8080/path'
                                        act = lo_parsed->get_string( '/url' ) ).
    cl_abap_unit_assert=>assert_equals( exp = '#ff00aa'
                                        act = lo_parsed->get_string( '/color' ) ).
    cl_abap_unit_assert=>assert_equals( exp = '[test]'
                                        act = lo_parsed->get_string( '/brackets' ) ).
  ENDMETHOD.

  METHOD test_writer_empty_strings.
    DATA lv_yaml   TYPE string.
    DATA lo_parsed TYPE REF TO zif_ayaml.

    mo_cut->set_string( iv_path  = '/empty_val'
                        iv_value = '' ).

    lv_yaml = mo_cut->to_yaml( 1 ).
    lo_parsed = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_true( lo_parsed->exists( '/empty_val' ) ).
    cl_abap_unit_assert=>assert_equals( exp = ''
                                        act = lo_parsed->get_string( '/empty_val' ) ).
  ENDMETHOD.

  METHOD test_writer_boolean_types.
    DATA lv_yaml   TYPE string.
    DATA lo_parsed TYPE REF TO zif_ayaml.

    mo_cut->set_boolean( iv_path  = '/flags/enabled'
                         iv_value = abap_true ).
    mo_cut->set_boolean( iv_path  = '/flags/disabled'
                         iv_value = abap_false ).

    lv_yaml = mo_cut->to_yaml( 1 ).
    lo_parsed = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_true( lo_parsed->get_boolean( '/flags/enabled' ) ).
    cl_abap_unit_assert=>assert_false( lo_parsed->get_boolean( '/flags/disabled' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ayaml_types=>cs_type-boolean
                                        act = lo_parsed->get_node_type( '/flags/enabled' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ayaml_types=>cs_type-boolean
                                        act = lo_parsed->get_node_type( '/flags/disabled' ) ).
  ENDMETHOD.

  METHOD test_writer_numeric_types.
    DATA lv_yaml   TYPE string.
    DATA lo_parsed TYPE REF TO zif_ayaml.

    mo_cut->set_integer( iv_path  = '/nums/negative'
                         iv_value = -42 ).
    mo_cut->set_integer( iv_path  = '/nums/zero'
                         iv_value = 0 ).
    mo_cut->set_integer( iv_path  = '/nums/positive'
                         iv_value = 9999 ).

    lv_yaml = mo_cut->to_yaml( 1 ).
    lo_parsed = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_equals( exp = -42
                                        act = lo_parsed->get_integer( '/nums/negative' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = lo_parsed->get_integer( '/nums/zero' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 9999
                                        act = lo_parsed->get_integer( '/nums/positive' ) ).
  ENDMETHOD.

  METHOD test_writer_date_and_time.
    DATA lv_date   TYPE d VALUE '20260921'.
    DATA lv_yaml   TYPE string.
    DATA lo_parsed TYPE REF TO zif_ayaml.

    mo_cut->set_date( iv_path  = '/release_date'
                      iv_value = lv_date ).

    lv_yaml = mo_cut->to_yaml( 1 ).
    lo_parsed = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_equals( exp = lv_date
                                        act = lo_parsed->get_date( '/release_date' ) ).
  ENDMETHOD.

  METHOD test_writer_keys_with_dashes.
    DATA lv_yaml   TYPE string.
    DATA lo_parsed TYPE REF TO zif_ayaml.

    mo_cut->set_string( iv_path  = '/app-config/server-name'
                        iv_value = 'prod-api' ).
    mo_cut->set_integer( iv_path  = '/app-config/max-connections'
                         iv_value = 100 ).

    lv_yaml = mo_cut->to_yaml( 1 ).
    lo_parsed = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_equals( exp = 'prod-api'
                                        act = lo_parsed->get_string( '/app-config/server-name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 100
                                        act = lo_parsed->get_integer( '/app-config/max-connections' ) ).
  ENDMETHOD.

  METHOD test_writer_reinit_array.
    DATA lv_yaml   TYPE string.
    DATA lo_parsed TYPE REF TO zif_ayaml.

    mo_cut->init_array( '/items' ).
    mo_cut->push( iv_path  = '/items'
                  iv_value = 'item1' ).
    mo_cut->push( iv_path  = '/items'
                  iv_value = 'item2' ).

    mo_cut->init_array( iv_path  = '/items'
                        iv_clear = abap_true ).
    mo_cut->push( iv_path  = '/items'
                  iv_value = 'item_reinit' ).

    lv_yaml = mo_cut->to_yaml( 1 ).
    lo_parsed = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lo_parsed->get_array_length( '/items' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'item_reinit'
                                        act = lo_parsed->get_string( '/items/1' ) ).
  ENDMETHOD.

  METHOD test_writer_from_abap_flat.
    DATA ls_in     TYPE ty_flat_item.
    DATA ls_out    TYPE ty_flat_item.
    DATA lv_yaml   TYPE string.
    DATA lo_yaml   TYPE REF TO zif_ayaml.
    DATA lo_parsed TYPE REF TO zif_ayaml.

    ls_in-id     = 101.
    ls_in-name   = 'Standard Item'.
    ls_in-active = abap_true.

    lo_yaml = zcl_ayaml=>create_from_abap( ls_in ).
    lv_yaml = lo_yaml->to_yaml( 1 ).

    lo_parsed = zcl_ayaml=>create_from_yaml( lv_yaml ).
    lo_parsed->to_abap( IMPORTING ev_data = ls_out ).

    cl_abap_unit_assert=>assert_equals( exp = 101
                                        act = ls_out-id ).
    cl_abap_unit_assert=>assert_equals( exp = 'Standard Item'
                                        act = ls_out-name ).
    cl_abap_unit_assert=>assert_true( ls_out-active ).
  ENDMETHOD.

  METHOD test_writer_from_abap_nested.
    DATA ls_in     TYPE ty_nested_config.
    DATA ls_out    TYPE ty_nested_config.
    DATA lv_yaml   TYPE string.
    DATA lo_yaml   TYPE REF TO zif_ayaml.
    DATA lo_parsed TYPE REF TO zif_ayaml.

    ls_in-title = 'Root Section'.
    ls_in-item-id     = 505.
    ls_in-item-name   = 'Child Item'.
    ls_in-item-active = abap_true.

    lo_yaml = zcl_ayaml=>create_from_abap( ls_in ).
    lv_yaml = lo_yaml->to_yaml( 1 ).

    lo_parsed = zcl_ayaml=>create_from_yaml( lv_yaml ).
    lo_parsed->to_abap( IMPORTING ev_data = ls_out ).

    cl_abap_unit_assert=>assert_equals( exp = 'Root Section'
                                        act = ls_out-title ).
    cl_abap_unit_assert=>assert_equals( exp = 505
                                        act = ls_out-item-id ).
    cl_abap_unit_assert=>assert_equals( exp = 'Child Item'
                                        act = ls_out-item-name ).
  ENDMETHOD.

  METHOD test_writer_from_abap_table.
    DATA lt_in     TYPE ty_t_flat_items.
    DATA lt_out    TYPE ty_t_flat_items.
    DATA ls_row    TYPE ty_flat_item.
    DATA lv_yaml   TYPE string.
    DATA lo_yaml   TYPE REF TO zif_ayaml.
    DATA lo_parsed TYPE REF TO zif_ayaml.

    ls_row-id     = 1.
    ls_row-name   = 'First'.
    ls_row-active = abap_true.
    APPEND ls_row TO lt_in.

    ls_row-id     = 2.
    ls_row-name   = 'Second'.
    ls_row-active = abap_false.
    APPEND ls_row TO lt_in.

    lo_yaml = zcl_ayaml=>create_from_abap( lt_in ).
    lv_yaml = lo_yaml->to_yaml( 1 ).

    lo_parsed = zcl_ayaml=>create_from_yaml( lv_yaml ).
    lo_parsed->to_abap( IMPORTING ev_data = lt_out ).

    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( lt_out ) ).
    READ TABLE lt_out INDEX 1 INTO ls_row.
    cl_abap_unit_assert=>assert_subrc( ).
    cl_abap_unit_assert=>assert_equals( exp = 'First'
                                        act = ls_row-name ).
    READ TABLE lt_out INDEX 2 INTO ls_row.
    cl_abap_unit_assert=>assert_subrc( ).
    cl_abap_unit_assert=>assert_equals( exp = 'Second'
                                        act = ls_row-name ).
  ENDMETHOD.

  METHOD test_writer_touch_array_empty.
    DATA lv_yaml   TYPE string.
    DATA lo_parsed TYPE REF TO zif_ayaml.

    mo_cut->init_array( '/empty_list' ).

    lv_yaml = mo_cut->to_yaml( 1 ).
    lo_parsed = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_true( lo_parsed->exists( '/empty_list' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = lo_parsed->get_array_length( '/empty_list' ) ).
  ENDMETHOD.

  METHOD test_writer_key_ordering.
    DATA lt_keys TYPE zif_ayaml_types=>ty_t_string.
    DATA lv_k1   TYPE string.
    DATA lv_k2   TYPE string.
    DATA lv_k3   TYPE string.

    mo_cut->set_string( iv_path  = '/alpha'
                        iv_value = '1' ).
    mo_cut->set_string( iv_path  = '/beta'
                        iv_value = '2' ).
    mo_cut->set_string( iv_path  = '/gamma'
                        iv_value = '3' ).

    lt_keys = mo_cut->get_keys( '/' ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lines( lt_keys ) ).
    READ TABLE lt_keys INDEX 1 INTO lv_k1.
    cl_abap_unit_assert=>assert_subrc( ).
    READ TABLE lt_keys INDEX 2 INTO lv_k2.
    cl_abap_unit_assert=>assert_subrc( ).
    READ TABLE lt_keys INDEX 3 INTO lv_k3.
    cl_abap_unit_assert=>assert_subrc( ).

    cl_abap_unit_assert=>assert_equals( exp = 'alpha'
                                        act = lv_k1 ).
    cl_abap_unit_assert=>assert_equals( exp = 'beta'
                                        act = lv_k2 ).
    cl_abap_unit_assert=>assert_equals( exp = 'gamma'
                                        act = lv_k3 ).
  ENDMETHOD.

  METHOD test_writer_multi_level_array.
    DATA lv_yaml   TYPE string.
    DATA lo_parsed TYPE REF TO zif_ayaml.

    mo_cut->init_array( '/pipeline' ).
    mo_cut->set_string( iv_path  = '/pipeline/1/name'
                        iv_value = 'Build' ).
    mo_cut->init_array( '/pipeline/1/steps' ).
    mo_cut->push( iv_path  = '/pipeline/1/steps'
                  iv_value = 'compile' ).
    mo_cut->push( iv_path  = '/pipeline/1/steps'
                  iv_value = 'package' ).

    mo_cut->set_string( iv_path  = '/pipeline/2/name'
                        iv_value = 'Deploy' ).
    mo_cut->init_array( '/pipeline/2/steps' ).
    mo_cut->push( iv_path  = '/pipeline/2/steps'
                  iv_value = 'upload' ).

    lv_yaml = mo_cut->to_yaml( 1 ).
    lo_parsed = zcl_ayaml=>create_from_yaml( lv_yaml ).

    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_parsed->get_array_length( '/pipeline' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'Build'
                                        act = lo_parsed->get_string( '/pipeline/1/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_parsed->get_array_length( '/pipeline/1/steps' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'compile'
                                        act = lo_parsed->get_string( '/pipeline/1/steps/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'upload'
                                        act = lo_parsed->get_string( '/pipeline/2/steps/1' ) ).
  ENDMETHOD.
ENDCLASS.


CLASS ltcl_ayaml_realworld_specs DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_entry,
        key   TYPE string,
        value TYPE i,
      END OF ty_entry,
      ty_t_entry TYPE STANDARD TABLE OF ty_entry WITH DEFAULT KEY.

    METHODS test_spec_github_ci_workflow   FOR TESTING RAISING cx_static_check.
    METHODS test_spec_docker_compose       FOR TESTING RAISING cx_static_check.
    METHODS test_spec_openapi_v3           FOR TESTING RAISING cx_static_check.
    METHODS test_spec_k8s_deployment       FOR TESTING RAISING cx_static_check.
    METHODS test_spec_k8s_ingress          FOR TESTING RAISING cx_static_check.
    METHODS test_spec_prometheus_alerts    FOR TESTING RAISING cx_static_check.
    METHODS test_spec_ansible_playbook     FOR TESTING RAISING cx_static_check.
    METHODS test_spec_helm_values          FOR TESTING RAISING cx_static_check.
    METHODS test_spec_gitlab_ci            FOR TESTING RAISING cx_static_check.
    METHODS test_spec_travis_ci            FOR TESTING RAISING cx_static_check.
    METHODS test_spec_elasticsearch_conf   FOR TESTING RAISING cx_static_check.
    METHODS test_spec_spring_application   FOR TESTING RAISING cx_static_check.
    METHODS test_spec_serverless_yaml      FOR TESTING RAISING cx_static_check.
    METHODS test_spec_nginx_reverse_proxy  FOR TESTING RAISING cx_static_check.
    METHODS test_spec_logstash_pipeline    FOR TESTING RAISING cx_static_check.
    METHODS test_spec_argocd_application   FOR TESTING RAISING cx_static_check.
    METHODS test_spec_dependabot_config    FOR TESTING RAISING cx_static_check.
    METHODS test_spec_cloudformation_yaml  FOR TESTING RAISING cx_static_check.
    METHODS test_spec_drone_ci_pipeline    FOR TESTING RAISING cx_static_check.
    METHODS test_spec_package_manifest     FOR TESTING RAISING cx_static_check.
    METHODS test_spec_anchor_merge_prod    FOR TESTING RAISING cx_static_check.
    METHODS test_spec_deep_table_roundtrip FOR TESTING RAISING cx_static_check.
    METHODS test_spec_flow_block_mixture   FOR TESTING RAISING cx_static_check.
    METHODS test_spec_multi_env_config     FOR TESTING RAISING cx_static_check.
    METHODS test_spec_writer_reader_e2e    FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltcl_ayaml_realworld_specs IMPLEMENTATION.
  METHOD test_spec_github_ci_workflow.
    DATA lv_yaml   TYPE string.
    DATA lo_doc    TYPE REF TO zif_ayaml.
    DATA lv_out    TYPE string.
    DATA lo_parsed TYPE REF TO zif_ayaml.

    lv_yaml =
      |name: CI Pipeline\n| &&
      |on:\n| &&
      |  push:\n| &&
      |    branches:\n| &&
      |      - main\n| &&
      |      - release/*\n| &&
      |jobs:\n| &&
      |  build:\n| &&
      |    runs-on: ubuntu-latest\n| &&
      |    steps:\n| &&
      |      - name: Checkout\n| &&
      |        uses: actions/checkout@v3\n| &&
      |      - name: Test\n| &&
      |        run: npm test|.

    lo_doc = zcl_ayaml=>create_from_yaml( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 'CI Pipeline'
                                        act = lo_doc->get_string( '/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'ubuntu-latest'
                                        act = lo_doc->get_string( '/jobs/build/runs-on' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_doc->get_array_length( '/on/push/branches' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'main'
                                        act = lo_doc->get_string( '/on/push/branches/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_doc->get_array_length( '/jobs/build/steps' ) ).

    lo_doc->set_string( iv_path  = '/jobs/build/runs-on'
                        iv_value = 'ubuntu-22.04' ).
    lv_out = lo_doc->to_yaml( 1 ).
    lo_parsed = zcl_ayaml=>create_from_yaml( lv_out ).
    cl_abap_unit_assert=>assert_equals( exp = 'ubuntu-22.04'
                                        act = lo_parsed->get_string( '/jobs/build/runs-on' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'npm test'
                                        act = lo_parsed->get_string( '/jobs/build/steps/2/run' ) ).
  ENDMETHOD.

  METHOD test_spec_docker_compose.
    DATA lv_yaml   TYPE string.
    DATA lo_doc    TYPE REF TO zif_ayaml.
    DATA lv_out    TYPE string.
    DATA lo_parsed TYPE REF TO zif_ayaml.

    lv_yaml =
      |version: '3.8'\n| &&
      |services:\n| &&
      |  web:\n| &&
      |    image: nginx:alpine\n| &&
      |    ports:\n| &&
      |      - 80:80\n| &&
      |      - 443:443\n| &&
      |    restart: always\n| &&
      |  redis:\n| &&
      |    image: redis:7-alpine\n| &&
      |    ports:\n| &&
      |      - 6379:6379|.

    lo_doc = zcl_ayaml=>create_from_yaml( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = '3.8'
                                        act = lo_doc->get_string( '/version' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'nginx:alpine'
                                        act = lo_doc->get_string( '/services/web/image' ) ).
    cl_abap_unit_assert=>assert_equals( exp = '80:80'
                                        act = lo_doc->get_string( '/services/web/ports/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'always'
                                        act = lo_doc->get_string( '/services/web/restart' ) ).

    lo_doc->init_array( '/services/web/environment' ).
    lo_doc->push( iv_path  = '/services/web/environment'
                  iv_value = 'NODE_ENV=production' ).
    lv_out = lo_doc->to_yaml( 1 ).
    lo_parsed = zcl_ayaml=>create_from_yaml( lv_out ).
    cl_abap_unit_assert=>assert_equals( exp = 'NODE_ENV=production'
                                        act = lo_parsed->get_string( '/services/web/environment/1' ) ).
  ENDMETHOD.

  METHOD test_spec_openapi_v3.
    DATA lv_yaml TYPE string.
    DATA lo_doc  TYPE REF TO zif_ayaml.

    lv_yaml =
      |openapi: 3.0.3\n| &&
      |info:\n| &&
      |  title: User Service API\n| &&
      |  version: 1.0.0\n| &&
      |paths:\n| &&
      |  /users:\n| &&
      |    get:\n| &&
      |      summary: Returns user list\n| &&
      |      responses:\n| &&
      |        '200':\n| &&
      |          description: Successful response|.

    lo_doc = zcl_ayaml=>create_from_yaml( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = '3.0.3'
                                        act = lo_doc->get_string( '/openapi' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'User Service API'
                                        act = lo_doc->get_string( '/info/title' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'Returns user list'
                                        act = lo_doc->get_string( '/paths//users/get/summary' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'Successful response'
                                        act = lo_doc->get_string( '/paths//users/get/responses/200/description' ) ).
  ENDMETHOD.

  METHOD test_spec_k8s_deployment.
    DATA lv_yaml   TYPE string.
    DATA lo_doc    TYPE REF TO zif_ayaml.
    DATA lv_out    TYPE string.
    DATA lo_parsed TYPE REF TO zif_ayaml.

    lv_yaml =
      |apiVersion: apps/v1\n| &&
      |kind: Deployment\n| &&
      |metadata:\n| &&
      |  name: backend-api\n| &&
      |  labels:\n| &&
      |    app: backend\n| &&
      |spec:\n| &&
      |  replicas: 3\n| &&
      |  selector:\n| &&
      |    matchLabels:\n| &&
      |      app: backend\n| &&
      |  template:\n| &&
      |    metadata:\n| &&
      |      labels:\n| &&
      |        app: backend\n| &&
      |    spec:\n| &&
      |      containers:\n| &&
      |        - name: server\n| &&
      |          image: backend:v1.2.0\n| &&
      |          ports:\n| &&
      |            - containerPort: 8080|.

    lo_doc = zcl_ayaml=>create_from_yaml( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 'apps/v1'
                                        act = lo_doc->get_string( '/apiVersion' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lo_doc->get_integer( '/spec/replicas' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 8080
                                        act = lo_doc->get_integer(
                                                  '/spec/template/spec/containers/1/ports/1/containerPort' ) ).

    lo_doc->set_integer( iv_path  = '/spec/replicas'
                         iv_value = 5 ).
    lv_out = lo_doc->to_yaml( 1 ).
    lo_parsed = zcl_ayaml=>create_from_yaml( lv_out ).
    cl_abap_unit_assert=>assert_equals( exp = 5
                                        act = lo_parsed->get_integer( '/spec/replicas' ) ).
  ENDMETHOD.

  METHOD test_spec_k8s_ingress.
    DATA lv_yaml TYPE string.
    DATA lo_doc  TYPE REF TO zif_ayaml.

    lv_yaml =
      |apiVersion: networking.k8s.io/v1\n| &&
      |kind: Ingress\n| &&
      |metadata:\n| &&
      |  name: public-gateway\n| &&
      |spec:\n| &&
      |  rules:\n| &&
      |    - host: api.domain.com\n| &&
      |      http:\n| &&
      |        paths:\n| &&
      |          - path: /v1\n| &&
      |            pathType: Prefix\n| &&
      |            backend:\n| &&
      |              service:\n| &&
      |                name: v1-service\n| &&
      |                port:\n| &&
      |                  number: 80|.

    lo_doc = zcl_ayaml=>create_from_yaml( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 'public-gateway'
                                        act = lo_doc->get_string( '/metadata/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'api.domain.com'
                                        act = lo_doc->get_string( '/spec/rules/1/host' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 80
                                        act = lo_doc->get_integer(
                                                  '/spec/rules/1/http/paths/1/backend/service/port/number' ) ).
  ENDMETHOD.

  METHOD test_spec_prometheus_alerts.
    DATA lv_yaml TYPE string.
    DATA lo_doc  TYPE REF TO zif_ayaml.

    lv_yaml =
      |groups:\n| &&
      |  - name: node_alerts\n| &&
      |    rules:\n| &&
      |      - alert: HighCPU\n| &&
      |        expr: node_cpu_utilization > 85\n| &&
      |        for: 10m\n| &&
      |        labels:\n| &&
      |          severity: critical\n| &&
      |        annotations:\n| &&
      |          summary: High CPU detected|.

    lo_doc = zcl_ayaml=>create_from_yaml( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 'node_alerts'
                                        act = lo_doc->get_string( '/groups/1/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'HighCPU'
                                        act = lo_doc->get_string( '/groups/1/rules/1/alert' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'critical'
                                        act = lo_doc->get_string( '/groups/1/rules/1/labels/severity' ) ).
    cl_abap_unit_assert=>assert_equals( exp = '10m'
                                        act = lo_doc->get_string( '/groups/1/rules/1/for' ) ).
  ENDMETHOD.

  METHOD test_spec_ansible_playbook.
    DATA lv_yaml TYPE string.
    DATA lo_doc  TYPE REF TO zif_ayaml.

    lv_yaml =
      |- name: Configure webserver\n| &&
      |  hosts: all\n| &&
      |  become: true\n| &&
      |  tasks:\n| &&
      |    - name: Install nginx\n| &&
      |      apt:\n| &&
      |        name: nginx\n| &&
      |        state: present|.

    lo_doc = zcl_ayaml=>create_from_yaml( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lo_doc->get_array_length( '/' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'Configure webserver'
                                        act = lo_doc->get_string( '/1/name' ) ).
    cl_abap_unit_assert=>assert_true( lo_doc->get_boolean( '/1/become' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'nginx'
                                        act = lo_doc->get_string( '/1/tasks/1/apt/name' ) ).
  ENDMETHOD.

  METHOD test_spec_helm_values.
    DATA lv_yaml TYPE string.
    DATA lo_doc  TYPE REF TO zif_ayaml.

    lv_yaml =
      |replicaCount: 2\n| &&
      |image:\n| &&
      |  repository: myrepo/webapp\n| &&
      |  pullPolicy: IfNotPresent\n| &&
      |  tag: 1.4.2\n| &&
      |resources:\n| &&
      |  limits:\n| &&
      |    cpu: 200m\n| &&
      |    memory: 256Mi\n| &&
      |autoscaling:\n| &&
      |  enabled: false|.

    lo_doc = zcl_ayaml=>create_from_yaml( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_doc->get_integer( '/replicaCount' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'myrepo/webapp'
                                        act = lo_doc->get_string( '/image/repository' ) ).
    cl_abap_unit_assert=>assert_equals( exp = '256Mi'
                                        act = lo_doc->get_string( '/resources/limits/memory' ) ).
    cl_abap_unit_assert=>assert_false( lo_doc->get_boolean( '/autoscaling/enabled' ) ).
  ENDMETHOD.

  METHOD test_spec_gitlab_ci.
    DATA lv_yaml TYPE string.
    DATA lo_doc  TYPE REF TO zif_ayaml.

    lv_yaml =
      |stages:\n| &&
      |  - test\n| &&
      |  - deploy\n| &&
      |variables:\n| &&
      |  APP_ENV: production\n| &&
      |unit-test:\n| &&
      |  stage: test\n| &&
      |  script:\n| &&
      |    - npm test\n| &&
      |    - npm run lint|.

    lo_doc = zcl_ayaml=>create_from_yaml( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_doc->get_array_length( '/stages' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'production'
                                        act = lo_doc->get_string( '/variables/APP_ENV' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'npm run lint'
                                        act = lo_doc->get_string( '/unit-test/script/2' ) ).
  ENDMETHOD.

  METHOD test_spec_travis_ci.
    DATA lv_yaml TYPE string.
    DATA lo_doc  TYPE REF TO zif_ayaml.

    lv_yaml =
      |language: node_js\n| &&
      |node_js:\n| &&
      |  - '18'\n| &&
      |  - '20'\n| &&
      |services:\n| &&
      |  - redis-server\n| &&
      |script:\n| &&
      |  - npm run check|.

    lo_doc = zcl_ayaml=>create_from_yaml( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 'node_js'
                                        act = lo_doc->get_string( '/language' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_doc->get_array_length( '/node_js' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'redis-server'
                                        act = lo_doc->get_string( '/services/1' ) ).
  ENDMETHOD.

  METHOD test_spec_elasticsearch_conf.
    DATA lv_yaml TYPE string.
    DATA lo_doc  TYPE REF TO zif_ayaml.

    lv_yaml =
      |cluster:\n| &&
      |  name: logging-cluster\n| &&
      |node:\n| &&
      |  name: node-master-1\n| &&
      |network:\n| &&
      |  host: 0.0.0.0\n| &&
      |http:\n| &&
      |  port: 9200\n| &&
      |discovery:\n| &&
      |  seed_hosts:\n| &&
      |    - 10.0.0.1\n| &&
      |    - 10.0.0.2|.

    lo_doc = zcl_ayaml=>create_from_yaml( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 'logging-cluster'
                                        act = lo_doc->get_string( '/cluster/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 9200
                                        act = lo_doc->get_integer( '/http/port' ) ).
    cl_abap_unit_assert=>assert_equals( exp = '10.0.0.2'
                                        act = lo_doc->get_string( '/discovery/seed_hosts/2' ) ).
  ENDMETHOD.

  METHOD test_spec_spring_application.
    DATA lv_yaml TYPE string.
    DATA lo_doc  TYPE REF TO zif_ayaml.

    lv_yaml =
      |server:\n| &&
      |  port: 8080\n| &&
      |spring:\n| &&
      |  application:\n| &&
      |    name: order-service\n| &&
      |  datasource:\n| &&
      |    url: jdbc:postgresql://localhost:5432/orders\n| &&
      |    username: order_user\n| &&
      |    driver-class-name: org.postgresql.Driver|.

    lo_doc = zcl_ayaml=>create_from_yaml( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 8080
                                        act = lo_doc->get_integer( '/server/port' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'order-service'
                                        act = lo_doc->get_string( '/spring/application/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'org.postgresql.Driver'
                                        act = lo_doc->get_string( '/spring/datasource/driver-class-name' ) ).
  ENDMETHOD.

  METHOD test_spec_serverless_yaml.
    DATA lv_yaml TYPE string.
    DATA lo_doc  TYPE REF TO zif_ayaml.

    lv_yaml =
      |service: auth-api\n| &&
      |frameworkVersion: '3'\n| &&
      |provider:\n| &&
      |  name: aws\n| &&
      |  runtime: nodejs18.x\n| &&
      |  region: eu-central-1\n| &&
      |functions:\n| &&
      |  login:\n| &&
      |    handler: handler.login\n| &&
      |    memorySize: 512|.

    lo_doc = zcl_ayaml=>create_from_yaml( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 'auth-api'
                                        act = lo_doc->get_string( '/service' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'eu-central-1'
                                        act = lo_doc->get_string( '/provider/region' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 512
                                        act = lo_doc->get_integer( '/functions/login/memorySize' ) ).
  ENDMETHOD.

  METHOD test_spec_nginx_reverse_proxy.
    DATA lv_yaml TYPE string.
    DATA lo_doc  TYPE REF TO zif_ayaml.

    lv_yaml =
      |proxy:\n| &&
      |  upstreams:\n| &&
      |    - srv1.internal:8000\n| &&
      |    - srv2.internal:8000\n| &&
      |  ssl_enabled: true\n| &&
      |  keepalive: 64|.

    lo_doc = zcl_ayaml=>create_from_yaml( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_doc->get_array_length( '/proxy/upstreams' ) ).
    cl_abap_unit_assert=>assert_true( lo_doc->get_boolean( '/proxy/ssl_enabled' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 64
                                        act = lo_doc->get_integer( '/proxy/keepalive' ) ).
  ENDMETHOD.

  METHOD test_spec_logstash_pipeline.
    DATA lv_yaml TYPE string.
    DATA lo_doc  TYPE REF TO zif_ayaml.

    lv_yaml =
      |input:\n| &&
      |  beats:\n| &&
      |    port: 5044\n| &&
      |output:\n| &&
      |  elasticsearch:\n| &&
      |    index: logs-%\{+YYYY.MM.dd\}\n| &&
      |    hosts:\n| &&
      |      - http://localhost:9200|.

    lo_doc = zcl_ayaml=>create_from_yaml( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 5044
                                        act = lo_doc->get_integer( '/input/beats/port' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'http://localhost:9200'
                                        act = lo_doc->get_string( '/output/elasticsearch/hosts/1' ) ).
  ENDMETHOD.

  METHOD test_spec_argocd_application.
    DATA lv_yaml TYPE string.
    DATA lo_doc  TYPE REF TO zif_ayaml.

    lv_yaml =
      |apiVersion: argoproj.io/v1alpha1\n| &&
      |kind: Application\n| &&
      |metadata:\n| &&
      |  name: core-app\n| &&
      |spec:\n| &&
      |  project: default\n| &&
      |  source:\n| &&
      |    repoURL: https://github.com/org/repo.git\n| &&
      |    targetRevision: HEAD\n| &&
      |    path: charts/core|.

    lo_doc = zcl_ayaml=>create_from_yaml( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 'core-app'
                                        act = lo_doc->get_string( '/metadata/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'HEAD'
                                        act = lo_doc->get_string( '/spec/source/targetRevision' ) ).
  ENDMETHOD.

  METHOD test_spec_dependabot_config.
    DATA lv_yaml TYPE string.
    DATA lo_doc  TYPE REF TO zif_ayaml.

    lv_yaml =
      |version: 2\n| &&
      |updates:\n| &&
      |  - package-ecosystem: npm\n| &&
      |    directory: /\n| &&
      |    schedule:\n| &&
      |      interval: weekly|.

    lo_doc = zcl_ayaml=>create_from_yaml( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_doc->get_integer( '/version' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'npm'
                                        act = lo_doc->get_string( '/updates/1/package-ecosystem' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'weekly'
                                        act = lo_doc->get_string( '/updates/1/schedule/interval' ) ).
  ENDMETHOD.

  METHOD test_spec_cloudformation_yaml.
    DATA lv_yaml TYPE string.
    DATA lo_doc  TYPE REF TO zif_ayaml.

    lv_yaml =
      |AWSTemplateFormatVersion: '2010-09-09'\n| &&
      |Description: Storage bucket template\n| &&
      |Resources:\n| &&
      |  S3Bucket:\n| &&
      |    Type: AWS::S3::Bucket\n| &&
      |    Properties:\n| &&
      |      BucketName: my-unique-storage|.

    lo_doc = zcl_ayaml=>create_from_yaml( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = '2010-09-09'
                                        act = lo_doc->get_string( '/AWSTemplateFormatVersion' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'AWS::S3::Bucket'
                                        act = lo_doc->get_string( '/Resources/S3Bucket/Type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'my-unique-storage'
                                        act = lo_doc->get_string( '/Resources/S3Bucket/Properties/BucketName' ) ).
  ENDMETHOD.

  METHOD test_spec_drone_ci_pipeline.
    DATA lv_yaml TYPE string.
    DATA lo_doc  TYPE REF TO zif_ayaml.

    lv_yaml =
      |kind: pipeline\n| &&
      |type: docker\n| &&
      |name: default\n| &&
      |steps:\n| &&
      |  - name: build\n| &&
      |    image: golang:1.20\n| &&
      |    commands:\n| &&
      |      - go build\n| &&
      |      - go test|.

    lo_doc = zcl_ayaml=>create_from_yaml( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 'pipeline'
                                        act = lo_doc->get_string( '/kind' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'golang:1.20'
                                        act = lo_doc->get_string( '/steps/1/image' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'go test'
                                        act = lo_doc->get_string( '/steps/1/commands/2' ) ).
  ENDMETHOD.

  METHOD test_spec_package_manifest.
    DATA lv_yaml TYPE string.
    DATA lo_doc  TYPE REF TO zif_ayaml.

    lv_yaml =
      |name: abap-yaml\n| &&
      |version: 1.0.0\n| &&
      |author: abaplint\n| &&
      |dependencies:\n| &&
      |  open-abap-core: ^0.1.0\n| &&
      |keywords:\n| &&
      |  - abap\n| &&
      |  - yaml\n| &&
      |  - parser|.

    lo_doc = zcl_ayaml=>create_from_yaml( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 'abap-yaml'
                                        act = lo_doc->get_string( '/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = '^0.1.0'
                                        act = lo_doc->get_string( '/dependencies/open-abap-core' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lo_doc->get_array_length( '/keywords' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'yaml'
                                        act = lo_doc->get_string( '/keywords/2' ) ).
  ENDMETHOD.

  METHOD test_spec_anchor_merge_prod.
    DATA lv_yaml TYPE string.
    DATA lo_doc  TYPE REF TO zif_ayaml.

    lv_yaml =
      |default_settings: &defaults\n| &&
      |  timeout: 30\n| &&
      |  retries: 3\n| &&
      |  ssl: true\n| &&
      |production:\n| &&
      |  <<: *defaults\n| &&
      |  retries: 5\n| &&
      |  host: prod.internal|.

    lo_doc = zcl_ayaml=>create_from_yaml( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 30
                                        act = lo_doc->get_integer( '/production/timeout' ) ).
    cl_abap_unit_assert=>assert_true( lo_doc->get_boolean( '/production/ssl' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 5
                                        act = lo_doc->get_integer( '/production/retries' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'prod.internal'
                                        act = lo_doc->get_string( '/production/host' ) ).
  ENDMETHOD.

  METHOD test_spec_deep_table_roundtrip.
    DATA ls_entry   TYPE ty_entry.
    DATA lt_entries TYPE ty_t_entry.
    DATA lt_result  TYPE ty_t_entry.
    DATA lo_doc     TYPE REF TO zif_ayaml.
    DATA lv_yaml    TYPE string.
    DATA lo_parsed  TYPE REF TO zif_ayaml.

    ls_entry-key   = 'k1'.
    ls_entry-value = 100.
    APPEND ls_entry TO lt_entries.

    ls_entry-key   = 'k2'.
    ls_entry-value = 200.
    APPEND ls_entry TO lt_entries.

    ls_entry-key   = 'k3'.
    ls_entry-value = 300.
    APPEND ls_entry TO lt_entries.

    lo_doc = zcl_ayaml=>create_from_abap( lt_entries ).
    lv_yaml = lo_doc->to_yaml( 1 ).

    lo_parsed = zcl_ayaml=>create_from_yaml( lv_yaml ).
    lo_parsed->to_abap( IMPORTING ev_data = lt_result ).

    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lines( lt_result ) ).
    READ TABLE lt_result INDEX 2 INTO ls_entry.
    cl_abap_unit_assert=>assert_subrc( ).
    cl_abap_unit_assert=>assert_equals( exp = 'k2'
                                        act = ls_entry-key ).
    cl_abap_unit_assert=>assert_equals( exp = 200
                                        act = ls_entry-value ).
  ENDMETHOD.

  METHOD test_spec_flow_block_mixture.
    DATA lv_yaml TYPE string.
    DATA lo_doc  TYPE REF TO zif_ayaml.

    lv_yaml =
      |services:\n| &&
      |  - name: api\n| &&
      |    tags: [core, v1]\n| &&
      |    config: \{port: 8080, active: true\}\n| &&
      |  - name: worker\n| &&
      |    tags: [background]\n| &&
      |    config: \{threads: 4\}|.

    lo_doc = zcl_ayaml=>create_from_yaml( lv_yaml ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_doc->get_array_length( '/services' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'core'
                                        act = lo_doc->get_string( '/services/1/tags/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 8080
                                        act = lo_doc->get_integer( '/services/1/config/port' ) ).
    cl_abap_unit_assert=>assert_true( lo_doc->get_boolean( '/services/1/config/active' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 4
                                        act = lo_doc->get_integer( '/services/2/config/threads' ) ).
  ENDMETHOD.

  METHOD test_spec_multi_env_config.
    DATA lv_yaml   TYPE string.
    DATA lo_doc    TYPE REF TO zif_ayaml.
    DATA lv_yaml_o TYPE string.
    DATA lo_res    TYPE REF TO zif_ayaml.

    lv_yaml =
      |environments:\n| &&
      |  dev:\n| &&
      |    debug: true\n| &&
      |    db_url: localhost:5432\n| &&
      |  staging:\n| &&
      |    debug: false\n| &&
      |    db_url: stage-db.internal:5432\n| &&
      |  prod:\n| &&
      |    debug: false\n| &&
      |    db_url: prod-cluster.internal:5432|.

    lo_doc = zcl_ayaml=>create_from_yaml( lv_yaml ).
    cl_abap_unit_assert=>assert_true( lo_doc->get_boolean( '/environments/dev/debug' ) ).
    cl_abap_unit_assert=>assert_false( lo_doc->get_boolean( '/environments/prod/debug' ) ).

    lo_doc->set_string( iv_path  = '/environments/prod/db_url'
                        iv_value = 'failover-db.internal:5432' ).
    lv_yaml_o = lo_doc->to_yaml( 1 ).
    lo_res = zcl_ayaml=>create_from_yaml( lv_yaml_o ).
    cl_abap_unit_assert=>assert_equals( exp = 'failover-db.internal:5432'
                                        act = lo_res->get_string( '/environments/prod/db_url' ) ).
  ENDMETHOD.

  METHOD test_spec_writer_reader_e2e.
    DATA lo_writer TYPE REF TO zif_ayaml.
    DATA lv_yaml1  TYPE string.
    DATA lo_reader TYPE REF TO zif_ayaml.
    DATA lv_yaml2  TYPE string.
    DATA lo_final  TYPE REF TO zif_ayaml.

    lo_writer = zcl_ayaml=>create_empty( ).
    lo_writer->set_string( iv_path  = '/meta/app'
                           iv_value = 'Enterprise Gateway' ).
    lo_writer->set_integer( iv_path  = '/meta/version'
                            iv_value = 2 ).
    lo_writer->init_array( '/services' ).
    lo_writer->set_string( iv_path  = '/services/1/name'
                           iv_value = 'auth' ).
    lo_writer->set_integer( iv_path  = '/services/1/port'
                            iv_value = 4001 ).
    lo_writer->set_string( iv_path  = '/services/2/name'
                           iv_value = 'billing' ).
    lo_writer->set_integer( iv_path  = '/services/2/port'
                            iv_value = 4002 ).

    lv_yaml1 = lo_writer->to_yaml( 1 ).

    lo_reader = zcl_ayaml=>create_from_yaml( lv_yaml1 ).
    cl_abap_unit_assert=>assert_equals( exp = 'Enterprise Gateway'
                                        act = lo_reader->get_string( '/meta/app' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_reader->get_array_length( '/services' ) ).

    lo_reader->set_string( iv_path  = '/services/3/name'
                           iv_value = 'notification' ).
    lo_reader->set_integer( iv_path  = '/services/3/port'
                            iv_value = 4003 ).
    lo_reader->delete( '/services/1' ).

    lv_yaml2 = lo_reader->to_yaml( 1 ).
    lo_final = zcl_ayaml=>create_from_yaml( lv_yaml2 ).

    cl_abap_unit_assert=>assert_equals( exp = 'Enterprise Gateway'
                                        act = lo_final->get_string( '/meta/app' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_final->get_array_length( '/services' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'billing'
                                        act = lo_final->get_string( '/services/1/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'notification'
                                        act = lo_final->get_string( '/services/2/name' ) ).
  ENDMETHOD.
ENDCLASS.


