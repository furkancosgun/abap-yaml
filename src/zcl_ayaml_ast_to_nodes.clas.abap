CLASS zcl_ayaml_ast_to_nodes DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS convert
      IMPORTING io_ast_root     TYPE REF TO zcl_ayaml_ast_node
      RETURNING VALUE(rt_nodes) TYPE zif_ayaml_types=>ty_t_nodes.

  PRIVATE SECTION.
    CLASS-METHODS traverse
      IMPORTING io_node  TYPE REF TO zcl_ayaml_ast_node
                iv_path  TYPE string
                iv_name  TYPE string
                iv_index TYPE i
      CHANGING  ct_nodes TYPE zif_ayaml_types=>ty_t_nodes
                cv_order TYPE i.

ENDCLASS.


CLASS zcl_ayaml_ast_to_nodes IMPLEMENTATION.

  METHOD convert.
    DATA lv_order TYPE i VALUE 0.
    CLEAR rt_nodes.
    IF io_ast_root IS INITIAL.
      RETURN.
    ENDIF.

    traverse(
      EXPORTING
        io_node  = io_ast_root
        iv_path  = `/`
        iv_name  = ``
        iv_index = 0
      CHANGING
        ct_nodes = rt_nodes
        cv_order = lv_order ).
  ENDMETHOD.

  METHOD traverse.
    DATA ls_node        TYPE zif_ayaml_types=>ty_s_node.
    DATA lv_child_path  TYPE string.
    DATA lt_children    TYPE zcl_ayaml_ast_node=>ty_t_nodes.
    DATA lo_child       TYPE REF TO zcl_ayaml_ast_node.
    DATA lv_seq_idx     TYPE i.
    DATA lv_node_type   TYPE zif_ayaml_types=>ty_node_type.

    IF io_node IS INITIAL.
      RETURN.
    ENDIF.

    lv_node_type = io_node->get_node_type( ).

    IF iv_name IS NOT INITIAL.
      cv_order += 1.
      ls_node-path  = iv_path.
      ls_node-name  = iv_name.
      ls_node-type  = lv_node_type.
      ls_node-value = io_node->get_value( ).
      ls_node-index = iv_index.
      ls_node-order = cv_order.
      INSERT ls_node INTO TABLE ct_nodes.
    ELSEIF lv_node_type <> zif_ayaml_types=>cs_type-mapping
        AND lv_node_type <> zif_ayaml_types=>cs_type-sequence.
      " Root is a single scalar
      cv_order += 1.
      ls_node-path  = `/`.
      ls_node-name  = ``.
      ls_node-type  = lv_node_type.
      ls_node-value = io_node->get_value( ).
      ls_node-index = 0.
      ls_node-order = cv_order.
      INSERT ls_node INTO TABLE ct_nodes.
      RETURN.
    ENDIF.

    IF iv_name IS INITIAL.
      lv_child_path = `/`.
    ELSE.
      lv_child_path = zcl_ayaml_path_utils=>append(
        iv_base = iv_path
        iv_name = iv_name ).
    ENDIF.

    lt_children = io_node->get_children( ).

    IF lv_node_type = zif_ayaml_types=>cs_type-mapping.
      LOOP AT lt_children INTO lo_child.
        traverse(
          EXPORTING
            io_node  = lo_child
            iv_path  = lv_child_path
            iv_name  = lo_child->get_key( )
            iv_index = 0
          CHANGING
            ct_nodes = ct_nodes
            cv_order = cv_order ).
      ENDLOOP.
    ELSEIF lv_node_type = zif_ayaml_types=>cs_type-sequence.
      lv_seq_idx = 0.
      LOOP AT lt_children INTO lo_child.
        lv_seq_idx += 1.
        traverse(
          EXPORTING
            io_node  = lo_child
            iv_path  = lv_child_path
            iv_name  = |{ lv_seq_idx }|
            iv_index = lv_seq_idx
          CHANGING
            ct_nodes = ct_nodes
            cv_order = cv_order ).
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
